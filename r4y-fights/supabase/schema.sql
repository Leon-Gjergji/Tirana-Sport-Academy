-- =====================================================================
-- Tirana Sport Academy – Fight Finder
-- Run this whole file once in Supabase: SQL Editor -> New query -> Run
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. PROFILES
-- One row per user. Created automatically when someone signs up.
-- ---------------------------------------------------------------------
create table public.profiles (
  id             uuid primary key references auth.users on delete cascade,
  username       text unique not null check (char_length(username) between 3 and 24),
  avatar_url     text,
  birth_date     date not null,
  guardian_phone text,                       -- required for under-18 users
  weight_kg      numeric(5,1) check (weight_kg between 20 and 250),
  level          text check (level in ('beginner','intermediate','advanced','pro')),
  role           text not null default 'user' check (role in ('user','admin')),
  banned         boolean not null default false,
  created_at     timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- 2. HELPER FUNCTIONS (security definer = they can read profiles
--    without running into the row rules below)
-- ---------------------------------------------------------------------
create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from profiles where id = auth.uid() and role = 'admin');
$$;

create or replace function public.is_minor(uid uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select birth_date > (current_date - interval '18 years') from profiles where id = uid;
$$;

-- true when both users are in the same age group (both under 18 or both 18+)
create or replace function public.same_group(a uuid, b uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select coalesce(public.is_minor(a) = public.is_minor(b), false);
$$;

create or replace function public.is_banned(uid uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select coalesce((select banned from profiles where id = uid), true);
$$;

-- Lets the signup form check if a username is free (before the user is logged in)
create or replace function public.username_available(name text)
returns boolean language sql stable security definer set search_path = public as $$
  select not exists (select 1 from profiles where lower(username) = lower(trim(name)));
$$;

-- ---------------------------------------------------------------------
-- 3. CREATE PROFILE ON SIGNUP
-- The signup form sends username, birth_date and guardian_phone as
-- metadata; this trigger turns them into a profile row.
-- ---------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_birth date := (new.raw_user_meta_data ->> 'birth_date')::date;
  v_guardian text := nullif(trim(new.raw_user_meta_data ->> 'guardian_phone'), '');
begin
  if v_birth is null or v_birth > current_date - interval '6 years' then
    raise exception 'Invalid birth date';
  end if;
  if v_birth > current_date - interval '18 years' and v_guardian is null then
    raise exception 'Guardian phone is required for users under 18';
  end if;

  insert into public.profiles (id, username, birth_date, guardian_phone)
  values (new.id, trim(new.raw_user_meta_data ->> 'username'), v_birth, v_guardian);
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------
-- 4. PROFILE RULES
-- - You see your own profile, and profiles in your own age group.
-- - Admin sees everyone.
-- - Nobody can read birth_date / guardian_phone of others (only admin, via admin_users()).
-- - You can only edit username, avatar, weight and level. Never role, banned or birth_date.
-- ---------------------------------------------------------------------
alter table public.profiles enable row level security;

create policy "profiles: view own group"
  on public.profiles for select to authenticated
  using (id = auth.uid() or public.is_admin() or public.same_group(id, auth.uid()));

create policy "profiles: update own"
  on public.profiles for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());

revoke all on public.profiles from anon, authenticated;
grant select (id, username, avatar_url, weight_kg, level, role, banned, created_at)
  on public.profiles to authenticated;
grant update (username, avatar_url, weight_kg, level) on public.profiles to authenticated;

-- ---------------------------------------------------------------------
-- 5. FIGHT POSTS
-- ---------------------------------------------------------------------
create table public.fight_posts (
  id             uuid primary key default gen_random_uuid(),
  author_id      uuid not null references public.profiles on delete cascade,
  discipline     text not null check (discipline in ('boxing','kickboxing','muay_thai','mma','taekwondo')),
  level          text not null check (level in ('beginner','intermediate','advanced','pro')),
  weight_kg      numeric(5,1) not null check (weight_kg between 20 and 250),
  age            int,                         -- filled in automatically
  is_minor       boolean,                     -- filled in automatically
  preferred_date date,
  notes          text check (char_length(notes) <= 500),
  status         text not null default 'open' check (status in ('open','closed')),
  prize          text check (char_length(prize) <= 120),  -- only the admin can set this
  created_at     timestamptz not null default now()
);

-- Fills author, age and age group from the logged-in user, so nobody can fake them
create or replace function public.fight_posts_before_insert()
returns trigger language plpgsql security definer set search_path = public as $$
declare v_birth date;
begin
  select birth_date into v_birth from profiles where id = auth.uid();
  new.author_id := auth.uid();
  new.age := date_part('year', age(current_date, v_birth))::int;
  new.is_minor := v_birth > current_date - interval '18 years';
  new.status := 'open';
  new.prize := null;
  return new;
end;
$$;

create trigger fight_posts_before_insert
  before insert on public.fight_posts
  for each row execute function public.fight_posts_before_insert();

alter table public.fight_posts enable row level security;

create policy "posts: view own group"
  on public.fight_posts for select to authenticated
  using (public.is_admin() or author_id = auth.uid() or public.same_group(author_id, auth.uid()));

create policy "posts: create own"
  on public.fight_posts for insert to authenticated
  with check (author_id = auth.uid() and not public.is_banned(auth.uid()));

create policy "posts: update own"
  on public.fight_posts for update to authenticated
  using (author_id = auth.uid()) with check (author_id = auth.uid());

create policy "posts: delete own or admin"
  on public.fight_posts for delete to authenticated
  using (author_id = auth.uid() or public.is_admin());

revoke all on public.fight_posts from anon, authenticated;
grant select, delete on public.fight_posts to authenticated;
grant insert (discipline, level, weight_kg, preferred_date, notes) on public.fight_posts to authenticated;
grant update (status, notes, preferred_date) on public.fight_posts to authenticated;

-- ---------------------------------------------------------------------
-- 6. CONVERSATIONS + MESSAGES
-- ---------------------------------------------------------------------
create table public.conversations (
  id              uuid primary key default gen_random_uuid(),
  user_a          uuid not null references public.profiles on delete cascade,
  user_b          uuid not null references public.profiles on delete cascade,
  post_id         uuid references public.fight_posts on delete set null,
  created_at      timestamptz not null default now(),
  last_message_at timestamptz not null default now(),
  check (user_a < user_b),
  unique (user_a, user_b)
);

create table public.messages (
  id              uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations on delete cascade,
  sender_id       uuid not null default auth.uid() references public.profiles on delete cascade,
  body            text not null check (char_length(body) between 1 and 2000),
  created_at      timestamptz not null default now()
);
create index messages_conversation_idx on public.messages (conversation_id, created_at);

create or replace function public.is_participant(conv uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from conversations
                 where id = conv and auth.uid() in (user_a, user_b));
$$;

alter table public.conversations enable row level security;
alter table public.messages enable row level security;

create policy "conversations: participants or admin"
  on public.conversations for select to authenticated
  using (auth.uid() in (user_a, user_b) or public.is_admin());

create policy "messages: participants or admin can read"
  on public.messages for select to authenticated
  using (public.is_participant(conversation_id) or public.is_admin());

-- You can only send if you are in the chat, not banned, and still in the same age group
create policy "messages: participants can send"
  on public.messages for insert to authenticated
  with check (
    sender_id = auth.uid()
    and public.is_participant(conversation_id)
    and not public.is_banned(auth.uid())
    and exists (select 1 from public.conversations c
                where c.id = conversation_id and public.same_group(c.user_a, c.user_b))
  );

revoke all on public.conversations from anon, authenticated;
revoke all on public.messages from anon, authenticated;
grant select on public.conversations to authenticated;
grant select on public.messages to authenticated;
grant insert (conversation_id, body) on public.messages to authenticated;

-- Keeps the chat list sorted by latest message
create or replace function public.touch_conversation()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  update conversations set last_message_at = new.created_at where id = new.conversation_id;
  return new;
end;
$$;

create trigger messages_touch_conversation
  after insert on public.messages
  for each row execute function public.touch_conversation();

-- Opens (or reuses) a chat with another user. Blocks cross-age-group chats.
create or replace function public.start_conversation(other_id uuid, p_post_id uuid default null)
returns uuid language plpgsql security definer set search_path = public as $$
declare
  me uuid := auth.uid();
  a uuid; b uuid; conv uuid;
begin
  if me is null then raise exception 'Not logged in'; end if;
  if other_id = me then raise exception 'You cannot message yourself'; end if;
  if public.is_banned(me) then raise exception 'Your account is banned'; end if;
  if not exists (select 1 from profiles where id = other_id) then raise exception 'User not found'; end if;
  if not public.same_group(me, other_id) then raise exception 'Not allowed'; end if;

  a := least(me, other_id); b := greatest(me, other_id);
  select id into conv from conversations where user_a = a and user_b = b;
  if conv is null then
    insert into conversations (user_a, user_b, post_id) values (a, b, p_post_id) returning id into conv;
  end if;
  return conv;
end;
$$;

-- ---------------------------------------------------------------------
-- 7. ADMIN FUNCTIONS
-- ---------------------------------------------------------------------
create or replace function public.admin_users()
returns table (id uuid, username text, email text, birth_date date, guardian_phone text,
               weight_kg numeric, level text, role text, banned boolean, created_at timestamptz)
language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'Admins only'; end if;
  return query
    select p.id, p.username, u.email::text, p.birth_date, p.guardian_phone,
           p.weight_kg, p.level, p.role, p.banned, p.created_at
    from profiles p join auth.users u on u.id = p.id
    order by p.created_at desc;
end;
$$;

create or replace function public.admin_set_banned(target uuid, value boolean)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'Admins only'; end if;
  if target = auth.uid() then raise exception 'You cannot ban yourself'; end if;
  update profiles set banned = value where id = target;
end;
$$;

create or replace function public.admin_set_prize(target uuid, value text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'Admins only'; end if;
  update fight_posts set prize = nullif(trim(value), '') where id = target;
end;
$$;

-- Only logged-in users may call these; username_available is also needed before login
revoke execute on all functions in schema public from public, anon;
grant execute on all functions in schema public to authenticated;
grant execute on function public.username_available(text) to anon;

-- ---------------------------------------------------------------------
-- 8. PROFILE PICTURES (Storage bucket "avatars")
-- Each user can only upload into a folder named after their own user id.
-- ---------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

create policy "avatars: upload own"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "avatars: update own"
  on storage.objects for update to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "avatars: delete own"
  on storage.objects for delete to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

-- ---------------------------------------------------------------------
-- 9. LIVE CHAT
-- ---------------------------------------------------------------------
alter publication supabase_realtime add table public.messages;
