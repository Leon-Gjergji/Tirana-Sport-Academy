<script>
	// The link in the reset email logs the user in for a moment so they can set a new password
	import { goto } from '$app/navigation';
	import { supabase } from '#lib/supabase.js';
	import { auth } from '#lib/auth.svelte.js';
	import { t } from '#lib/i18n.svelte.js';
	import AuthCard from '#lib/components/AuthCard.svelte';

	let password = $state('');
	let password2 = $state('');
	let error = $state('');
	let busy = $state(false);

	async function submit(e) {
		e.preventDefault();
		error = '';
		if (password.length < 8) return (error = t('auth.err.short'));
		if (password !== password2) return (error = t('auth.err.match'));
		busy = true;
		const { error: err } = await supabase.auth.updateUser({ password });
		busy = false;
		if (err) return (error = err.message);
		goto('/fights');
	}
</script>

<AuthCard title={t('auth.resetTitle')}>
	{#if !auth.ready}
		<p class="text-center text-sm text-zinc-400">{t('c.loading')}</p>
	{:else if !auth.session}
		<p class="alert-error">{t('auth.resetInvalid')}</p>
		<a href="/forgot-password" class="btn-primary mt-5 w-full py-3">{t('auth.sendLink')}</a>
	{:else}
		<form class="space-y-4" onsubmit={submit}>
			<div>
				<label class="label" for="password">{t('auth.newPassword')}</label>
				<input id="password" type="password" class="input" autocomplete="new-password" required minlength="8" bind:value={password} />
			</div>
			<div>
				<label class="label" for="password2">{t('auth.password2')}</label>
				<input id="password2" type="password" class="input" autocomplete="new-password" required bind:value={password2} />
			</div>
			{#if error}<p class="alert-error">{error}</p>{/if}
			<button class="btn-primary w-full py-3" disabled={busy}>{busy ? t('c.loading') : t('auth.save')}</button>
		</form>
	{/if}
</AuthCard>
