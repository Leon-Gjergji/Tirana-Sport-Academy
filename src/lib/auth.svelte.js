import { supabase, PROFILE_COLUMNS } from './supabase.js';

// Shared login state for the whole app
export const auth = $state({
	ready: false, // true once we know if someone is logged in
	session: null,
	profile: null,
	isMinor: false
});

export async function loadProfile() {
	const user = auth.session?.user;
	if (!user) {
		auth.profile = null;
		auth.isMinor = false;
		return;
	}
	const { data } = await supabase.from('profiles').select(PROFILE_COLUMNS).eq('id', user.id).single();
	auth.profile = data;
	const { data: minor } = await supabase.rpc('is_minor', { uid: user.id });
	auth.isMinor = !!minor;
}

let started = false;

export function initAuth() {
	if (started) return;
	started = true;

	supabase.auth.getSession().then(async ({ data }) => {
		auth.session = data.session;
		await loadProfile();
		auth.ready = true;
	});

	supabase.auth.onAuthStateChange((event, session) => {
		auth.session = session;
		// Supabase recommends not awaiting other Supabase calls inside this callback
		if (event === 'SIGNED_IN' || event === 'SIGNED_OUT' || event === 'USER_UPDATED') {
			setTimeout(loadProfile, 0);
		}
	});
}

export async function logout() {
	await supabase.auth.signOut();
	auth.profile = null;
}
