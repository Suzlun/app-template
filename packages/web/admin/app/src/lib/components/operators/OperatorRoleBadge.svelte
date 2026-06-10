<script lang="ts">
	import { Badge } from '@app-template/web-ui/components';

	const { role, label = role }: { role: string; label?: string } = $props();

	const variant = $derived(
		role === 'admin' ? 'default' : role === 'operator' ? 'info' : 'secondary'
	);
</script>

<Badge {variant}>{label}</Badge>
