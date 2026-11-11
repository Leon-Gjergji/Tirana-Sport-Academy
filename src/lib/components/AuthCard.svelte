<script>
	let { title, subtitle = '', children, footer } = $props();
</script>

<div class="relative overflow-hidden">
	<div class="pointer-events-none absolute inset-0">
		<div class="absolute -top-32 left-1/4 h-80 w-80 rounded-full bg-brand/20 blur-[110px]"></div>
		<div class="absolute top-10 right-1/4 h-80 w-80 rounded-full bg-navy/30 blur-[110px]"></div>
	</div>
	<div class="container-page relative flex justify-center py-12 sm:py-20">
		<div class="card w-full max-w-md p-7 sm:p-9">
			<img src="/logo.png" alt="" class="mx-auto h-16 w-16" />
			<h1 class="heading mt-5 text-center text-3xl">{title}</h1>
			{#if subtitle}<p class="mt-2 text-center text-sm text-zinc-400">{subtitle}</p>{/if}
			<div class="mt-7">
				{@render children()}
			</div>
			{#if footer}
				<div class="mt-6 border-t border-line pt-5 text-center text-sm text-zinc-400">
					{@render footer()}
				</div>
			{/if}
		</div>
	</div>
</div>
