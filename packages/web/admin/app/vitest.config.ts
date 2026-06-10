import { fileURLToPath } from 'node:url';

import { defineConfig } from 'vitest/config';

export default defineConfig({
  resolve: {
    alias: {
      '@app-template/web-admin-domain': fileURLToPath(
        new URL('../domain/src/index.ts', import.meta.url)
      ),
      '@app-template/web-i18n': fileURLToPath(new URL('../../i18n/src/index.ts', import.meta.url)),
    },
  },
  test: {
    globals: true,
    environment: 'node',
    include: ['src/**/*.{test,spec}.{ts,js}'],
  },
});
