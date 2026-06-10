<script lang="ts">
	import type { Separator as SeparatorPrimitive } from "bits-ui";
	import { Separator } from "@app-template/web-ui/components/separator";
	import { cn } from "@app-template/web-ui/lib/utils";

	let {
		ref = $bindable(null),
		class: className,
		...restProps
	}: SeparatorPrimitive.RootProps = $props();
</script>

<Separator
	bind:ref
	data-slot="select-separator"
	class={cn("bg-border/50 -mx-1 my-1 h-px pointer-events-none", className)}
	{...restProps}
/>
