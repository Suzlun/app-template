# Contributing

## 前提

- Nix with flakes enabled
- devenv
- Node.js / pnpm / Go / OpenSpec は Nix/devenv shell で固定
- `compose.yaml` が local infra/runtime stack の唯一の定義
- host / `devenv shell` の開発起動は `.config/local.toml` と `.config/local.admin.toml` を使い、接続先は `pnpm infra:up` が公開する localhost port を向く
- optional な Docker Compose runtime は `pnpm runtime:up` で起動し、`compose.yaml` から `.config/compose.toml` と `.config/compose.admin.toml` を受け取る
- 本番向け設定の雛形は `.config/example.toml` と `.config/example.admin.toml`

Zed で作業する場合は repository root を通常の worktree として開き、初回に worktree を trust してください。Zed の terminal、task、LSP、formatter は Nix/devenv shell の toolchain を使います。

## 基本フロー

1. `./setup.sh`
2. `devenv shell -- pnpm infra:up`
3. `devenv shell -- pnpm migrate:up`
4. 実装
5. `devenv shell -- pnpm lint`
6. `devenv shell -- pnpm test:run` (`frontend + Go`)
7. `devenv shell -- pnpm build`

`setup.sh` は Nix、devenv、Docker / Docker Compose、`pnpm install --frozen-lockfile`、`pnpm gen` をまとめて確認します。導入内容だけ確認したい場合は `./setup.sh --dry-run` を使ってください。

手で進める場合の最小手順:

1. `devenv shell -- pnpm install --frozen-lockfile`
2. `devenv shell -- pnpm gen`
3. `devenv shell -- pnpm infra:up`
4. `devenv shell -- pnpm migrate:up`
5. 実装
6. `devenv shell -- pnpm lint`
7. `devenv shell -- pnpm test:run` (`frontend + Go`)
8. `devenv shell -- pnpm build`

## API 契約

- 正は `packages/typespec/main.tsp`
- `packages/web/lp/wrangler.toml` と `packages/web/admin/app` 配下の配備設定は API contract の canonical source ではない
- Product API と Admin API はどちらも `/api/v1/*` だけを許可し、origin / Go binary / TypeSpec service / OpenAPI artifact / SDK package / Go bindings で分離する
- `/api/admin/*` は Admin BFF 逃げ道として使わない
- 生成物は手編集しない
  - Product OpenAPI: `packages/typespec/openapi/openapi.json`
  - Admin OpenAPI: `packages/typespec/openapi/admin.openapi.json`
  - Admin SDK: `packages/web/admin/api/src/generated/client.ts`
  - Product Go bindings: `packages/backend/internal/generated/openapi/openapi.gen.go`
  - Admin Go bindings: `packages/backend/internal/generated/adminopenapi/openapi.gen.go`
- 契約変更後は必ず `pnpm gen` と `pnpm check:codegen`

## Go backend ルール

- Product public surface は `/api/v1/auth/*`（`/api/v1/auth/logout` を除く）および `/api/v1/status`
- runtime public surface baseline は `/api/v1/status`, `/api/v1/auth/passkey/start`, `/api/v1/auth/passkey/finish`, `/api/v1/auth/passkey/register/start`, `/api/v1/auth/passkey/register`, `/api/v1/auth/recovery`, `/api/v1/auth/recovery/consume`, `/api/v1/auth/passkey/add/start`, `/api/v1/auth/passkey/add/finish`
- app surface（bearer 必須）は `/api/v1/passkeys/*` および `/api/v1/auth/logout`
- app surface は `Authorization: Bearer <token>` 境界を必須にする
- Admin surface も Admin origin の `/api/v1/*` として提供し、Product origin / Product binary / Product OpenAPI / Product SDK / Product Go bindings へ混入させない
- `APP_ENV!=development` では `APP_BEARER_TOKEN` を必須にする
- OpenAPI は Spectral lint で path policy と bearer security declaration を検証する
- backend の依存方向は `cmd/api -> internal/app -> (internal/adapter/* | internal/application | internal/platform/*) -> internal/domain` を守る
- GORM は `packages/backend/internal/adapter/postgres/**` のみ
- `AutoMigrate` は禁止。`golang-migrate` 用 SQL を `packages/backend/db/migrations/**` に置く
- `internal/domain` / `internal/application` は Gin, GORM, generated, HTTP infra に依存しない
- `internal/adapter/http` は `internal/adapter/postgres` / `internal/adapter/valkey` などの永続化 adapter を直 import しない

## Hooks

- `pre-commit`: `pnpm lint-staged` のみ。codegen drift check は `pnpm lint` と CI の `pnpm check:codegen` で実行する
- staged `.go` は hook 内で `gofmt` + `goimports` を掛ける
- staged migration SQL は custom guardrail で filename / pair policy を検証する
- staged ESLint は inline suppression 無効・warning 失敗で実行する

## チェックコマンド

```bash
devenv shell -- pnpm gen
devenv shell -- pnpm check:codegen
devenv shell -- pnpm lint
devenv shell -- pnpm test:run
devenv shell -- pnpm build
```

## OpenSpec

- `openspec/**` は default lint / CI から外しています
- 仕様の正は TypeSpec とテストです
