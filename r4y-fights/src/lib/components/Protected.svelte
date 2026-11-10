<script>
	// Wrap a page with this to make it "logged in only" (or admin only)
	import { goto } from '$app/navigation';
	import { auth } from '#lib/auth.svelte.js';
	import { t } from '#lib/i18n.svelte.js';

	let { children, admin = false } = $props();

	$effect(() => {
		if (auth.ready && !auth.session) goto('/login');
	});
</script>

{#if !auth.ready || !auth.session || !auth.profile}
	<div class="flex min-h-[50vh] items-center justify-center text-sm text-zinc-400">
		<span class="mr-3 h-5 w-5 animate-spin rounded-full border-2 border-zinc-600 border-t-brand"></span>
		{t('c.loading')}
	</div>
{:else if admin && auth.profile.role !== 'admin'}
	<div class="container-page py-16">
		<p class="alert-error">{t('c.notAllowed')}</p>
	</div>
{:else}
	{@render children()}
{/if}
