<script>
	import { supabase, POST_COLUMNS } from '#lib/supabase.js';
	import { auth } from '#lib/auth.svelte.js';
	import { t, formatDate } from '#lib/i18n.svelte.js';
	import { ageFrom } from '#lib/constants.js';
	import { loadConversations } from '#lib/conversations.js';
	import Protected from '#lib/components/Protected.svelte';
	import Avatar from '#lib/components/Avatar.svelte';

	let tab = $state('users');
	let users = $state([]);
	let posts = $state([]);
	let convs = $state([]);
	let prizes = $state({});
	let search = $state('');
	let error = $state('');
	let loading = $state(true);
	let busyId = $state(null);

	let loaded = false;
	$effect(() => {
		if (auth.profile?.role === 'admin' && !loaded) {
			loaded = true;
			loadAll();
		}
	});

	async function loadAll() {
		loading = true;
		error = '';
		try {
			const [u, p, c] = await Promise.all([
				supabase.rpc('admin_users'),
				supabase.from('fight_posts').select(POST_COLUMNS).order('created_at', { ascending: false }).limit(500),
				loadConversations()
			]);
			if (u.error) throw u.error;
			if (p.error) throw p.error;
			users = u.data;
			posts = p.data;
			convs = c;
			prizes = Object.fromEntries(posts.map((x) => [x.id, x.prize ?? '']));
		} catch (e) {
			error = e.message;
		}
		loading = false;
	}

	const q = $derived(search.trim().toLowerCase());
	const filteredUsers = $derived(
		users.filter((u) => !q || u.username.toLowerCase().includes(q) || u.email?.toLowerCase().includes(q))
	);
	const filteredPosts = $derived(posts.filter((p) => !q || p.author?.username?.toLowerCase().includes(q)));
	const filteredConvs = $derived(
		convs.filter(
			(c) => !q || c.a?.username?.toLowerCase().includes(q) || c.b?.username?.toLowerCase().includes(q)
		)
	);

	async function setBanned(user, value) {
		busyId = user.id;
		const { error: err } = await supabase.rpc('admin_set_banned', { target: user.id, value });
		busyId = null;
		if (err) return (error = err.message);
		user.banned = value;
	}

	async function resetPassword(user) {
		const pw = prompt(t('a.resetPrompt').replace('{name}', user.username));
		if (pw === null) return;
		if (pw.length < 8) return (error = t('auth.err.short'));
		busyId = user.id;
		const { error: err } = await supabase.rpc('admin_reset_password', { target: user.id, new_password: pw });
		busyId = null;
		if (err) return (error = err.message);
		error = '';
		alert(t('a.resetDone').replace('{pw}', pw));
	}

	async function savePrize(post) {
		busyId = post.id;
		const { error: err } = await supabase.rpc('admin_set_prize', { target: post.id, value: prizes[post.id] ?? '' });
		busyId = null;
		if (err) return (error = err.message);
		post.prize = prizes[post.id]?.trim() || null;
	}

	async function deletePost(post) {
		if (!confirm(t('f.confirmDelete'))) return;
		busyId = post.id;
		const { error: err } = await supabase.from('fight_posts').delete().eq('id', post.id);
		busyId = null;
		if (err) return (error = err.message);
		posts = posts.filter((p) => p.id !== post.id);
	}

	const tabs = $derived([
		{ id: 'users', label: t('a.users'), count: users.length },
		{ id: 'posts', label: t('a.posts'), count: posts.length },
		{ id: 'chats', label: t('a.chats'), count: convs.length }
	]);
</script>

<Protected admin>
	<section class="container-page py-10">
		<h1 class="heading text-4xl">{t('a.title')}</h1>

		<div class="mt-6 flex flex-wrap items-center justify-between gap-3">
			<div class="flex rounded-xl border border-line p-1">
				{#each tabs as tb (tb.id)}
					<button
						class="rounded-lg px-4 py-1.5 text-sm font-semibold transition {tab === tb.id
							? 'bg-brand text-white'
							: 'text-zinc-400 hover:text-white'}"
						onclick={() => (tab = tb.id)}
					>
						{tb.label} <span class="ml-1 opacity-70">{tb.count}</span>
					</button>
				{/each}
			</div>
			<input class="input max-w-xs py-2" placeholder={t('a.search')} bind:value={search} />
		</div>

		{#if error}<p class="alert-error mt-6">{error}</p>{/if}

		{#if loading}
			<p class="mt-10 text-center text-sm text-zinc-400">{t('c.loading')}</p>
		{:else if tab === 'users'}
			<div class="card mt-6 overflow-x-auto">
				<table class="w-full min-w-[56rem] text-left text-sm">
					<thead class="border-b border-line text-xs tracking-wide text-zinc-500 uppercase">
						<tr>
							<th class="px-4 py-3">{t('a.user')}</th>
							<th class="px-4 py-3">{t('f.age')}</th>
							<th class="px-4 py-3">{t('auth.guardian')}</th>
							<th class="px-4 py-3">{t('f.weight')}</th>
							<th class="px-4 py-3">{t('f.level')}</th>
							<th class="px-4 py-3">{t('a.joined')}</th>
							<th class="px-4 py-3">{t('a.status')}</th>
							<th class="px-4 py-3"></th>
						</tr>
					</thead>
					<tbody class="divide-y divide-line">
						{#each filteredUsers as u (u.id)}
							{@const age = ageFrom(u.birth_date)}
							<tr class="hover:bg-panel-2/50">
								<td class="px-4 py-3">
									<p class="font-semibold">
										{u.username}
										{#if u.role === 'admin'}<span class="badge ml-1 bg-navy/60 text-indigo-200">admin</span>{/if}
									</p>
									<p class="text-xs text-zinc-500">{u.email}</p>
								</td>
								<td class="px-4 py-3">
									{age}
									{#if age < 18}<span class="badge ml-1 bg-navy/50 text-indigo-200">U18</span>{/if}
								</td>
								<td class="px-4 py-3 text-zinc-300">{u.guardian_phone ?? '—'}</td>
								<td class="px-4 py-3">{u.weight_kg ? `${u.weight_kg} kg` : '—'}</td>
								<td class="px-4 py-3">{u.level ? t('l.' + u.level) : '—'}</td>
								<td class="px-4 py-3 text-zinc-400">{formatDate(u.created_at)}</td>
								<td class="px-4 py-3">
									{#if u.banned}
										<span class="badge bg-brand/20 text-red-300">{t('a.banned')}</span>
									{:else}
										<span class="badge bg-emerald-500/15 text-emerald-300">{t('a.active')}</span>
									{/if}
								</td>
								<td class="space-x-1 px-4 py-3 text-right whitespace-nowrap">
									<button class="btn-secondary py-1.5" disabled={busyId === u.id} onclick={() => resetPassword(u)}>🔑 {t('a.resetPw')}</button>
									{#if u.id !== auth.profile.id}
										{#if u.banned}
											<button class="btn-secondary py-1.5" disabled={busyId === u.id} onclick={() => setBanned(u, false)}>{t('a.unban')}</button>
										{:else}
											<button class="btn-danger py-1.5" disabled={busyId === u.id} onclick={() => setBanned(u, true)}>{t('a.ban')}</button>
										{/if}
									{/if}
								</td>
							</tr>
						{/each}
					</tbody>
				</table>
			</div>
		{:else if tab === 'posts'}
			<div class="mt-6 space-y-3">
				{#each filteredPosts as p (p.id)}
					<div class="card flex flex-col gap-4 p-4 lg:flex-row lg:items-center">
						<div class="flex min-w-0 flex-1 items-center gap-3">
							<Avatar src={p.author?.avatar_url} name={p.author?.username} size={40} />
							<div class="min-w-0">
								<p class="font-semibold">
									{p.author?.username}
									{#if p.is_minor}<span class="badge ml-1 bg-navy/50 text-indigo-200">U18</span>{/if}
									{#if p.status === 'closed'}<span class="badge ml-1 bg-zinc-700 text-zinc-300">{t('f.closed')}</span>{/if}
								</p>
								<p class="truncate text-xs text-zinc-400">
									{t('d.' + p.discipline)} · {p.weight_kg} kg · {p.age} {t('f.years')} · {t('l.' + p.level)}
									· {p.preferred_date ? formatDate(p.preferred_date) : t('f.anyDate')}
								</p>
								{#if p.notes}<p class="mt-1 truncate text-xs text-zinc-500">{p.notes}</p>{/if}
							</div>
						</div>
						<div class="flex flex-wrap items-center gap-2">
							<input class="input w-56 py-2" maxlength="120" placeholder={t('a.prizePh')} bind:value={prizes[p.id]} />
							<button class="btn-secondary py-2" disabled={busyId === p.id} onclick={() => savePrize(p)}>🏆 {t('a.setPrize')}</button>
							<button class="btn-danger py-2" disabled={busyId === p.id} onclick={() => deletePost(p)}>{t('f.delete')}</button>
						</div>
					</div>
				{/each}
			</div>
		{:else}
			<ul class="card mt-6 divide-y divide-line overflow-hidden">
				{#each filteredConvs as c (c.id)}
					<li>
						<a href="/messages/{c.id}" class="flex items-center gap-4 px-5 py-4 hover:bg-panel-2">
							<div class="flex -space-x-3">
								<Avatar src={c.a?.avatar_url} name={c.a?.username} size={36} />
								<Avatar src={c.b?.avatar_url} name={c.b?.username} size={36} />
							</div>
							<p class="flex-1 font-semibold">{c.a?.username} ↔ {c.b?.username}</p>
							<p class="text-xs text-zinc-500">{t('a.last')}: {formatDate(c.last_message_at, true)}</p>
							<span class="btn-secondary py-1.5">{t('a.open')}</span>
						</a>
					</li>
				{/each}
			</ul>
		{/if}
	</section>
</Protected>
