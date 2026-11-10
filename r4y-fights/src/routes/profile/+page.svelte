<script>
	import { supabase } from '#lib/supabase.js';
	import { auth, loadProfile } from '#lib/auth.svelte.js';
	import { t } from '#lib/i18n.svelte.js';
	import { LEVELS } from '#lib/constants.js';
	import Protected from '#lib/components/Protected.svelte';
	import Avatar from '#lib/components/Avatar.svelte';

	let username = $state('');
	let weight = $state('');
	let level = $state('');
	let error = $state('');
	let saved = $state(false);
	let busy = $state(false);
	let uploading = $state(false);

	let filled = false;
	$effect(() => {
		if (auth.profile && !filled) {
			filled = true;
			username = auth.profile.username;
			weight = auth.profile.weight_kg ?? '';
			level = auth.profile.level ?? '';
		}
	});

	async function uploadPhoto(e) {
		const file = e.currentTarget.files?.[0];
		if (!file) return;
		error = '';
		if (file.size > 3 * 1024 * 1024) return (error = t('p.fileTooBig'));

		uploading = true;
		const ext = file.name.split('.').pop()?.toLowerCase() || 'jpg';
		// Files go into a folder named after the user id – the storage rules only allow that
		const path = `${auth.profile.id}/avatar-${Date.now()}.${ext}`;
		const { error: upErr } = await supabase.storage.from('avatars').upload(path, file, { contentType: file.type });
		if (upErr) {
			uploading = false;
			return (error = upErr.message);
		}
		const { data } = supabase.storage.from('avatars').getPublicUrl(path);
		const { error: dbErr } = await supabase
			.from('profiles')
			.update({ avatar_url: data.publicUrl })
			.eq('id', auth.profile.id);
		uploading = false;
		if (dbErr) return (error = dbErr.message);
		await loadProfile();
	}

	async function save(e) {
		e.preventDefault();
		error = '';
		saved = false;
		const name = username.trim();
		if (!/^[a-zA-Z0-9_.]{3,24}$/.test(name)) return (error = t('auth.err.usernameFormat'));

		busy = true;
		const { error: err } = await supabase
			.from('profiles')
			.update({
				username: name,
				weight_kg: weight === '' || weight === null ? null : Number(weight),
				level: level || null
			})
			.eq('id', auth.profile.id);
		busy = false;
		if (err) return (error = err.code === '23505' ? t('auth.err.username') : err.message);
		saved = true;
		await loadProfile();
	}
</script>

<Protected>
	<section class="container-page flex justify-center py-10">
		<div class="card w-full max-w-xl p-7 sm:p-9">
			<h1 class="heading text-3xl">{t('p.title')}</h1>

			<div class="mt-7 flex items-center gap-5">
				<Avatar src={auth.profile.avatar_url} name={auth.profile.username} size={88} />
				<div>
					<label class="btn-secondary cursor-pointer">
						📷 {uploading ? t('p.uploading') : t('p.photo')}
						<input type="file" accept="image/*" class="hidden" disabled={uploading} onchange={uploadPhoto} />
					</label>
					<p class="mt-2 text-xs text-zinc-500">{auth.session?.user?.email}</p>
					<p class="mt-1 text-xs text-zinc-500">
						{t('p.group')}:
						<span class="badge {auth.isMinor ? 'bg-navy/50 text-indigo-200' : 'bg-brand/15 text-red-300'}">
							{auth.isMinor ? t('p.minor') : t('p.adult')}
						</span>
					</p>
				</div>
			</div>

			<form class="mt-8 space-y-5" onsubmit={save}>
				<div>
					<label class="label" for="username">{t('auth.username')}</label>
					<input id="username" class="input" maxlength="24" required bind:value={username} />
				</div>
				<div class="grid gap-4 sm:grid-cols-2">
					<div>
						<label class="label" for="weight">{t('f.weightKg')}</label>
						<input id="weight" type="number" step="0.1" min="20" max="250" class="input" bind:value={weight} />
					</div>
					<div>
						<label class="label" for="level">{t('f.level')}</label>
						<select id="level" class="input" bind:value={level}>
							<option value="">—</option>
							{#each LEVELS as l (l)}<option value={l}>{t('l.' + l)}</option>{/each}
						</select>
					</div>
				</div>

				{#if error}<p class="alert-error">{error}</p>{/if}
				{#if saved}<p class="alert-ok">{t('p.saved')}</p>{/if}

				<button class="btn-primary w-full py-3" disabled={busy}>{busy ? t('c.loading') : t('p.save')}</button>
			</form>
		</div>
	</section>
</Protected>
