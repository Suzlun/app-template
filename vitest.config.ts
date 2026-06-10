import { defineConfig } from 'vitest/config';

/**
 * Vitest monorepo projects.
 *
 * Run all tests: `pnpm test:run`
 * Run a single project: `vitest run --project web-lp`
 */
export default defineConfig({
  test: {
    projects: [
      {
        extends: './packages/web/lp/vitest.config.ts',
        root: './packages/web/lp',
        test: {
          name: 'web-lp',
        },
      },
      {
        extends: './packages/web/ui/vitest.config.ts',
        root: './packages/web/ui',
        test: {
          name: 'web-ui',
        },
      },
      {
        extends: './packages/web/admin/app/vitest.config.ts',
        root: './packages/web/admin/app',
        test: {
          name: 'web-admin',
        },
      },
      {
        root: './',
        test: {
          name: 'root',
          include: ['tests/**/*.test.ts'],
          environment: 'node',
          globals: true,
        },
      },
    ],
  },
});
