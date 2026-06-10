import { fileURLToPath } from 'node:url';

import { defineConfig } from 'vitest/config';

export default defineConfig({
  resolve: {
    alias: {
      '@app-template/admin-domain': fileURLToPath(
        new URL('../domain/src/index.ts', import.meta.url)
      ),
      '@app-template/i18n': fileURLToPath(
        new URL('../../frontend/i18n/src/index.ts', import.meta.url)
      ),
    },
  },
  test: {
    globals: true,
    environment: 'node',
    include: ['src/**/*.{test,spec}.{ts,js}'],
  },
});
