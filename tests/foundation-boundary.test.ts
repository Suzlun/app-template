import { existsSync, readFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import { describe, expect, it } from 'vitest';

const repoRoot = fileURLToPath(new URL('..', import.meta.url));
const removedFrontendRoot = ['packages', 'frontend'].join('/');
const removedProductAppAlias = ['@app-template', 'app'].join('/');
const removedProductApiAlias = ['@app-template', 'api'].join('/');
const removedAdminApiAlias = ['@app-template', 'admin-api'].join('/');
const removedProductApiPackage = ['packages', 'frontend', 'api'].join('/');
const removedAppDevScript = ['dev', 'app'].join(':');
const removedAppOrigin = ['app.localhost', '5174'].join(':');

const readText = (relativePath: string): string =>
  readFileSync(path.join(repoRoot, relativePath), 'utf8');

describe('Flutter app template foundation boundaries', () => {
  it('[AUTH-FE-S001] Product frontend app package is not a workspace member', () => {
    const workspace = readText('pnpm-workspace.yaml');
    const rootManifest = readText('package.json');
    const tsconfig = readText('tsconfig.base.json');

    expect(existsSync(path.join(repoRoot, 'packages/frontend'))).toBe(false);
    expect(workspace).not.toContain(removedFrontendRoot);
    expect(rootManifest).not.toContain(removedAppDevScript);
    expect(rootManifest).not.toContain(removedProductAppAlias);
    expect(tsconfig).not.toContain(removedFrontendRoot);
  });

  it('[AUTH-FE-S010] Product passkey management UI references are absent', () => {
    const activeFiles = [
      'package.json',
      'pnpm-workspace.yaml',
      'tsconfig.base.json',
      'playwright.config.ts',
      'vitest.config.ts',
    ];

    for (const filePath of activeFiles) {
      const content = readText(filePath);
      expect(content).not.toContain('passkey-management');
      expect(content).not.toContain('device-management');
      expect(content).not.toContain(removedAppOrigin);
    }
  });

  it('[API-CONTRACT-BE-S001] Product generation excludes Admin operations and Product TS SDK', () => {
    const rootManifest = readText('package.json');
    const codegenCheck = readText('scripts/codegen/check.sh');

    expect(rootManifest).not.toContain(removedProductApiAlias);
    expect(rootManifest).not.toContain(removedProductApiPackage);
    expect(codegenCheck).not.toContain(removedProductApiPackage);
    expect(codegenCheck).toContain('Admin operation or tag in Product OpenAPI');
    expect(codegenCheck).toContain('Admin export in Product Go bindings');
    expect(rootManifest).toContain('@app-template/web-admin-api');
    expect(codegenCheck).toContain('packages/web/admin/api/src/generated/client.ts');
  });

  it('[API-CONTRACT-BE-S006] Drift check validates retained artifacts only', () => {
    const codegenCheck = readText('scripts/codegen/check.sh');

    expect(codegenCheck).toContain('packages/typespec/openapi/openapi.json');
    expect(codegenCheck).toContain('packages/typespec/openapi/admin.openapi.json');
    expect(codegenCheck).toContain('packages/web/admin/api/src/generated/client.ts');
    expect(codegenCheck).toContain('packages/backend/internal/generated/openapi/openapi.gen.go');
    expect(codegenCheck).toContain(
      'packages/backend/internal/generated/adminopenapi/openapi.gen.go'
    );
    expect(codegenCheck).not.toContain(removedProductApiPackage);
  });

  it('[API-CONTRACT-BE-S009] Admin SDK stays inside web admin api boundary', () => {
    const tsconfig = readText('tsconfig.base.json');
    const adminDomainManifest = readText('packages/web/admin/domain/package.json');

    expect(tsconfig).toContain('@app-template/web-admin-api');
    expect(adminDomainManifest).toContain('@app-template/web-admin-api');
    expect(tsconfig).not.toContain(removedAdminApiAlias);
  });
});
