<script>
	import { t, formatDate } from '#lib/i18n.svelte.js';
	import Avatar from './Avatar.svelte';

	let { post, mine = false, onContact, onToggle, onDelete, busy = false } = $props();

	const accent = {
		boxing: 'bg-brand/15 text-red-300',
		kickboxing: 'bg-navy/40 text-indigo-200',
		muay_thai: 'bg-amber-500/15 text-amber-200',
		mma: 'bg-emerald-500/15 text-emerald-200',
		taekwondo: 'bg-sky-500/15 text-sky-200'
	};
</script>

<article class="card flex flex-col p-5 transition hover:border-zinc-600 {post.status === 'closed' ? 'opacity-60' : ''}">
	<div class="flex items-start justify-between gap-3">
		<div class="flex items-center gap-3">
			<Avatar src={post.author?.avatar_url} name={post.author?.username} size={44} />
			<div>
				<p class="font-semibold">
					{post.author?.username ?? '—'}
					{#if mine}<span class="ml-1 text-xs font-normal text-zinc-500">({t('f.you')})</span>{/if}
				</p>
				<p class="text-xs text-zinc-500">{formatDate(post.created_at, true)}</p>
			</div>
		</div>
		<span class="badge {accent[post.discipline]}">{t('d.' + post.discipline)}</span>
	</div>

	<dl class="mt-5 grid grid-cols-3 gap-2 text-center">
		<div class="rounded-xl bg-panel-2 px-2 py-2.5">
			<dt class="text-[11px] tracking-wide text-zinc-500 uppercase">{t('f.weight')}</dt>
			<dd class="heading mt-0.5 text-lg">{post.weight_kg} kg</dd>
		</div>
		<div class="rounded-xl bg-panel-2 px-2 py-2.5">
			<dt class="text-[11px] tracking-wide text-zinc-500 uppercase">{t('f.age')}</dt>
			<dd class="heading mt-0.5 text-lg">{post.age} {t('f.years')}</dd>
		</div>
		<div class="rounded-xl bg-panel-2 px-2 py-2.5">
			<dt class="text-[11px] tracking-wide text-zinc-500 uppercase">{t('f.level')}</dt>
			<dd class="heading mt-1 truncate text-sm leading-6">{t('l.' + post.level)}</dd>
		</div>
	</dl>

	<p class="mt-4 flex items-center gap-2 text-sm text-zinc-300">
		<span>📅</span>
		{post.preferred_date ? formatDate(post.preferred_date) : t('f.anyDate')}
		{#if post.status === 'closed'}<span class="badge ml-auto bg-zinc-700 text-zinc-300">{t('f.closed')}</span>{/if}
	</p>

	{#if post.prize}
		<p class="mt-3 rounded-xl border border-amber-400/30 bg-amber-400/10 px-3 py-2 text-sm text-amber-200">
			🏆 <span class="font-semibold">{t('f.prize')}:</span> {post.prize}
		</p>
	{/if}

	{#if post.notes}
		<p class="mt-3 text-sm leading-relaxed whitespace-pre-line text-zinc-400">{post.notes}</p>
	{/if}

	<div class="mt-auto flex gap-2 pt-5">
		{#if mine}
			<button class="btn-secondary flex-1" disabled={busy} onclick={() => onToggle?.(post)}>
				{post.status === 'open' ? t('f.close') : t('f.reopen')}
			</button>
			<button class="btn-danger" disabled={busy} onclick={() => onDelete?.(post)}>{t('f.delete')}</button>
		{:else if post.status === 'open'}
			<button class="btn-primary flex-1" disabled={busy} onclick={() => onContact?.(post)}>💬 {t('f.contact')}</button>
		{/if}
	</div>
</article>
