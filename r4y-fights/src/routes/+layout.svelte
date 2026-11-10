<script>
	import './layout.css';
	import { onMount } from 'svelte';
	import Nav from '#lib/components/Nav.svelte';
	import { auth, initAuth } from '#lib/auth.svelte.js';
	import { t, initLang } from '#lib/i18n.svelte.js';
	import { ACADEMY } from '#lib/constants.js';

	let { children } = $props();

	onMount(() => {
		initLang();
		initAuth();
	});
</script>

<div class="flex min-h-screen flex-col">
	<Nav />

	{#if auth.profile?.banned}
		<div class="container-page pt-4">
			<p class="alert-error">{t('p.banned')}</p>
		</div>
	{/if}

	<main class="flex-1">
		{@render children()}
	</main>

	<footer class="mt-16 border-t border-line">
		<div class="container-page flex flex-col items-center justify-between gap-4 py-8 text-sm text-zinc-400 sm:flex-row">
			<div class="flex items-center gap-3">
				<img src="/logo.png" alt="" class="h-8 w-8" />
				<span>© {new Date().getFullYear()} {ACADEMY.name} · {ACADEMY.city}</span>
			</div>
			<div class="flex items-center gap-5">
				<a href={ACADEMY.phoneHref} class="hover:text-white">{ACADEMY.phone}</a>
				<a href={ACADEMY.tiktok} target="_blank" rel="noopener" class="hover:text-white">TikTok</a>
			</div>
		</div>
	</footer>
</div>
