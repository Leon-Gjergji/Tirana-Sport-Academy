<script>
	import { goto } from '$app/navigation';
	import { supabase } from '#lib/supabase.js';
	import { auth } from '#lib/auth.svelte.js';
	import { t } from '#lib/i18n.svelte.js';
	import AuthCard from '#lib/components/AuthCard.svelte';
	import { ACADEMY } from '#lib/constants.js';

	let email = $state('');
	let password = $state('');
	let error = $state('');
	let busy = $state(false);

	// Already logged in (or just came back from the confirmation email) -> go to fights
	$effect(() => {
		if (auth.ready && auth.session) goto('/fights');
	});

	async function submit(e) {
		e.preventDefault();
		error = '';
		busy = true;
		const { error: err } = await supabase.auth.signInWithPassword({ email: email.trim(), password });
		busy = false;
		if (err) {
			error = err.message.toLowerCase().includes('invalid') ? t('auth.err.login') : err.message;
			return;
		}
		goto('/fights');
	}
</script>

<AuthCard title={t('auth.loginTitle')} subtitle={t('auth.loginSub')}>
	<form class="space-y-4" onsubmit={submit}>
		<div>
			<label class="label" for="email">{t('auth.email')}</label>
			<input id="email" type="email" class="input" autocomplete="email" required bind:value={email} />
		</div>
		<div>
			<label class="label" for="password">{t('auth.password')}</label>
			<input id="password" type="password" class="input" autocomplete="current-password" required bind:value={password} />
		</div>
		{#if error}<p class="alert-error">{error}</p>{/if}
		<button class="btn-primary w-full py-3" disabled={busy}>{busy ? t('c.loading') : t('nav.login')}</button>
		<p class="text-center text-xs text-zinc-500">
			{t('auth.forgot')}
			<a href={ACADEMY.whatsapp} target="_blank" rel="noopener" class="font-semibold text-zinc-300 hover:text-brand">{t('auth.forgotContact')}</a>
		</p>
	</form>

	{#snippet footer()}
		{t('auth.noAccount')} <a href="/signup" class="font-semibold text-brand hover:underline">{t('nav.signup')}</a>
	{/snippet}
</AuthCard>
