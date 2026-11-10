<script>
	import { goto } from '$app/navigation';
	import { supabase } from '#lib/supabase.js';
	import { auth } from '#lib/auth.svelte.js';
	import { t } from '#lib/i18n.svelte.js';
	import { ageFrom } from '#lib/constants.js';
	import AuthCard from '#lib/components/AuthCard.svelte';

	let email = $state('');
	let username = $state('');
	let birthDate = $state('');
	let guardianPhone = $state('');
	let password = $state('');
	let password2 = $state('');
	let acceptRules = $state(false);

	let error = $state('');
	let done = $state(false);
	let busy = $state(false);

	const age = $derived(ageFrom(birthDate));
	const isMinor = $derived(age !== null && age < 18);
	const today = new Date().toISOString().slice(0, 10);

	// Logged in (e.g. right after signup when email confirmation is off) -> add photo on profile
	$effect(() => {
		if (auth.ready && auth.session) goto('/profile');
	});

	async function submit(e) {
		e.preventDefault();
		error = '';

		const name = username.trim();
		if (!/^[a-zA-Z0-9_.]{3,24}$/.test(name)) return (error = t('auth.err.usernameFormat'));
		if (age === null || age < 6 || age > 100) return (error = t('auth.err.birth'));
		if (isMinor && guardianPhone.trim().length < 6) return (error = t('auth.err.guardian'));
		if (password.length < 8) return (error = t('auth.err.short'));
		if (password !== password2) return (error = t('auth.err.match'));
		if (!acceptRules) return (error = t('auth.err.rules'));

		busy = true;
		const { data: free } = await supabase.rpc('username_available', { name });
		if (free === false) {
			busy = false;
			return (error = t('auth.err.username'));
		}

		const { data, error: err } = await supabase.auth.signUp({
			email: email.trim(),
			password,
			options: {
				emailRedirectTo: `${location.origin}/login`,
				data: {
					username: name,
					birth_date: birthDate,
					guardian_phone: isMinor ? guardianPhone.trim() : null
				}
			}
		});
		busy = false;

		if (err) return (error = err.message);
		if (!data.session) done = true; // otherwise the effect above redirects
	}
</script>

<AuthCard title={t('auth.signupTitle')} subtitle={t('auth.signupSub')}>
	{#if done}
		<p class="alert-ok">{t('auth.checkEmail')}</p>
		<a href="/login" class="btn-primary mt-5 w-full py-3">{t('auth.backToLogin')}</a>
	{:else}
		<form class="space-y-4" onsubmit={submit}>
			<div>
				<label class="label" for="username">{t('auth.username')}</label>
				<input id="username" class="input" autocomplete="username" required maxlength="24" bind:value={username} />
			</div>
			<div>
				<label class="label" for="email">{t('auth.email')}</label>
				<input id="email" type="email" class="input" autocomplete="email" required bind:value={email} />
			</div>
			<div>
				<label class="label" for="birth">{t('auth.birth')}</label>
				<input id="birth" type="date" class="input" max={today} required bind:value={birthDate} />
			</div>

			{#if isMinor}
				<div class="rounded-xl border border-navy-light/40 bg-navy/15 p-4">
					<label class="label" for="guardian">{t('auth.guardian')}</label>
					<input id="guardian" type="tel" class="input" placeholder="+355 6X XXX XXXX" required bind:value={guardianPhone} />
					<p class="mt-2 text-xs text-indigo-200/80">{t('auth.guardianHint')}</p>
				</div>
			{/if}

			<div class="grid gap-4 sm:grid-cols-2">
				<div>
					<label class="label" for="password">{t('auth.password')}</label>
					<input id="password" type="password" class="input" autocomplete="new-password" required minlength="8" bind:value={password} />
				</div>
				<div>
					<label class="label" for="password2">{t('auth.password2')}</label>
					<input id="password2" type="password" class="input" autocomplete="new-password" required bind:value={password2} />
				</div>
			</div>

			<label class="flex items-start gap-3 text-sm text-zinc-300">
				<input type="checkbox" class="mt-0.5 rounded border-line bg-ink text-brand focus:ring-brand" bind:checked={acceptRules} />
				{t('auth.rules')}
			</label>

			{#if error}<p class="alert-error">{error}</p>{/if}
			<button class="btn-primary w-full py-3" disabled={busy}>{busy ? t('c.loading') : t('nav.signup')}</button>
		</form>
	{/if}

	{#snippet footer()}
		{t('auth.haveAccount')} <a href="/login" class="font-semibold text-brand hover:underline">{t('nav.login')}</a>
	{/snippet}
</AuthCard>
