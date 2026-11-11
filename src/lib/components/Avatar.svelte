<script>
	let { src = null, name = '', size = 40 } = $props();
	const initials = $derived((name || '?').slice(0, 2).toUpperCase());
</script>

{#if src}
	<img
		{src}
		alt={name}
		class="shrink-0 rounded-full border border-line object-cover"
		style="width:{size}px;height:{size}px"
	/>
{:else}
	<div
		class="flex shrink-0 items-center justify-center rounded-full bg-linear-to-br from-brand to-navy font-display font-semibold text-white"
		style="width:{size}px;height:{size}px;font-size:{Math.round(size * 0.38)}px"
	>
		{initials}
	</div>
{/if}
