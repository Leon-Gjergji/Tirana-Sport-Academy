-- Only needed if you ALREADY ran schema.sql before this function was added.
-- (A fresh schema.sql already contains it.)

-- Lets the admin set a new password for a user who forgot theirs (no emails needed)
create extension if not exists pgcrypto with schema extensions;

create or replace function public.admin_reset_password(target uuid, new_password text)
returns void language plpgsql security definer set search_path = public, extensions as $$
begin
  if not public.is_admin() then raise exception 'Admins only'; end if;
  if char_length(new_password) < 8 then raise exception 'Password must be at least 8 characters'; end if;
  update auth.users
     set encrypted_password = extensions.crypt(new_password, extensions.gen_salt('bf')),
         updated_at = now()
   where id = target;
  if not found then raise exception 'User not found'; end if;
end;
$$;

revoke execute on function public.admin_reset_password(uuid, text) from public, anon;
grant execute on function public.admin_reset_password(uuid, text) to authenticated;
