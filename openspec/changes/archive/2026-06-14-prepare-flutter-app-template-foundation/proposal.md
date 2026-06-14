## Why

`app-template` は Flutter アプリ構築テンプレートの基盤として使う前提だが、現在の OpenSpec と repository には Product Svelte app 時代の frontend 仕様と実装境界が残っている。特に `auth-fe` は `/login`、`/logout`、`/session-expired`、Product app の passkey/session/device 管理を要求しており、今回削除する `packages/frontend/app` / `packages/frontend/domain` / `packages/frontend/api` と直接結び付いている。

この変更は Flutter アプリ本体を作る変更ではない。目的は、Product frontend app の FE 仕様と実装を削除し、残す Web LP、Web UI、Web i18n、Web Admin、Backend、TypeSpec の仕様境界へ OpenSpec を合わせることである。顧客にとっての成功は、後続の Flutter app 追加時に Svelte app 前提の仕様や生成物へ引き戻されず、Nix/devenv と Compose runtime を正とする基盤から安全に始められる状態である。

## What Changes

- **BREAKING**: `auth-fe` の Product Svelte app 向け frontend 認証・セッション・passkey・device 管理 requirements を削除する。
- **BREAKING**: `localization-fe` から認証済み Product アプリ向け locale requirement を削除する。
- **BREAKING**: Product TypeScript SDK package と `packages/frontend/api` を API contract/codegen の対象から外し、Product は OpenAPI と Go bindings、Admin は OpenAPI・Admin TS SDK・Go bindingsを残す。
- **BREAKING**: `packages/admin/*` と `packages/frontend/ui` / `packages/frontend/i18n` 前提のFE仕様境界を、`packages/web/admin/*`、`packages/web/ui`、`packages/web/i18n` に修正する。
- Dev Container と `scripts/devcontainer/run.sh` 前提を撤去し、Nix/devenv を標準 toolchain として docs/CI/Zed/AGENTS に統一する。
- Compose はローカルインフラと BE/Web runtime 用に残し、workspace service ではなく runtime service として扱う。
- Flutter app 本体、`packages/app`、root `pubspec.yaml`、Dart workspace、Flutter lint/test/build/CI は追加しない。

## Spec Units

### New Spec Units

- なし。今回の変更は既存 FE/contract 仕様の削除・修正であり、新しい恒久機能の追加ではない。

### Modified Spec Units

- `auth-fe`: Product Svelte app で提供していた frontend 認証・セッション・passkey・device 管理 requirements を削除する。Cross-cutting: security、migration。
- `localization-fe`: 認証済み Product アプリ locale requirement を削除し、公開 Web と Admin Console と shared i18n 境界を新 package tree へ修正する。Cross-cutting: i18n coverage、accessibility。
- `api-contract-be`: Product TypeScript SDK を生成・検証対象から外し、retained Product/Admin artifacts の surface separation を維持する。Cross-cutting: codegen、security。
- `admin-console-fe`: Admin Console の app/domain/api package 境界を `packages/web/admin/*` と `@app-template/web-*` scope に修正する。Cross-cutting: authorization boundary、lint。
- `admin-auth-fe`: Admin auth/passkey UI が参照する Admin domain/API package 境界を `packages/web/admin/*` に修正する。Cross-cutting: session security、lint。

## Naming

Scenario ID は既存 Spec Unit の prefix を維持する。削除対象は `AUTH-FE-*`、locale修正は `LOCALIZATION-FE-*`、contract修正は `API-CONTRACT-BE-*`、Admin FE修正は `ADMIN-CONSOLE-FE-*` と `ADMIN-AUTH-FE-*` を使う。

## Impact

- Deleted FE spec scope: `auth-fe` の Product frontend app requirements。
- Modified FE spec scope: `localization-fe`、`admin-console-fe`、`admin-auth-fe`。
- Modified BE/contract spec scope: `api-contract-be`。
- Packages: `packages/frontend/app`、`packages/frontend/domain`、`packages/frontend/api`、`packages/frontend/ui`、`packages/frontend/i18n`、`packages/admin/*`、`packages/web/**`、`packages/typespec`、`packages/backend`。
- Tooling: `package.json`、`pnpm-workspace.yaml`、`pnpm-lock.yaml`、`tsconfig.base.json`、`eslint.config.js`、`vitest.config.ts`、`playwright.config.ts`、`.github/workflows/ci.yml`、`.zed/**`。
- Runtime/ops: `.devcontainer/**`、`scripts/devcontainer/run.sh`、`compose.yaml`、`docker/runtime/Dockerfile`、`compose/signoz/**`、`.config/**`。
- Docs/agent rules: `README.md`、`AGENTS.md`、`CONTRIBUTING.md`、`CODING_STANDARDS.md`、`.opencode/**`、`openspec/**`。
- API/DB: DB schema migration is not expected. API paths remain `/api/v1/*`; Product/Admin Go bindings remain separated.
