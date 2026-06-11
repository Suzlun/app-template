# app-template

TypeSpec を API 契約の正とし、Svelte の Web surface と Go バックエンドを同じリポジトリで運用する、Flutter アプリ追加前の基盤テンプレートです。

- API 契約は `packages/typespec/main.tsp` が唯一の正です
- OpenAPI・Admin SDK・Go バインディングは契約から生成します（手編集禁止）
- `web/lp` は公開面 LP であり Admin `domain` / `api` に依存しません（`web/ui` と `web/i18n` のみ利用可）
- `web/admin/app` は `admin-app -> admin-domain -> admin-api` の依存方向を守ります（`admin-app` は `web/ui` と `web/i18n` にも依存）
- バックエンドは `cmd/api -> internal/app -> (adapter/*|application|platform) -> domain` の依存方向を守ります

## 目次

- [技術スタック](#技術スタック)
- [リポジトリ構成](#リポジトリ構成)
- [アーキテクチャ](#アーキテクチャ)
- [ローカル開発環境セットアップ](#ローカル開発環境セットアップ)
- [コマンド一覧](#コマンド一覧)
- [標準の検証順（CI と同じ）](#標準の検証順ci-と同じ)
- [API 契約と生成物](#api-契約と生成物)
- [現在の API surface](#現在の-api-surface)
- [Auth surface と認証仕様](#auth-surface-と認証仕様)
- [設定ファイルリファレンス](#設定ファイルリファレンス)
- [データベースマイグレーション](#データベースマイグレーション)
- [CI/CD](#cicd)
- [Git hooks とコミット規約](#git-hooks-とコミット規約)
- [Guardrails と静的解析](#guardrails-と静的解析)
- [関連ドキュメント](#関連ドキュメント)

---

## 技術スタック

| 分類               | 内容                                                         |
| ------------------ | ------------------------------------------------------------ |
| フロントエンド     | SvelteKit 2, Svelte 5, TypeScript, Vite                      |
| テスト（フロント） | Vitest, Playwright                                           |
| API 契約           | TypeSpec 1.8, OpenAPI 3, Spectral, Orval                     |
| コード生成         | Orval（Admin SDK）, oapi-codegen 2.4（Go bindings）          |
| バックエンド       | Go 1.26.4, Gin 1.11, GORM 1.31, golang-migrate 4.18          |
| DB / KVS / Search  | PostgreSQL 18, Valkey 9 (Redis 互換), OpenSearch 3           |
| Object Storage     | Cloudflare R2 / MinIO（S3 互換）                             |
| メール             | SMTP（開発時は Mailpit）                                     |
| ツール             | Nix/devenv, OpenSpec, pnpm 11.5.1, ESLint 9, Prettier, Husky |
| CI                 | GitHub Actions                                               |
| 開発環境           | Nix/devenv + Docker Compose infra/runtime                    |

---

## リポジトリ構成

```text
.
├── .zed/                        # Zed プロジェクト設定（LSP / formatter / task）
├── .github/workflows/ci.yml     # CI パイプライン
├── .husky/                      # Git hooks（pre-commit, commit-msg）
├── compose.yaml                  # Docker Compose infra/runtime
├── compose/signoz/               # SigNoz Compose 設定
├── docker/runtime/Dockerfile     # Compose runtime image
├── devenv.nix                    # Nix/devenv toolchain definition
├── flake.nix                     # Nix flake entrypoint
├── setup.sh                      # Nix / devenv / Docker / repo bootstrap
├── scripts/                     # CI / lint / codegen / migration ヘルパースクリプト
│   ├── codegen/check.sh         # codegen drift check
│   ├── go/                      # Go build / lint / format / test / migrate
│   ├── hooks/                   # pre-commit 内で呼ばれるフックスクリプト
│   └── security/                # govulncheck / gitleaks / osv-scanner
├── tests/                       # Playwright E2E テスト
├── packages/
│   ├── typespec/                # API 契約（唯一の正）
│   │   ├── main.tsp             # エントリポイント
│   │   ├── src/
│   │   │   ├── common/          # 共通エラー定義
│   │   │   ├── models/          # データモデル
│   │   │   └── routes/v1/       # API ルート定義
│   │   ├── openapi/openapi.json # 生成 OpenAPI（手編集禁止）
│   │   └── .spectral.yaml       # Spectral lint ルールセット
│   ├── web/
│   │   ├── lp/                  # SvelteKit 公開面 LP（Admin domain / api 非依存）
│   │   ├── ui/                  # 共有 UI コンポーネント（atoms / molecules / organisms）
│   │   ├── i18n/                # 共有 frontend i18n runtime
│   │   └── admin/
│   │       ├── app/             # Admin Console static SPA
│   │       ├── domain/          # Admin domain hook / state orchestration
│   │       └── api/             # Admin SDK + API wrapper（generated は手編集禁止）
│   └── backend/
│       ├── cmd/api/             # Go API エントリポイント
│       ├── db/migrations/       # golang-migrate SQL ファイル（*.up.sql / *.down.sql）
│       ├── internal/
│       │   ├── app/             # ランタイムコンテナ・依存注入（Composition Root）
│       │   ├── domain/          # ドメインモデル・値オブジェクト（Account/Auth を flat package で表現）
│       │   ├── application/     # アプリケーションサービス（ユースケース・ポート）
│       │   ├── adapter/
│       │   │   ├── http/        # Gin ルーター・ハンドラアダプタ
│       │   │   ├── postgres/    # GORM リポジトリ実装
│       │   │   ├── valkey/      # Valkey 状態リポジトリ実装
│       │   │   ├── webauthn/    # WebAuthn プロバイダ実装
│       │   │   └── mailer/      # SMTP メール送信実装
│       │   ├── platform/
│       │   │   ├── config/      # 設定・共有型
│       │   │   ├── id/          # ID ポリシー・ULID 生成
│       │   │   ├── observability/ # ロガー・メトリクス・トレーサー
│       │   │   └── health/      # インフラ健全性チェック
│       │   └── generated/openapi/openapi.gen.go  # 生成 Go バインディング（手編集禁止）
│       └── tools/analyzers/     # カスタム静的解析ツール（guardrails）
└── openspec/                    # OpenSpec 仕様（現在は lint / CI 対象外）
```

---

## アーキテクチャ

### Web 依存方向

```
packages/web/lp  ───────────────►  packages/web/ui
        │                          （公開面 LP は Admin api / domain に依存しない）
        └───────────────────────►  packages/web/i18n

packages/web/admin/app  ──►  packages/web/admin/domain  ──►  packages/web/admin/api
         │                          │                                      └── 生成 Admin SDK
         ├───────────────────────►  packages/web/ui
         └───────────────────────►  packages/web/i18n

```

- `web/lp` は `@app-template/web-ui` と `@app-template/web-i18n` のみ利用可。Admin domain / API の import は ESLint で禁止。
- `web/admin/app` はページ・コンポーネントで直接 API を呼ばず、`web/admin/domain` の `use*` フックを経由します。
- Admin `domain` フックは `{ data, actions }` を返す `use*` export に統一します（stateful 実装は `.svelte.ts` に配置）。
- Admin ページ・コンポーネントは副作用（`onMount`, `$effect` による I/O）を書かず、フックの `actions` を呼ぶだけにします。

### バックエンド依存方向

```
cmd/api
  └── internal/app              （DI コンテナ・ランタイム）
        ├── internal/adapter/http        （Gin + 生成アダプタ）
        │     └── internal/application
        ├── internal/adapter/postgres    （GORM リポジトリ実装）
        │     └── internal/domain
        ├── internal/adapter/valkey      （Valkey 状態リポジトリ実装）
        │     └── internal/domain
        ├── internal/adapter/webauthn    （WebAuthn プロバイダ）
        │     └── internal/domain
        ├── internal/adapter/mailer      （SMTP メール送信）
        │     └── internal/application
        ├── internal/application         （ユースケース・ポート）
        │     └── internal/domain
        ├── internal/domain              （ドメインモデル・値オブジェクト）
        └── internal/platform/*           （クロスカッティング基盤）
```

**禁止事項（守護ルール）**

| レイヤー                 | 禁止                                                                    |
| ------------------------ | ----------------------------------------------------------------------- |
| `domain` / `application` | Gin, GORM, generated, HTTP infra の import                              |
| `adapter/http`           | `domain.<Entity>` / `domain.Err\*` の直接使用（application DTO を経由） |
| `adapter/postgres` 以外  | GORM / Postgres driver の import                                        |
| `domain` / `application` | `time.Now`, `os.Getenv`, `log`, `math/rand` の直接使用                  |

### API 契約フロー

```
packages/typespec/main.tsp
        │  pnpm gen
        ├──► packages/typespec/openapi/openapi.json
        │           │  oapi-codegen
        │           └──► packages/backend/internal/generated/openapi/openapi.gen.go
        ├──► packages/typespec/openapi/admin.openapi.json
        │           │  Orval
        │           ├──► packages/web/admin/api/src/generated/client.ts
        │           │  oapi-codegen
        │           └──► packages/backend/internal/generated/adminopenapi/openapi.gen.go
        │
        └── pnpm check:codegen（drift があれば CI 失敗）
```

---

## ローカル開発環境セットアップ

### オプション A: Nix/devenv（推奨）

Zed で repository root を開き、初回に `.zed/settings.json` の LSP / formatter / extension 設定を有効化するため worktree を trust します。

terminal、task、language server は Nix/devenv shell の toolchain を使います。infra は Docker Compose で起動します。

最初の 1 回は root の `setup.sh` を実行してください。script が `Nix -> devenv -> Docker / Docker Compose -> pnpm install -> pnpm gen` の順で確認し、不足していれば導入します。

```bash
./setup.sh
```

導入内容だけ確認したい場合は `./setup.sh --dry-run`、対話確認を省いて一気に進めたい場合は `./setup.sh --yes` を使います。

`compose.yaml` がローカル infra/runtime の唯一の定義です。setup 後はまず `devenv shell -- pnpm infra:up` を実行し、Compose stack 全体を起動してください。これにより PostgreSQL / Valkey / OpenSearch / MinIO / Mailpit / SigNoz と runtime container がそろい、`.config/local*.toml` が参照する localhost ポートも同時に公開されます。

| サービス                 | host / `devenv shell` からの接続先                              | Compose runtime からの接続先       |
| ------------------------ | --------------------------------------------------------------- | ---------------------------------- |
| PostgreSQL 18            | `localhost:5432`                                                | `postgres:5432`                    |
| Valkey 9（Redis 互換）   | `localhost:6379`                                                | `valkey:6379`                      |
| OpenSearch 3             | `http://localhost:9200`                                         | `http://opensearch:9200`           |
| MinIO（S3 互換）         | API: `http://localhost:9000` / Console: `http://localhost:9001` | API: `http://minio:9000`           |
| Mailpit（SMTP + Web UI） | SMTP: `localhost:1025` / UI: `http://localhost:8025`            | SMTP: `mailpit:1025`               |
| SigNoz UI                | `http://localhost:3301`                                         | `http://signoz:8080`               |
| SigNoz OTLP              | gRPC: `localhost:4317` / HTTP: `localhost:4318`                 | gRPC: `signoz-otel-collector:4317` |

host / `devenv shell` で起動する Product/Admin backend は `.config/local.toml` と `.config/local.admin.toml` を使い、その接続先は `pnpm infra:up` が起動する `compose.yaml` の公開ポートに向きます。`docker compose exec runtime ...` で動かす runtime container には `compose.yaml` から `.config/compose.toml` と `.config/compose.admin.toml` を渡します。`setup.sh` は Docker daemon と Compose 構文だけを確認し、長時間生きる stack の起動までは行いません。

Zed の project task から `pnpm dev:*`、`pnpm lint`、`pnpm check`、`pnpm test:run`、`pnpm build` を実行できます。すべて Nix/devenv shell の `pnpm` と toolchain を使います。

Codex Desktop や host 側 terminal から検証する場合は、host の Node.js / Go / bash 差分を避けるため Nix/devenv shell 経由で実行します。

```bash
devenv shell -- pnpm check
devenv shell -- pnpm lint
devenv shell -- pnpm test:run
devenv shell -- pnpm build
```

`setup.sh` を使わず手で進める場合は、`devenv shell -- pnpm install` と `devenv shell -- pnpm gen` で依存と生成物をそろえます。OpenSpec CLI も Nix/devenv shell から利用します。

### オプション B: ローカルセットアップ（手動）

**前提ツール**

- Node.js 24.12+
- pnpm 11.5.1（`corepack enable` で有効化）
- Go 1.26.4+
- Docker / Docker Compose

**手順**

```bash
# 1. 依存インストール
corepack enable
pnpm install

# 2. 生成物をそろえる（TypeSpec -> OpenAPI -> Admin SDK -> Go bindings）
pnpm gen

# 3. host / devenv shell 用の tracked local config を確認
# Product API: .config/local.toml
# Admin API:   .config/local.admin.toml

# 4. compose.yaml で local infra/runtime stack を起動
pnpm infra:up

# 5. DB マイグレーションを実行
pnpm migrate:up

# 6. 全サービスを起動
pnpm dev:all
```

起動後のアクセス先:

| サービス               | URL                           |
| ---------------------- | ----------------------------- |
| Product Go API         | `http://localhost:8080`       |
| Admin Go API           | `http://localhost:8081`       |
| 公開面 LP（web）       | `http://www.localhost:5173`   |
| Admin Console（admin） | `http://admin.localhost:5176` |

---

## コマンド一覧

### 開発

```bash
pnpm dev:all          # Product/Admin Go API + web + admin を並列起動
pnpm dev:server       # Product Go API のみ（http://localhost:8080）
pnpm dev:admin-server # Admin Go API のみ（http://localhost:8081）
pnpm dev:web          # 公開面 LP のみ（http://www.localhost:5173）
pnpm dev:admin        # Admin Console のみ（http://admin.localhost:5176）
pnpm dev:client       # dev:web のエイリアス
```

### Compose

```bash
pnpm infra:up         # compose.yaml で定義された local infra/runtime stack を起動
pnpm infra:down       # compose.yaml の stack を停止
pnpm infra:ps         # compose.yaml の service 状態を確認
```

### コード生成

```bash
pnpm gen              # TypeSpec -> OpenAPI -> Admin SDK -> Go bindings（フル生成）
pnpm gen:openapi      # TypeSpec -> OpenAPI のみ
pnpm gen:api-sdk      # TypeSpec -> OpenAPI -> Admin SDK
pnpm gen:backend      # OpenAPI -> Go bindings のみ
pnpm check:codegen    # 生成物に未コミットの差分があれば失敗（CI 確認用）
```

### 検証

```bash
pnpm format:check     # Prettier + tsp format + gofmt/goimports のフォーマット確認
pnpm lint             # Spectral + ESLint + golangci-lint + custom guardrails + security + codegen drift
pnpm check            # TypeSpec compile + frontend 型チェック + Go build
pnpm test:run         # web + admin + ui + Go ユニットテスト（全て）
pnpm test:server      # Go ユニットテストのみ
pnpm test:client      # web + admin フロントテストのみ
pnpm test:e2e         # Playwright E2E テスト
pnpm build            # Go backend + frontend をビルド
```

### フォーマット

```bash
pnpm format           # 全ファイルをフォーマット（Prettier + tsp format + gofmt/goimports）
pnpm format:check     # フォーマット確認のみ（変更なし）
```

### DB マイグレーション

```bash
pnpm migrate:create <name>      # 新規マイグレーションファイルを作成（up + down のペア）
pnpm migrate:up                 # 未適用の全マイグレーションを適用
pnpm migrate:down               # 直近 1 つのマイグレーションをロールバック
```

---

## 標準の検証順（CI と同じ）

CI は以下の順番で実行します。ローカルで問題が疑われる場合はこの順番で確認してください。

```bash
pnpm format:check     # 1. フォーマット確認
pnpm gen              # 2. 生成物を最新化
pnpm lint             # 3. 全 lint（Spectral / ESLint / Go lint / security / codegen drift）
pnpm check            # 4. 型チェック + Go build
pnpm test:run         # 5. 全ユニットテスト
pnpm check:codegen    # 6. 生成物 drift 確認（pnpm gen 後の差分ゼロ確認）
pnpm build            # 7. 本番ビルド
```

---

## API 契約と生成物

### ファイル対応

| 役割                     | パス                                                              |
| ------------------------ | ----------------------------------------------------------------- |
| 契約（唯一の正）         | `packages/typespec/main.tsp`                                      |
| 生成 Product OpenAPI     | `packages/typespec/openapi/openapi.json`                          |
| 生成 Admin OpenAPI       | `packages/typespec/openapi/admin.openapi.json`                    |
| 生成 Admin SDK           | `packages/web/admin/api/src/generated/client.ts`                  |
| 生成 Product Go bindings | `packages/backend/internal/generated/openapi/openapi.gen.go`      |
| 生成 Admin Go bindings   | `packages/backend/internal/generated/adminopenapi/openapi.gen.go` |

**生成物は手編集禁止です。** 契約を変更したら `pnpm gen` を実行し、生成物をまとめてコミットしてください。`pnpm check:codegen` は生成物に差分が残っていると失敗します。

### API 変更の手順

1. `packages/typespec/main.tsp`（または `src/` 配下の `.tsp`）を編集
2. `pnpm gen` を実行して生成物を更新
3. `pnpm lint` と `pnpm check` を通す
4. 生成物とソースをまとめてコミット

### Product/Admin デプロイルーティング

- Product domain と Admin domain は一致させません。どちらも同じ `/api/v1/*` path 空間を使いますが、別 domain / 別 Go binary / 別 TypeSpec service / 別 OpenAPI / 別 SDK / 別 Go bindings で分離します。
- Product domain では、Cloudflare route が `/api/v1/*` を Product GoServer（`packages/backend/cmd/api`）へ送り、それ以外の公開面は `packages/web/lp` 側で配信します。
- Admin domain では、Cloudflare route が `/api/v1/*` を Admin GoServer（`packages/backend/cmd/admin-api`）へ送り、それ以外の path は Admin static frontend を配信します。Admin frontend からの API 呼び出しは同一 Admin domain の `/api/v1/*` だけを使い、Product domain や `/api/admin/*` BFF route は使いません。
- `packages/web/lp/wrangler.toml` と `packages/web/admin/app` 配下の配備設定は API contract の canonical source ではありません。API の正は常に `packages/typespec/main.tsp` です。

### Spectral lint ルール

OpenAPI に対して以下の Spectral ルールが適用されます（`pnpm lint` / CI に含まれます）。

| ルール        | 内容                                                                           |
| ------------- | ------------------------------------------------------------------------------ |
| path-policy   | OpenAPI path は `/api/v1/*` のみ許可                                           |
| app-security  | `/api/v1/auth/*` と `/api/v1/status` 以外の operation は `BearerAuth` 宣言必須 |
| bearer-scheme | `BearerAuth` は `type=http` + `scheme=bearer` に限定                           |

---

## 現在の API surface

### public（Bearer 不要）

| メソッド | パス                                  | 説明                           |
| -------- | ------------------------------------- | ------------------------------ |
| `GET`    | `/api/v1/status`                      | ヘルスチェック                 |
| `POST`   | `/api/v1/auth/passkey/start`          | パスキー認証開始               |
| `POST`   | `/api/v1/auth/passkey/finish`         | パスキー認証完了               |
| `POST`   | `/api/v1/auth/passkey/register/start` | パスキー登録開始               |
| `POST`   | `/api/v1/auth/passkey/register`       | パスキー登録完了               |
| `POST`   | `/api/v1/auth/recovery`               | アカウントリカバリー開始       |
| `POST`   | `/api/v1/auth/recovery/consume`       | リカバリートークン消費         |
| `POST`   | `/api/v1/auth/passkey/add/start`      | パスキー追加開始（OTP フロー） |
| `POST`   | `/api/v1/auth/passkey/add/finish`     | パスキー追加完了（OTP フロー） |

### Bearer 必須

| メソッド | パス                      | 説明                               |
| -------- | ------------------------- | ---------------------------------- |
| `POST`   | `/api/v1/auth/logout`     | ログアウト                         |
| `GET`    | `/api/v1/passkeys`        | パスキー一覧取得                   |
| `POST`   | `/api/v1/passkeys/start`  | パスキー追加開始（認証済みフロー） |
| `POST`   | `/api/v1/passkeys/finish` | パスキー追加完了（認証済みフロー） |
| `POST`   | `/api/v1/passkeys/otp`    | OTP 発行                           |
| `DELETE` | `/api/v1/passkeys/{id}`   | パスキー削除                       |

### OpenAPI 契約外（router.go 直書き）

| メソッド | パス      | 説明                           |
| -------- | --------- | ------------------------------ |
| `GET`    | `/health` | インフラレベルのヘルスチェック |

---

## Auth surface と認証仕様

### フロントエンドルート

| パス                       | 説明                                            |
| -------------------------- | ----------------------------------------------- |
| `/login`                   | パスキー専用の認証面                            |
| `/login/recovery`          | 既存アカウント向けリカバリー導線                |
| `/login/recovery/sent`     | リカバリーメール送信完了                        |
| `/login/recovery/consume`  | リカバリートークン消費                          |
| `/login/recovery/register` | リカバリー後のパスキー再登録                    |
| `/logout`                  | ログアウト（実行は `POST /api/v1/auth/logout`） |

auth routes (`/login*`, `/logout`) と auth endpoints は `Cache-Control: no-store` 前提で扱います。

### Bearer セッション契約

- ログイン / リカバリー登録成功後、クライアントは `Authorization: Bearer <session token>` を `/api/v1/passkeys/*` 等に付与します
- bearer token はフロントエンドの **in-memory state にのみ保持**し、`localStorage` / `sessionStorage` 等の永続ストレージには書き込みません
- セッション不在 → 通常の `/login` 導線へ戻す
- セッション期限切れ / 失効 → `/session-expired` へ分岐

### システム所有 ID ポリシー

以下の ID は canonical ULID string を使用します。

`accountId`, `sessionId`, `passkeyCredentialId`, `recoveryTokenId`, `recoverySessionId`, `requestId`

例外（ULID 対象外）: opaque bearer token, recovery link token, rate-limit bucket key, WebAuthn RP ID

### Auth のレート制限・TTL デフォルト値

| 設定                                   | 値                                                       |
| -------------------------------------- | -------------------------------------------------------- |
| challenge TTL                          | 5 分                                                     |
| recovery token TTL                     | 30 分                                                    |
| recovery session TTL                   | 15 分                                                    |
| session idle TTL                       | 12 時間                                                  |
| session absolute TTL                   | 14 日                                                    |
| passkey start throttle                 | 5 req / 5 分                                             |
| recovery throttle                      | 3 req / 時（メールアドレスごと）, 10 req / 時（IP ごと） |
| finish / consume / register 失敗ロック | 10 失敗 / 15 分 → 15 分ロック                            |

---

## 設定ファイルリファレンス

backend は個別の `.env` ではなく TOML 設定ファイルを読みます。

- host / `devenv shell` の既定（`pnpm infra:up` が公開する port に接続）:
  - Product API: `.config/local.toml`
  - Admin API: `.config/local.admin.toml`
- Docker Compose runtime の既定:
  - Product API: `.config/compose.toml`
  - Admin API: `.config/compose.admin.toml`
- 上書き方法:
  - Product API: `CONFIG_PATH`
  - Admin API: `ADMIN_CONFIG_PATH`
- 雛形:
  - Product API: `.config/example.toml`
  - Admin API: `.config/example.admin.toml`

### compose-backed host local development 既定値

| ファイル                   | 主要な接続先 / origin                                                                                                                                                                                   |
| -------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `.config/local.toml`       | PostgreSQL `localhost:5432`, Valkey `localhost:6379`, OpenSearch `http://localhost:9200`, MinIO `http://localhost:9000`, Mailpit SMTP `localhost:1025`, OTLP `localhost:4317`                           |
| `.config/local.admin.toml` | Admin origin `http://admin.localhost:5176`, Product origin `http://www.localhost:5173`, PostgreSQL `localhost:5432`, Valkey `localhost:6379`, OpenSearch `http://localhost:9200`, OTLP `localhost:4317` |

### 重要な既定値

| TOML key                         | 既定値                                             | 説明                                         |
| -------------------------------- | -------------------------------------------------- | -------------------------------------------- |
| `app.environment`                | `development`                                      | 実行環境（`development` 以外では厳格モード） |
| `app.bearer_token`               | `dev-app-auth`                                     | Product app API 用 Bearer token              |
| `server.port`                    | Product `8080`, Admin `8081`                       | backend listen port                          |
| `server.allowed_origins`         | `http://www.localhost:5173`                        | Product API の CORS 許可 origin              |
| `auth.webauthn_rp_id`            | `www.localhost`                                    | Product WebAuthn RP ID                       |
| `auth.account_recovery_url_base` | `http://www.localhost:5173/login/recovery/consume` | recovery link base URL                       |
| `smtp.port`                      | `1025`                                             | Mailpit SMTP port                            |
| `object_storage.use_path_style`  | `true`                                             | MinIO の path-style endpoint を使う          |

### 重要な起動条件

- Product backend は起動時に PostgreSQL / Valkey / OpenSearch / object storage の疎通確認を行います。接続失敗時は起動しません
- Admin backend は起動時に PostgreSQL / OpenSearch の疎通確認を行います。接続失敗時は起動しません
- `development` 以外では Product `app.bearer_token` を空にできません

---

## データベースマイグレーション

マイグレーションは `packages/backend/db/migrations/` に配置します。`AutoMigrate` は禁止です。

### 命名規則

```
000001_description_here.up.sql
000001_description_here.down.sql
```

- 6 桁の連番 + アンダースコア + lowercase 英数字
- `up` / `down` のペアが必須
- ネストディレクトリ禁止

### 操作コマンド

```bash
# 新規マイグレーションファイルを作成（up + down のペア自動生成）
pnpm migrate:create add_auth_tables

# 未適用のマイグレーションを全て適用
pnpm migrate:up

# 直近 1 つのマイグレーションをロールバック
pnpm migrate:down
```

GORM の import は `packages/backend/internal/adapter/postgres/**` のみに許可されています。

---

## CI/CD

GitHub Actions の `ci.yml` が以下の順番で実行されます（`main` / `develop` への push と PR が対象）。

```
Checkout
└── Setup pnpm 11.5.1
└── Setup Node 24
└── Setup Go 1.26.4
└── pnpm install --frozen-lockfile
└── pnpm format:check          # フォーマット確認
└── pnpm gen                   # 生成物の最新化
└── pnpm lint                  # 全 lint
└── pnpm check                 # 型チェック + Go build
└── pnpm test:run              # ユニットテスト
└── pnpm check:codegen         # codegen drift 確認
└── pnpm build                 # ビルド
```

タイムアウト: 15 分。`pnpm install` は `--frozen-lockfile` で実行するため、`pnpm-lock.yaml` を常に最新にしてコミットしてください。

---

## Git hooks とコミット規約

### pre-commit（`pnpm lint-staged`）

staged ファイルに対して以下を自動適用します。

| 対象パターン                           | 処理内容                                                                |
| -------------------------------------- | ----------------------------------------------------------------------- |
| `*.{ts,tsx,js,jsx}`                    | `eslint --fix --no-inline-config --max-warnings 0` → `prettier --write` |
| `*.{json,md,yml,yaml}`                 | `prettier --write`                                                      |
| `*.go`                                 | `gofmt -w` + `goimports -local app-template -w`                         |
| `packages/backend/db/migrations/*.sql` | migration ファイル名 / ペアポリシーの検証                               |

codegen drift check は pre-commit には含まれず、`pnpm lint` と CI で実行されます。

### commit-msg

Conventional Commits 形式を強制します（`commitlint`）。

```
<type>: <subject>
```

使用可能な type: `feat` | `fix` | `docs` | `style` | `refactor` | `perf` | `test` | `build` | `ci` | `chore` | `revert`

**NG 例**: `update stuff`  
**OK 例**: `fix: prevent write application services from bypassing domain validation`

---

## Guardrails と静的解析

`pnpm lint` は以下の検証をすべて実行します。

### フロントエンド（ESLint）

- `eslint-plugin-boundaries`: パッケージ間依存方向の強制
- `no-restricted-imports`: Admin app からの `@app-template/web-admin-api` 直接 import 禁止など
- `frontend-svelte5/no-legacy-syntax`: Svelte 5 記法の強制（`on:click` 等の旧記法禁止）
- `sveltekit-app-policy`: サーバー面 route・サーバー import の禁止
- `hooks-domain/require-domain-structure`: `use*` + `{ data, actions }` 形式の強制
- `export-tsdoc/require-export-tsdoc`: export に TSDoc コメント必須
- `eslint-comments/no-use`: `eslint-disable` コメント全面禁止
- `max-lines` / `max-lines-per-function`: ファイル 500 行・関数 100 行以内

### バックエンド（golangci-lint + カスタム guardrails）

- `depguard`: レイヤー間の外部依存強制（GORM は adapter/postgres のみ等）
- カスタム静的解析（`tools/analyzers/cmd/guardrails/main.go`）:
  - レイヤー配置ポリシー・import 方向チェック
  - `adapter/http` が `domain` 型を直接使用していないか
  - application の exported API が domain 型を露出していないか
  - domain entity を `{}` リテラルで直接構築していないか
  - write application service が domain を経由しているか
  - `time.Now`, `os.Getenv` 等の副作用源の直接使用禁止
  - `AutoMigrate` 禁止
  - migration ファイル名・ペアポリシー

### セキュリティスキャン

- `govulncheck`: Go の既知脆弱性チェック
- `osv-scanner`: 依存関係の OSV チェック
- `gitleaks --no-git --config .gitleaks.toml`: シークレットスキャン

---

## 関連ドキュメント

| ドキュメント                  | 内容                                                       |
| ----------------------------- | ---------------------------------------------------------- |
| `CONTRIBUTING.md`             | コントリビューター向けの最短フロー                         |
| `CODING_STANDARDS.md`         | 機械的に fail するルールの完全一覧（guardrail の解説付き） |
| `AGENTS.md`                   | AI コーディングエージェント向けの実行方針                  |
| `devenv.nix`                  | Nix/devenv toolchain 定義                                  |
| `compose.yaml`                | Docker Compose infra/runtime 定義                          |
| `.zed/settings.json`          | Zed の LSP / formatter / scan 除外設定                     |
| `.zed/tasks.json`             | Zed から実行する `pnpm` ベースの開発・検証 task            |
| `packages/typespec/README.md` | TypeSpec 契約の詳細                                        |
