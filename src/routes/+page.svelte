<script>
	import { auth } from '#lib/auth.svelte.js';
	import { t } from '#lib/i18n.svelte.js';
	import { ACADEMY, DISCIPLINES } from '#lib/constants.js';

	const ctaHref = $derived(auth.session ? '/fights' : '/signup');

	const icons = {
		boxing: '🥊',
		kickboxing: '🦵',
		muay_thai: '💥',
		mma: '🤼',
		taekwondo: '🥋'
	};
</script>

<!-- HERO -->
<section class="relative overflow-hidden">
	<div class="pointer-events-none absolute inset-0">
		<div class="absolute -top-40 -left-40 h-[32rem] w-[32rem] rounded-full bg-brand/25 blur-[120px]"></div>
		<div class="absolute -right-40 top-20 h-[32rem] w-[32rem] rounded-full bg-navy/40 blur-[120px]"></div>
	</div>

	<div class="container-page relative grid items-center gap-12 py-16 md:grid-cols-[1.2fr_1fr] md:py-24">
		<div class="min-w-0">
			<p class="mb-5 inline-flex items-center gap-2 rounded-full border border-line bg-panel/70 px-3 py-1 text-xs font-semibold tracking-wider text-zinc-300 uppercase">
				<span class="h-1.5 w-1.5 rounded-full bg-brand"></span>
				{t('home.eyebrow')}
			</p>
			<h1 class="heading text-[2.4rem] leading-[1.05] break-words sm:text-6xl lg:text-7xl">
				{t('home.title1')} <br />
				<span class="bg-linear-to-r from-brand to-navy-light bg-clip-text text-transparent">{t('home.title2')}</span>
			</h1>
			<p class="mt-6 max-w-xl text-lg text-zinc-300">{t('home.subtitle')}</p>
			<div class="mt-8 flex flex-wrap gap-3">
				<a href={ctaHref} class="btn-primary px-6 py-3 text-base">{t('home.cta')} →</a>
				<a href="#how" class="btn-secondary px-6 py-3 text-base">{t('home.cta2')}</a>
			</div>

			<dl class="mt-12 grid max-w-lg grid-cols-3 gap-6 border-t border-line pt-6">
				<div>
					<dt class="heading text-3xl text-white">5</dt>
					<dd class="mt-1 text-xs text-zinc-400">{t('home.stat1')}</dd>
				</div>
				<div>
					<dt class="heading text-3xl text-white">100%</dt>
					<dd class="mt-1 text-xs text-zinc-400">{t('home.stat2')}</dd>
				</div>
				<div>
					<dt class="heading text-3xl text-white">U18</dt>
					<dd class="mt-1 text-xs text-zinc-400">{t('home.stat3')}</dd>
				</div>
			</dl>
		</div>

		<div class="relative mx-auto w-56 sm:w-80 md:w-full md:max-w-sm">
			<div class="absolute inset-6 rounded-full bg-linear-to-br from-brand/40 to-navy/50 blur-2xl"></div>
			<img src="/logo.png" alt="Tirana Sport Academy logo" class="relative w-full drop-shadow-2xl" />
		</div>
	</div>
</section>

<!-- DISCIPLINES -->
<section class="container-page py-12">
	<div class="mb-8 flex items-end justify-between gap-4">
		<div>
			<h2 class="heading text-3xl sm:text-4xl">{t('home.disciplines')}</h2>
			<p class="mt-2 text-zinc-400">{t('home.disciplinesSub')}</p>
		</div>
	</div>
	<div class="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-5">
		{#each DISCIPLINES as d, i (d)}
			<div class="card group relative overflow-hidden p-5 transition hover:-translate-y-0.5 hover:border-brand/60">
				<div class="absolute top-0 left-0 h-1 w-full {i % 2 === 0 ? 'bg-brand' : 'bg-navy-light'}"></div>
				<div class="text-3xl">{icons[d]}</div>
				<p class="heading mt-4 text-lg">{t('d.' + d)}</p>
			</div>
		{/each}
	</div>
</section>

<!-- HOW IT WORKS -->
<section id="how" class="container-page scroll-mt-20 py-12">
	<h2 class="heading mb-8 text-3xl sm:text-4xl">{t('home.how')}</h2>
	<div class="grid gap-4 md:grid-cols-3">
		{#each [1, 2, 3] as n (n)}
			<div class="card p-6">
				<div class="heading flex h-11 w-11 items-center justify-center rounded-xl bg-brand text-xl text-white">{n}</div>
				<h3 class="heading mt-5 text-xl">{t(`home.step${n}`)}</h3>
				<p class="mt-2 text-sm leading-relaxed text-zinc-400">{t(`home.step${n}d`)}</p>
			</div>
		{/each}
	</div>
</section>

<!-- SAFETY + CONTACT -->
<section class="container-page grid gap-4 py-12 md:grid-cols-2">
	<div class="card relative overflow-hidden p-7">
		<div class="absolute -right-16 -bottom-16 h-48 w-48 rounded-full bg-navy/30 blur-3xl"></div>
		<h2 class="heading relative text-2xl">{t('home.safety')}</h2>
		<ul class="relative mt-5 space-y-3 text-sm text-zinc-300">
			{#each [1, 2, 3] as n (n)}
				<li class="flex gap-3">
					<span class="mt-0.5 flex h-5 w-5 shrink-0 items-center justify-center rounded-full bg-brand/20 text-xs text-brand">✓</span>
					{t(`home.safety${n}`)}
				</li>
			{/each}
		</ul>
	</div>

	<div class="card relative overflow-hidden p-7">
		<div class="absolute -right-16 -bottom-16 h-48 w-48 rounded-full bg-brand/25 blur-3xl"></div>
		<h2 class="heading relative text-2xl">{t('home.contact')}</h2>
		<div class="relative mt-5 space-y-3 text-sm">
			<p class="flex items-center gap-3 text-zinc-300"><span class="text-lg">📍</span> {ACADEMY.city}</p>
			<a href={ACADEMY.phoneHref} class="flex items-center gap-3 text-zinc-300 hover:text-white"><span class="text-lg">📞</span> {ACADEMY.phone}</a>
			<div class="flex flex-wrap gap-2 pt-3">
				<a href={ACADEMY.whatsapp} target="_blank" rel="noopener" class="btn-secondary">WhatsApp</a>
				<a href={ACADEMY.tiktok} target="_blank" rel="noopener" class="btn-secondary">TikTok @r4yfromthefuture</a>
			</div>
		</div>
	</div>
</section>

<!-- FINAL CTA -->
<section class="container-page py-12">
	<div class="relative overflow-hidden rounded-3xl bg-linear-to-r from-brand-dark via-brand to-navy p-10 text-center sm:p-14">
		<h2 class="heading text-3xl text-white sm:text-4xl">{t('home.ready')}</h2>
		<p class="mx-auto mt-3 max-w-xl text-white/85">{t('home.readySub')}</p>
		<a href={ctaHref} class="btn mt-7 bg-white px-7 py-3 text-base text-ink hover:bg-zinc-100">{t('home.cta')} →</a>
	</div>
</section>
