<script lang="ts">
  import type { Snippet } from 'svelte';
  import { useObservability } from '@app-template/domain';
  import { env } from '$env/dynamic/public';

  import '@app-template/ui/styles.css';
  import '../app.css';

  let { children }: { children: Snippet } = $props();

  const otelCollectorUrl = env.PUBLIC_OTEL_COLLECTOR_URL ?? 'http://localhost:4318/v1/traces';

  useObservability('app-template-app', otelCollectorUrl);
</script>

{@render children()}
