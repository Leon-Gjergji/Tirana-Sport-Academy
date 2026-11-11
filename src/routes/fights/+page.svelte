<script>
	import { goto } from '$app/navigation';
	import { supabase, POST_COLUMNS } from '#lib/supabase.js';
	import { auth } from '#lib/auth.svelte.js';
	import { t } from '#lib/i18n.svelte.js';
	import { DISCIPLINES, LEVELS } from '#lib/constants.js';
	import Protected from '#lib/components/Protected.svelte';
	import FightCard from '#lib/components/FightCard.svelte';

	let posts = $state([]);
	let loading = $state(true);
	let error = $state('');
	let busyId = $state(null);

	// filters
	let tab = $state('all'); // 'all' | 'mine'
	let discipline = $state('');
	let level = $state('');
	let minKg = $state('');
	let maxKg = $state('');

	let loaded = false;
	$effect(() => {
		if (auth.profile && !loaded) {
			loaded = true;
			load();
		}
	});

	async function load() {
		loading = true;
		// The database only returns posts from your own age group (see schema.sql)
		const { data, error: err } = await supabase
			.from('fight_posts')
			.select(POST_COLUMNS)
			.order('created_at', { ascending: false })
			.limit(200);
		loading = false;
		if (err) return (error = err.message);
		posts = data;
	}

	const visible = $derived(
		posts.filter((p) => {
			const mine = p.author_id === auth.profile?.id;
			if (tab === 'mine') return mine;
			if (p.status !== 'open') return false;
			if (discipline && p.discipline !== discipline) return false;
			if (level && p.level !== level) return false;
			if (minKg !== '' && minKg !== null && p.weight_kg < Number(minKg)) return false;
			if (maxKg !== '' && maxKg !== null && p.weight_kg > Number(maxKg)) return false;
			return true;
		})
	);

	async function contact(post) {
		busyId = post.id;
		const { data, error: err } = await supabase.rpc('start_conversation', {
			other_id: post.author_id,
			p_post_id: post.id
		});
		busyId = null;
		if (err) return (error = err.message);
		goto(`/messages/${data}`);
	}

	async function toggle(post) {
		busyId = post.id;
		const status = post.status === 'open' ? 'closed' : 'open';
		const { error: err } = await supabase.from('fight_posts').update({ status }).eq('id', post.id);
		busyId = null;
		if (err) return (error = err.message);
		post.status = status;
	}

	async function remove(post) {
		if (!confirm(t('f.confirmDelete'))) return;
		busyId = post.id;
		const { error: err } = await supabase.from('fight_posts').delete().eq('id', post.id);
		busyId = null;
		if (err) return (error = err.message);
		posts = posts.filter((p) => p.id !== post.id);
	}
</script>

<Protected>
	<section class="container-page py-10">
		<div class="flex flex-wrap items-end justify-between gap-4">
			<div>
				<h1 class="heading text-4xl">{t('f.title')}</h1>
				<p class="mt-1 text-zinc-400">{t('f.sub')}</p>
			</div>
			{#if !auth.profile.banned}
				<a href="/fights/new" class="btn-primary px-5 py-3">+ {t('f.new')}</a>
			{/if}
		</div>

		{#if auth.isMinor}
			<p class="alert-info mt-6">👥 {t('f.groupMinor')}</p>
		{/if}

		<!-- filters -->
		<div class="card mt-6 flex flex-wrap items-end gap-3 p-4">
			<div class="flex rounded-xl border border-line p-1">
				{#each ['all', 'mine'] as v (v)}
					<button
						class="rounded-lg px-4 py-1.5 text-sm font-semibold transition {tab === v
							? 'bg-brand text-white'
							: 'text-zinc-400 hover:text-white'}"
						onclick={() => (tab = v)}>{t('f.' + v)}</button
					>
				{/each}
			</div>

			{#if tab === 'all'}
				<div class="min-w-36 flex-1">
					<label class="label text-xs" for="disc">{t('f.discipline')}</label>
					<select id="disc" class="input py-2" bind:value={discipline}>
						<option value="">{t('f.all')}</option>
						{#each DISCIPLINES as d (d)}<option value={d}>{t('d.' + d)}</option>{/each}
					</select>
				</div>
				<div class="min-w-36 flex-1">
					<label class="label text-xs" for="lvl">{t('f.level')}</label>
					<select id="lvl" class="input py-2" bind:value={level}>
						<option value="">{t('f.all')}</option>
						{#each LEVELS as l (l)}<option value={l}>{t('l.' + l)}</option>{/each}
					</select>
				</div>
				<div class="min-w-44 flex-1">
					<span class="label text-xs">{t('f.weightRange')} (kg)</span>
					<div class="flex gap-2">
						<input type="number" class="input py-2" placeholder={t('f.min')} bind:value={minKg} />
						<input type="number" class="input py-2" placeholder={t('f.max')} bind:value={maxKg} />
					</div>
				</div>
			{/if}
		</div>

		{#if error}<p class="alert-error mt-6">{error}</p>{/if}

		{#if loading}
			<p class="mt-10 text-center text-sm text-zinc-400">{t('c.loading')}</p>
		{:else if visible.length === 0}
			<div class="card mt-6 p-12 text-center">
				<p class="text-4xl">🥊</p>
				<p class="mt-3 text-zinc-400">{t('f.empty')}</p>
			</div>
		{:else}
			<div class="mt-6 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
				{#each visible as post (post.id)}
					<FightCard
						{post}
						mine={post.author_id === auth.profile.id}
						busy={busyId === post.id}
						onContact={contact}
						onToggle={toggle}
						onDelete={remove}
					/>
				{/each}
			</div>
		{/if}
	</section>
</Protected>
