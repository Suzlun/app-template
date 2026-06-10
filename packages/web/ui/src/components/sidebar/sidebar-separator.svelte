<script lang="ts">
	import { Separator } from "@app-template/web-ui/components/separator";
	import { cn } from "@app-template/web-ui/lib/utils";
	import type { ComponentProps } from "svelte";

	let {
		ref = $bindable(null),
		class: className,
		...restProps
	}: ComponentProps<typeof Separator> = $props();
</script>

<Separator
	bind:ref
	data-slot="sidebar-separator"
	data-sidebar="separator"
	class={cn("bg-sidebar-border mx-4 w-auto", className)}
	{...restProps}
/>
