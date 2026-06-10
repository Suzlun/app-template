## 1. OpenSpec 境界の修正確認

- [x] 1.1 `openspec/specs/auth-fe/spec.md` を読み、削除対象の Product Svelte app FE requirements と Scenario ID を確認する。
- [x] 1.2 `openspec/specs/localization-fe/spec.md` を読み、削除する Product app locale requirement と残す公開Web/Admin/i18n requirementを確認する。
- [x] 1.3 `openspec/specs/api-contract-be/spec.md` を読み、Product TS SDK を外す生成・drift check 箇所を確認する。
- [x] 1.4 `openspec/specs/admin-console-fe/spec.md` と `openspec/specs/admin-auth-fe/spec.md` を読み、`packages/admin/*` から `packages/web/admin/*` へ修正する requirement を確認する。

## 2. Product FE spec と実装 package の削除

- [x] 2.1 `packages/frontend/app`、`packages/frontend/domain`、`packages/frontend/api` を削除し、空の `packages/frontend` を残さない。
- [x] 2.2 root scripts から `dev:app`、`build:app`、Product app/domain/api を含む `check`、`test`、`lint`、`gen:api-sdk` の Product TS SDK target を削除する。
- [x] 2.3 `playwright.config.ts` から Product app dev server、`5174`、`app.localhost` 前提を削除する。
- [x] 2.4 `[AUTH-FE-S001] Product frontend app package is not a workspace member` の自動検証を追加し、test title に Scenario ID を含める。
- [x] 2.5 `[AUTH-FE-S010] Product passkey management UI references are absent` の自動検証を追加し、削除対象UI参照が残らないことを確認する。

## 3. Web/Admin package tree への移動

- [x] 3.1 `packages/web` を一時path経由で `packages/web/lp` へ移動する。
- [x] 3.2 `packages/frontend/ui` を `packages/web/ui` へ、`packages/frontend/i18n` を `packages/web/i18n` へ移動する。
- [x] 3.3 `packages/admin/app`、`packages/admin/api`、`packages/admin/domain` を `packages/web/admin/app`、`packages/web/admin/api`、`packages/web/admin/domain` へ移動する。
- [x] 3.4 各 package の `package.json`、`tsconfig.json`、Svelte/Vite/Vitest/Orval config の相対pathとpackage名を更新する。
- [x] 3.5 `pnpm-workspace.yaml` を supported packages のみに更新し、supply-chain hardening 設定を維持する。
- [x] 3.6 `tsconfig.base.json` の aliases を `@app-template/web-*` に更新し、Product frontend aliases を削除する。

## 4. localization-fe / Admin FE 境界の実装

- [x] 4.1 `scripts/i18n/check-locales.ts` と ESLint locale globs を `packages/web/lp`、`packages/web/admin/app`、`packages/web/i18n` に更新する。
- [x] 4.2 `eslint.config.js` の Admin app/domain/api boundary を `packages/web/admin/*` と `@app-template/web-*` scope に更新する。
- [x] 4.3 `eslint.config.js` の shared UI i18n禁止境界を `packages/web/ui` と `@app-template/web-i18n` に更新する。
- [x] 4.4 `[LOCALIZATION-FE-S010] Locale coverage scans LP and Admin only` の自動検証を追加する。
- [x] 4.5 `[LOCALIZATION-FE-S011] Shared UI cannot import web i18n runtime` の自動検証を追加する。
- [x] 4.6 `[LOCALIZATION-FE-S013] Localized concrete components stay in surfaces` の自動検証を追加する。
- [x] 4.7 `[ADMIN-CONSOLE-FE-S038] Admin app cannot import generated API client directly` の自動検証を追加する。
- [x] 4.8 `[ADMIN-CONSOLE-FE-S039] Admin package rejects server-only modules` の自動検証を追加する。
- [x] 4.9 `[ADMIN-CONSOLE-FE-S040] Admin domain uses Admin api layer` の自動検証を追加する。
- [x] 4.10 `[ADMIN-AUTH-FE-S027] Login UI calls Admin backend through Admin api layer` の自動検証を移動後pathで更新する。
- [x] 4.11 `[ADMIN-AUTH-FE-S028] Product auth SDK is not used for operator session` の自動検証を更新する。
- [x] 4.12 `[ADMIN-AUTH-FE-S033] Operator login keeps refreshToken out of browser-readable state` の自動検証を移動後pathで維持する。
- [x] 4.13 `[ADMIN-AUTH-FE-S012]` から `[ADMIN-AUTH-FE-S016]` の Admin passkey management tests を移動後pathで維持する。

## 5. API contract / codegen の更新

- [x] 5.1 `package.json` の `gen` scripts を Product OpenAPI、Admin OpenAPI、Admin TS SDK、Product/Admin Go bindings に整理する。
- [x] 5.2 Product TS SDK 用 package、Orval config、prettier target、drift check target を削除する。
- [x] 5.3 `packages/web/admin/api/orval.config.ts` の OpenAPI input と generated output path を更新する。
- [x] 5.4 `scripts/codegen/check.sh` を retained artifacts のみに更新する。
- [x] 5.5 `lint:api-admin-policy` を TypeSpec/OpenAPI/Admin SDK/Go bindings 対象へ更新する。
- [x] 5.6 `[API-CONTRACT-BE-S001] Product generation excludes Admin operations and Product TS SDK` の自動検証を追加する。
- [x] 5.7 `[API-CONTRACT-BE-S006] Drift check validates retained artifacts only` の自動検証を追加する。
- [x] 5.8 `[API-CONTRACT-BE-S009] Admin SDK stays inside web admin api boundary` の自動検証を追加する。

## 6. Nix/devenv と Compose runtime

- [ ] 6.1 `flake.nix`、`flake.lock`、`devenv.nix`、`devenv.yaml`、`devenv.lock` を追加し、標準 toolchain を Nix/devenv にする。
- [x] 6.2 `.gitignore` に `.cache/`、`.devenv/`、`.direnv/` を追加する。
- [x] 6.3 `.devcontainer/compose.yaml` を root `compose.yaml` へ移動し、`workspace` service を `runtime` にする。
- [x] 6.4 `.devcontainer/Dockerfile` を `docker/runtime/Dockerfile` へ移動または縮小する。
- [x] 6.5 `.devcontainer/**` と `scripts/devcontainer/run.sh` を削除する。
- [x] 6.6 Compose の mount path、DB identifiers、ports、SigNoz mount/profile を新方針へ更新する。
- [ ] 6.7 `nix flake check`、`nix develop --command node --version`、`nix develop --command pnpm --version`、`nix develop --command go version` を実行する。
- [x] 6.8 `docker compose config` を実行する。

## 7. Docs / CI / Editor / Agent 設定

- [x] 7.1 `README.md` を Flutter基盤、FE spec削除後のWeb/Admin/Backend/TypeSpec構成、Nix/devenv、Compose runtime に更新する。
- [x] 7.2 `AGENTS.md` の command policy と package responsibility を Nix/devenv と `packages/web/**` 構成へ更新する。
- [x] 7.3 `CONTRIBUTING.md` と `CODING_STANDARDS.md` を Product FE削除、Product TS SDK削除、Admin/Web package移動に合わせる。
- [x] 7.4 `.github/workflows/ci.yml` を Nix/devenv 経由の `pnpm` scripts に更新する。
- [x] 7.5 `.zed/tasks.json` と `.zed/settings.json` から Dev Container / Product app task 前提を削除する。
- [x] 7.6 `.opencode/**` の agent scope と review routing を `packages/web/**`、`packages/backend`、`packages/typespec` に更新する。
- [x] 7.7 `scripts/lint/no-legacy-paths.sh` を追加し、削除対象 identifiers の残存を検出する。

## 8. 最終検証

- [ ] 8.1 `nix develop --command pnpm install --frozen-lockfile` を実行し、必要な場合のみ hardening 設定を維持して lockfile を更新する。
- [ ] 8.2 `nix develop --command pnpm gen` を実行する。
- [ ] 8.3 `nix develop --command pnpm format:check` を実行する。
- [ ] 8.4 `nix develop --command pnpm lint` を実行する。
- [ ] 8.5 `nix develop --command pnpm check` を実行する。
- [ ] 8.6 `nix develop --command pnpm test:run` を実行する。
- [ ] 8.7 `nix develop --command pnpm test:e2e` を実行する。
- [ ] 8.8 `nix develop --command pnpm build` を実行する。
- [x] 8.9 `git grep` で Product FE削除対象、Dev Container、旧package scope/path が active surface に残っていないことを確認する。
- [x] 8.10 `openspec validate "prepare-flutter-app-template-foundation" --type change --strict --no-interactive` を実行できる環境で実行する。
