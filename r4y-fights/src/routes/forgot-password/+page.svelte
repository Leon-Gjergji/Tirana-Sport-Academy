<script>
	import { supabase } from '#lib/supabase.js';
	import { t } from '#lib/i18n.svelte.js';
	import AuthCard from '#lib/components/AuthCard.svelte';

	let email = $state('');
	let sent = $state(false);
	let error = $state('');
	let busy = $state(false);

	async function submit(e) {
		e.preventDefault();
		error = '';
		busy = true;
		const { error: err } = await supabase.auth.resetPasswordForEmail(email.trim(), {
			redirectTo: `${location.origin}/reset-password`
		});
		busy = false;
		if (err) error = err.message;
		else sent = true;
	}
</script>

<AuthCard title={t('auth.forgotTitle')} subtitle={t('auth.forgotSub')}>
	{#if sent}
		<p class="alert-ok">{t('auth.linkSent')}</p>
	{:else}
		<form class="space-y-4" onsubmit={submit}>
			<div>
				<label class="label" for="email">{t('auth.email')}</label>
				<input id="email" type="email" class="input" autocomplete="email" required bind:value={email} />
			</div>
			{#if error}<p class="alert-error">{error}</p>{/if}
			<button class="btn-primary w-full py-3" disabled={busy}>{busy ? t('c.loading') : t('auth.sendLink')}</button>
		</form>
	{/if}

	{#snippet footer()}
		<a href="/login" class="font-semibold text-brand hover:underline">{t('auth.backToLogin')}</a>
	{/snippet}
</AuthCard>
