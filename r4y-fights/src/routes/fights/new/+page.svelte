<script>
	import { goto } from '$app/navigation';
	import { supabase } from '#lib/supabase.js';
	import { auth } from '#lib/auth.svelte.js';
	import { t } from '#lib/i18n.svelte.js';
	import { DISCIPLINES, LEVELS } from '#lib/constants.js';
	import Protected from '#lib/components/Protected.svelte';

	let discipline = $state('boxing');
	let level = $state('beginner');
	let weight = $state('');
	let preferredDate = $state('');
	let notes = $state('');
	let error = $state('');
	let busy = $state(false);

	const today = new Date().toISOString().slice(0, 10);

	// Pre-fill from the profile
	let filled = false;
	$effect(() => {
		if (auth.profile && !filled) {
			filled = true;
			if (auth.profile.level) level = auth.profile.level;
			if (auth.profile.weight_kg) weight = auth.profile.weight_kg;
		}
	});

	async function submit(e) {
		e.preventDefault();
		error = '';
		busy = true;
		const { error: err } = await supabase.from('fight_posts').insert({
			discipline,
			level,
			weight_kg: Number(weight),
			preferred_date: preferredDate || null,
			notes: notes.trim() || null
		});
		busy = false;
		if (err) return (error = err.message);
		goto('/fights');
	}
</script>

<Protected>
	<section class="container-page flex justify-center py-10">
		<div class="card w-full max-w-xl p-7 sm:p-9">
			<h1 class="heading text-3xl">{t('f.newTitle')}</h1>
			<p class="mt-2 text-sm text-zinc-400">{t('f.newSub')}</p>

			<form class="mt-7 space-y-5" onsubmit={submit}>
				<div>
					<span class="label">{t('f.discipline')}</span>
					<div class="grid grid-cols-2 gap-2 sm:grid-cols-3">
						{#each DISCIPLINES as d (d)}
							<button
								type="button"
								class="rounded-xl border px-3 py-2.5 text-sm font-semibold transition {discipline === d
									? 'border-brand bg-brand/15 text-white'
									: 'border-line text-zinc-400 hover:border-zinc-500 hover:text-white'}"
								onclick={() => (discipline = d)}>{t('d.' + d)}</button
							>
						{/each}
					</div>
				</div>

				<div class="grid gap-4 sm:grid-cols-2">
					<div>
						<label class="label" for="level">{t('f.level')}</label>
						<select id="level" class="input" bind:value={level}>
							{#each LEVELS as l (l)}<option value={l}>{t('l.' + l)}</option>{/each}
						</select>
					</div>
					<div>
						<label class="label" for="weight">{t('f.weightKg')}</label>
						<input id="weight" type="number" step="0.1" min="20" max="250" class="input" required bind:value={weight} />
					</div>
				</div>

				<div>
					<label class="label" for="date">{t('f.date')} <span class="text-zinc-500">({t('c.optional')})</span></label>
					<input id="date" type="date" min={today} class="input" bind:value={preferredDate} />
				</div>

				<div>
					<label class="label" for="notes">{t('f.notes')} <span class="text-zinc-500">({t('c.optional')})</span></label>
					<textarea id="notes" rows="4" maxlength="500" class="input" placeholder={t('f.notesPh')} bind:value={notes}></textarea>
				</div>

				{#if error}<p class="alert-error">{error}</p>{/if}

				<div class="flex gap-3">
					<a href="/fights" class="btn-secondary flex-1 py-3">{t('f.cancel')}</a>
					<button class="btn-primary flex-1 py-3" disabled={busy || auth.profile.banned}>
						{busy ? t('c.loading') : t('f.publish')}
					</button>
				</div>
			</form>
		</div>
	</section>
</Protected>
