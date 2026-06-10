<script lang="ts">
	import type { ComponentProps } from "svelte";
	import { Input } from "@app-template/web-ui/components/input";
	import { cn } from "@app-template/web-ui/lib/utils";

	let {
		ref = $bindable(null),
		value = $bindable(""),
		class: className,
		...restProps
	}: ComponentProps<typeof Input> = $props();
</script>

<Input
	bind:ref
	bind:value
	data-slot="sidebar-input"
	data-sidebar="input"
	class={cn("bg-background h-8 w-full shadow-none", className)}
	{...restProps}
/>
