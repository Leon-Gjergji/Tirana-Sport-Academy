import { createClient } from '@supabase/supabase-js';

// These come from the .env file locally, and from Vercel's Environment Variables online
const url = import.meta.env.VITE_SUPABASE_URL;
const key = import.meta.env.VITE_SUPABASE_ANON_KEY;

if (!url || !key) {
	console.error('Missing VITE_SUPABASE_URL or VITE_SUPABASE_ANON_KEY – see README.md');
}

export const supabase = createClient(url ?? 'http://localhost', key ?? 'missing-key');

// Profile columns we are allowed to read (birth date and guardian phone are private)
export const PROFILE_COLUMNS = 'id, username, avatar_url, weight_kg, level, role, banned, created_at';

export const POST_COLUMNS =
	'id, author_id, discipline, level, weight_kg, age, is_minor, preferred_date, notes, status, prize, created_at, author:profiles(id, username, avatar_url)';
