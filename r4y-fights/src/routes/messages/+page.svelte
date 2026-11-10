<script>
	import { auth } from '#lib/auth.svelte.js';
	import { t, formatDate } from '#lib/i18n.svelte.js';
	import { loadConversations } from '#lib/conversations.js';
	import Protected from '#lib/components/Protected.svelte';
	import Avatar from '#lib/components/Avatar.svelte';

	let convs = $state([]);
	let loading = $state(true);
	let error = $state('');

	let loaded = false;
	$effect(() => {
		if (auth.profile && !loaded) {
			loaded = true;
			loadConversations({ onlyMine: auth.profile.id })
				.then((list) => (convs = list))
				.catch((e) => (error = e.message))
				.finally(() => (loading = false));
		}
	});

	function other(c) {
		return c.user_a === auth.profile.id ? c.b : c.a;
	}
</script>

<Protected>
	<section class="container-page max-w-3xl py-10">
		<h1 class="heading text-4xl">{t('m.title')}</h1>

		{#if error}<p class="alert-error mt-6">{error}</p>{/if}

		{#if loading}
			<p class="mt-10 text-center text-sm text-zinc-400">{t('c.loading')}</p>
		{:else if convs.length === 0}
			<div class="card mt-6 p-12 text-center">
				<p class="text-4xl">💬</p>
				<p class="mt-3 text-zinc-400">{t('m.empty')}</p>
				<a href="/fights" class="btn-primary mt-6">{t('nav.fights')}</a>
			</div>
		{:else}
			<ul class="card mt-6 divide-y divide-line overflow-hidden">
				{#each convs as c (c.id)}
					{@const person = other(c)}
					<li>
						<a href="/messages/{c.id}" class="flex items-center gap-4 px-5 py-4 transition hover:bg-panel-2">
							<Avatar src={person?.avatar_url} name={person?.username} size={46} />
							<div class="min-w-0 flex-1">
								<p class="truncate font-semibold">{person?.username ?? '—'}</p>
								<p class="text-xs text-zinc-500">{formatDate(c.last_message_at, true)}</p>
							</div>
							<span class="text-zinc-500">→</span>
						</a>
					</li>
				{/each}
			</ul>
		{/if}
	</section>
</Protected>
