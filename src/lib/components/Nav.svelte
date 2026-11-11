<script>
	import { page } from '$app/state';
	import { goto } from '$app/navigation';
	import { auth, logout } from '#lib/auth.svelte.js';
	import { t, i18n, setLang } from '#lib/i18n.svelte.js';
	import Avatar from './Avatar.svelte';

	let open = $state(false);

	const links = $derived(
		[
			{ href: '/', label: t('nav.home'), show: true },
			{ href: '/fights', label: t('nav.fights'), show: true },
			{ href: '/messages', label: t('nav.messages'), show: !!auth.session },
			{ href: '/admin', label: t('nav.admin'), show: auth.profile?.role === 'admin' }
		].filter((l) => l.show)
	);

	function active(href) {
		const path = page.url.pathname;
		return href === '/' ? path === '/' : path.startsWith(href);
	}

	async function doLogout() {
		open = false;
		await logout();
		goto('/');
	}
</script>

{#snippet langSwitch()}
	<div class="flex rounded-lg border border-line p-0.5 text-xs font-semibold">
		{#each ['sq', 'en'] as l (l)}
			<button
				class="rounded-md px-2 py-1 uppercase transition {i18n.lang === l
					? 'bg-brand text-white'
					: 'text-zinc-400 hover:text-white'}"
				onclick={() => setLang(l)}>{l}</button
			>
		{/each}
	</div>
{/snippet}

<header class="sticky top-0 z-40 border-b border-line/70 bg-ink/85 backdrop-blur">
	<nav class="container-page flex h-16 items-center justify-between gap-4">
		<a href="/" class="flex items-center gap-2.5" onclick={() => (open = false)}>
			<img src="/logo.png" alt="Tirana Sport Academy" class="h-10 w-10" />
			<span class="heading hidden text-lg leading-none sm:block">
				Tirana <span class="text-brand">Sport</span> Academy
			</span>
		</a>

		<!-- desktop -->
		<div class="hidden items-center gap-1 md:flex">
			{#each links as link (link.href)}
				<a
					href={link.href}
					class="rounded-lg px-3 py-2 text-sm font-medium transition {active(link.href)
						? 'text-white'
						: 'text-zinc-400 hover:text-white'}"
				>
					{link.label}
					{#if active(link.href)}<span class="mt-0.5 block h-0.5 rounded bg-brand"></span>{/if}
				</a>
			{/each}
		</div>

		<div class="hidden items-center gap-3 md:flex">
			{@render langSwitch()}
			{#if auth.session && auth.profile}
				<a href="/profile" class="flex items-center gap-2 rounded-full py-1 pr-3 pl-1 hover:bg-panel-2">
					<Avatar src={auth.profile.avatar_url} name={auth.profile.username} size={32} />
					<span class="text-sm font-medium">{auth.profile.username}</span>
				</a>
				<button class="btn-ghost" onclick={doLogout}>{t('nav.logout')}</button>
			{:else if auth.ready}
				<a href="/login" class="btn-ghost">{t('nav.login')}</a>
				<a href="/signup" class="btn-primary">{t('nav.signup')}</a>
			{/if}
		</div>

		<!-- mobile -->
		<div class="flex items-center gap-2 md:hidden">
			{@render langSwitch()}
			<button class="btn-ghost px-2.5" aria-label="Menu" onclick={() => (open = !open)}>
				<svg class="h-6 w-6" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
					{#if open}
						<path stroke-linecap="round" d="M6 6l12 12M18 6L6 18" />
					{:else}
						<path stroke-linecap="round" d="M4 7h16M4 12h16M4 17h16" />
					{/if}
				</svg>
			</button>
		</div>
	</nav>

	{#if open}
		<div class="border-t border-line bg-ink md:hidden">
			<div class="container-page flex flex-col gap-1 py-3">
				{#each links as link (link.href)}
					<a
						href={link.href}
						onclick={() => (open = false)}
						class="rounded-lg px-3 py-2.5 text-sm font-medium {active(link.href)
							? 'bg-panel-2 text-white'
							: 'text-zinc-300'}">{link.label}</a
					>
				{/each}
				<div class="mt-2 border-t border-line pt-3">
					{#if auth.session && auth.profile}
						<a href="/profile" onclick={() => (open = false)} class="flex items-center gap-3 px-3 py-2">
							<Avatar src={auth.profile.avatar_url} name={auth.profile.username} size={32} />
							<span class="text-sm font-medium">{auth.profile.username}</span>
						</a>
						<button class="btn-ghost w-full justify-start" onclick={doLogout}>{t('nav.logout')}</button>
					{:else}
						<div class="grid grid-cols-2 gap-2">
							<a href="/login" onclick={() => (open = false)} class="btn-secondary">{t('nav.login')}</a>
							<a href="/signup" onclick={() => (open = false)} class="btn-primary">{t('nav.signup')}</a>
						</div>
					{/if}
				</div>
			</div>
		</div>
	{/if}
</header>
