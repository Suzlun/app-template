## MODIFIED Requirements

### Requirement: MVCS 層間依存と import 制約

Admin Console の frontend code は `packages/web/admin/app -> packages/web/admin/domain -> packages/web/admin/api` の依存方向を SHALL 保つ。`packages/web/admin/app` は `packages/web/admin/domain`、`@app-template/web-ui`、`@app-template/web-i18n` のみを直接利用し、Admin generated API client を直接 import してはならない（MUST NOT）。`packages/web/admin/domain` は `packages/web/admin/api` を通じて Admin backend API を呼び出し、Product API SDK、DB client、server-only module を import してはならない（MUST NOT）。`packages/web/admin/api` は Admin surface から生成された package-local SDK のみを使用し、Product surface SDK を使用してはならない（MUST NOT）。`packages/web/admin` は SvelteKit server route handlers、server load/actions、`$lib/server`、Prisma、Valkey、OpenSearch、WebAuthn server library を runtime dependency として使用してはならない（MUST NOT）。これらの制約は lint で強制されなければならない（SHALL）。

**Customer Context**

Admin Console は強権限画面であるため、画面配信 package に backend domain logic、DB 接続、secret 取扱い、server-only action が存在すると、責務境界が曖昧になり監査と保守が難しくなる。運営者は Admin UI を安全に利用しながら、Account domain の判断を Backend に一元化したい。

#### Scenario: Admin app から API client を直接 import すると lint エラーになる (ADMIN-CONSOLE-FE-S038)

- **WHEN** `packages/web/admin/app` の `.svelte` または route module が Admin generated API client を直接 import する
- **THEN** lint は layer violation として失敗する

#### Scenario: Admin package に server-only module が存在すると lint エラーになる (ADMIN-CONSOLE-FE-S039)

- **WHEN** `packages/web/admin` に SvelteKit `+server.ts`、`+page.server.ts`、`src/lib/server`、または DB/Valkey/OpenSearch runtime module が存在する
- **THEN** lint は server ownership violation として失敗する

#### Scenario: Admin domain layer は Admin api layer 経由で account data を取得する (ADMIN-CONSOLE-FE-S040)

- **GIVEN** Accounts 画面が account 一覧を表示する
- **WHEN** `packages/web/admin/domain` が account 検索を実行する
- **THEN** 呼び出しは `packages/web/admin/api` の generated Admin SDK wrapper を通じて Admin backend に送信される
- **AND** Product SDK は import されない
