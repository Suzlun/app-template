<script lang="ts">
	import { Button, type ButtonProps } from "@app-template/ui/components/button";

	let { ref = $bindable(null), ...restProps }: ButtonProps = $props();
</script>

<Button bind:ref type="submit" {...restProps} />
