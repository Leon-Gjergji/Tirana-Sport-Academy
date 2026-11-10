<script>
	import { page } from '$app/state';
	import { tick } from 'svelte';
	import { supabase, POST_COLUMNS } from '#lib/supabase.js';
	import { auth } from '#lib/auth.svelte.js';
	import { t, formatDate } from '#lib/i18n.svelte.js';
	import Protected from '#lib/components/Protected.svelte';
	import Avatar from '#lib/components/Avatar.svelte';

	const id = $derived(page.params.id);

	let conv = $state(null);
	let people = $state({});
	let post = $state(null);
	let messages = $state([]);
	let loading = $state(true);
	let notFound = $state(false);
	let error = $state('');
	let text = $state('');
	let sending = $state(false);
	let scroller = $state();

	const me = $derived(auth.profile?.id);
	const isParticipant = $derived(conv && (conv.user_a === me || conv.user_b === me));
	const other = $derived(conv ? people[conv.user_a === me ? conv.user_b : conv.user_a] : null);

	// Load the chat and listen for new messages. Runs again if you open another chat.
	$effect(() => {
		if (!auth.profile || !id) return;
		const convId = id;
		load(convId);

		const channel = supabase
			.channel(`chat-${convId}`)
			.on(
				'postgres_changes',
				{ event: 'INSERT', schema: 'public', table: 'messages', filter: `conversation_id=eq.${convId}` },
				(payload) => addMessage(payload.new)
			)
			.subscribe();

		return () => supabase.removeChannel(channel);
	});

	async function load(convId) {
		loading = true;
		notFound = false;
		error = '';
		const { data: c } = await supabase
			.from('conversations')
			.select('id, user_a, user_b, post_id, created_at')
			.eq('id', convId)
			.maybeSingle();
		if (!c) {
			loading = false;
			notFound = true;
			return;
		}
		conv = c;

		const [{ data: profiles }, { data: msgs }, postRes] = await Promise.all([
			supabase.from('profiles').select('id, username, avatar_url').in('id', [c.user_a, c.user_b]),
			supabase
				.from('messages')
				.select('id, conversation_id, sender_id, body, created_at')
				.eq('conversation_id', convId)
				.order('created_at', { ascending: true })
				.limit(500),
			c.post_id
				? supabase.from('fight_posts').select(POST_COLUMNS).eq('id', c.post_id).maybeSingle()
				: Promise.resolve({ data: null })
		]);
		people = Object.fromEntries((profiles ?? []).map((p) => [p.id, p]));
		messages = msgs ?? [];
		post = postRes.data;
		loading = false;
		scrollDown();
	}

	function addMessage(m) {
		if (messages.some((x) => x.id === m.id)) return;
		messages.push(m);
		scrollDown();
	}

	async function scrollDown() {
		await tick();
		if (scroller) scroller.scrollTop = scroller.scrollHeight;
	}

	async function send(e) {
		e.preventDefault();
		const body = text.trim();
		if (!body) return;
		sending = true;
		error = '';
		const { data, error: err } = await supabase
			.from('messages')
			.insert({ conversation_id: id, body })
			.select('id, conversation_id, sender_id, body, created_at')
			.single();
		sending = false;
		if (err) return (error = err.message);
		text = '';
		addMessage(data);
	}

	function onKey(e) {
		if (e.key === 'Enter' && !e.shiftKey) send(e);
	}
</script>

<Protected>
	<section class="container-page max-w-3xl py-6 sm:py-10">
		<a href={isParticipant || !conv ? '/messages' : '/admin'} class="text-sm text-zinc-400 hover:text-white">
			← {isParticipant || !conv ? t('m.back') : t('a.title')}
		</a>

		{#if loading}
			<p class="mt-10 text-center text-sm text-zinc-400">{t('c.loading')}</p>
		{:else if notFound}
			<p class="alert-error mt-6">{t('m.notFound')}</p>
		{:else}
			<div class="card mt-4 flex h-[calc(100vh-11rem)] min-h-[28rem] flex-col overflow-hidden">
				<!-- header -->
				<div class="flex items-center gap-3 border-b border-line px-5 py-4">
					{#if isParticipant}
						<Avatar src={other?.avatar_url} name={other?.username} size={42} />
						<p class="font-semibold">{other?.username ?? '—'}</p>
					{:else}
						<p class="font-semibold">
							{people[conv.user_a]?.username ?? '—'} ↔ {people[conv.user_b]?.username ?? '—'}
						</p>
					{/if}
				</div>

				{#if post}
					<div class="border-b border-line bg-panel-2/60 px-5 py-2.5 text-xs text-zinc-400">
						{t('m.about')}: <span class="font-semibold text-zinc-200">{t('d.' + post.discipline)}</span>
						· {post.weight_kg} kg · {t('l.' + post.level)}
						{#if post.preferred_date}· {formatDate(post.preferred_date)}{/if}
					</div>
				{/if}

				<!-- messages -->
				<div bind:this={scroller} class="flex-1 space-y-2 overflow-y-auto px-4 py-5 sm:px-5">
					<p class="mb-4 text-center text-xs text-zinc-500">{t('m.start')}</p>
					{#each messages as m (m.id)}
						{@const mine = m.sender_id === me}
						<div class="flex {mine ? 'justify-end' : 'justify-start'}">
							<div
								class="max-w-[80%] rounded-2xl px-4 py-2.5 text-sm {mine
									? 'rounded-br-md bg-brand text-white'
									: 'rounded-bl-md bg-panel-2 text-zinc-100'}"
							>
								{#if !isParticipant}
									<p class="mb-0.5 text-[11px] font-semibold opacity-70">{people[m.sender_id]?.username}</p>
								{/if}
								<p class="break-words whitespace-pre-line">{m.body}</p>
								<p class="mt-1 text-right text-[10px] opacity-60">{formatDate(m.created_at, true)}</p>
							</div>
						</div>
					{/each}
				</div>

				{#if error}<p class="alert-error mx-4 mb-3">{error}</p>{/if}

				<!-- input -->
				{#if isParticipant}
					<form class="flex items-end gap-2 border-t border-line p-3" onsubmit={send}>
						<textarea
							rows="1"
							maxlength="2000"
							class="input max-h-32 resize-none"
							placeholder={t('m.placeholder')}
							bind:value={text}
							onkeydown={onKey}
							disabled={auth.profile.banned}
						></textarea>
						<button class="btn-primary px-5 py-2.5" disabled={sending || !text.trim() || auth.profile.banned}>
							{t('m.send')}
						</button>
					</form>
				{:else}
					<p class="border-t border-line px-5 py-3 text-xs text-zinc-400">🔒 {t('m.readOnly')}</p>
				{/if}
			</div>
		{/if}
	</section>
</Protected>
