import { supabase } from './supabase.js';

// Loads conversations and attaches both users' public profiles
export async function loadConversations({ onlyMine = null } = {}) {
	let query = supabase
		.from('conversations')
		.select('id, user_a, user_b, post_id, created_at, last_message_at')
		.order('last_message_at', { ascending: false })
		.limit(300);
	if (onlyMine) query = query.or(`user_a.eq.${onlyMine},user_b.eq.${onlyMine}`);

	const { data: convs, error } = await query;
	if (error) throw error;

	const ids = [...new Set(convs.flatMap((c) => [c.user_a, c.user_b]))];
	let people = {};
	if (ids.length) {
		const { data: profiles } = await supabase
			.from('profiles')
			.select('id, username, avatar_url')
			.in('id', ids);
		people = Object.fromEntries((profiles ?? []).map((p) => [p.id, p]));
	}
	return convs.map((c) => ({ ...c, a: people[c.user_a], b: people[c.user_b] }));
}
