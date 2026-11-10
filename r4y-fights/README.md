# Tirana Sport Academy – Fight Finder

A website where academy members can post fight requests (discipline, level, weight, age, date), browse other requests, chat 1-to-1 to set a date, and fight **at the academy**. Available in Albanian and English.

**Stack:** SvelteKit (Svelte 5) + Tailwind CSS + Supabase (login, database, profile pictures, live chat). Hosted on Vercel.

---

## 1. Set up Supabase (about 10 min)

1. Go to **supabase.com** → **New project**. Pick region **Frankfurt (eu-central-1)**, the closest one to Albania. Save the database password somewhere.
2. Open **SQL Editor → New query**. Paste the whole file `supabase/schema.sql` and press **Run**. It should say *Success*.
3. Go to **Project Settings → API Keys** (on older dashboards: **Settings → API**) and copy:
   - the **Project URL** (`https://xxxx.supabase.co`)
   - the **anon / publishable key**
4. Go to **Authentication → URL Configuration**:
   - **Site URL:** your Vercel address once you have it, for example `https://tsa-fights.vercel.app`
   - **Redirect URLs:** add `https://tsa-fights.vercel.app/**` and `http://localhost:5173/**`

   This is what makes the "confirm email" and "forgot password" links work.

> **Emails:** Supabase's built-in email sender only allows a few emails per hour, which is fine for testing. Before the real launch, connect your own email provider (for example Resend or Brevo, both free to start) under **Authentication → Emails → SMTP Settings**.

## 2. Run it on your computer (optional)

```bash
npm install
cp .env.example .env      # then paste your URL and key into .env
npm run dev
```
Open http://localhost:5173

## 3. Put it on GitHub

```bash
git init
git add .
git commit -m "First version"
git branch -M main
git remote add origin https://github.com/YOUR-NAME/tsa-fights.git
git push -u origin main
```
(Create the empty repo on github.com first. The `.env` file is ignored on purpose, so your keys stay off GitHub.)

## 4. Deploy on Vercel

1. **vercel.com → Add New → Project →** import the GitHub repo. Vercel detects SvelteKit by itself.
2. Before clicking Deploy, open **Environment Variables** and add:
   - `VITE_SUPABASE_URL` = your Project URL
   - `VITE_SUPABASE_ANON_KEY` = your anon / publishable key
3. Click **Deploy**. When it's done, copy the URL and put it in Supabase → Authentication → URL Configuration (step 1.4).

If you change environment variables later, redeploy, because they get built into the site.

## 5. Make the academy account admin

1. Sign up on the website with the academy's email and confirm it.
2. In Supabase **SQL Editor**, run (change the email):
   ```sql
   update public.profiles set role = 'admin'
   where id = (select id from auth.users where email = 'academy@example.com');
   ```
3. Log out and back in. The **Admin** tab now appears in the menu.

The admin can: see all users (with email, real age and the parent's phone for under-18s), block or unblock users, see and delete all requests, attach an academy prize to a request, and read every chat.

---

## How the rules work

All of these are enforced **inside the database** (`supabase/schema.sql`), not just hidden in the page, so nobody can get around them by editing the website code:

- **Under-18 and 18+ are separate groups.** Each group only sees profiles and requests from its own group, and chats can only be opened inside the same group. Under-18s must enter a parent's phone number at signup.
- Users **can't change their own birth date, role or blocked status**, so nobody can make themselves admin or move to the other age group.
- Age on a request is calculated from the birth date, so it can't be faked.
- Only the admin can set prizes, block users and read other people's chats.
- Blocked users can still log in, but they can't post, message or start chats.
- Profile pictures can only be uploaded into the user's own folder.

## Where to change things

| What | File |
|---|---|
| Phone, TikTok, WhatsApp, city | `src/lib/constants.js` |
| All texts (Albanian and English) | `src/lib/i18n.svelte.js` |
| Colors and fonts | `src/routes/layout.css` |
| Logo and browser icon | `static/logo.png`, `static/favicon.png` (the logo was cut from a screenshot, so swap in the original file if you have it) |
| Disciplines / levels | `src/lib/constants.js` **and** the check lists in `supabase/schema.sql` |

## Pages

| URL | What |
|---|---|
| `/` | Start page: logo, info, disciplines, how it works, contact |
| `/signup`, `/login` | Account. Signup asks for username, email, birth date, and parent's phone if under 18 |
| `/forgot-password`, `/reset-password` | Password reset by email |
| `/fights` | All open requests from your age group, with filters. "Mine" tab to close or delete your own |
| `/fights/new` | Post a request |
| `/messages`, `/messages/[id]` | Your chats, live |
| `/profile` | Photo, username, weight, level |
| `/admin` | Admin panel |
