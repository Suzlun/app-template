<script lang="ts">
	import { cn, type WithElementRef } from "@app-template/web-ui/lib/utils";
	import type { HTMLAttributes } from "svelte/elements";
	import { Dialog as DialogPrimitive } from "bits-ui";
	import { Button } from "@app-template/web-ui/components/button";
	import XIcon from '@lucide/svelte/icons/x';

	let {
		ref = $bindable(null),
		class: className,
		children,
		showCloseButton = false,
		closeLabel,
		...restProps
	}: WithElementRef<HTMLAttributes<HTMLDivElement>> & {
		showCloseButton?: boolean;
		closeLabel: string;
	} = $props();
</script>

<div
	bind:this={ref}
	data-slot="dialog-footer"
	class={cn("gap-2 flex flex-col-reverse gap-2 sm:flex-row sm:justify-end", className)}
	{...restProps}
>
	{@render children?.()}
	{#if showCloseButton}
		<DialogPrimitive.Close>
			{#snippet child({ props })}
				<Button variant="outline" aria-label={closeLabel} {...props}>
					<XIcon />
				</Button>
			{/snippet}
		</DialogPrimitive.Close>
	{/if}
</div>
