## MODIFIED Requirements

### Requirement: オペレーターは passkey でログインする

Admin Console は `/login` route で passkey 専用ログイン画面を SHALL 提供する。Login UI は browser WebAuthn API と `packages/web/admin/domain` の auth flow を使用し、`packages/web/admin/api` 経由で same-origin の `/api/v1/auth/passkey/*` API を呼び出さなければならない（SHALL）。Login 成功時、Admin frontend は response body の operator accessToken と session metadata を memory state に保持し、operator refreshToken は Admin backend が `HttpOnly; Secure; SameSite=Lax` Cookie として管理しなければならない（SHALL）。Admin auth UI は SvelteKit server hooks、server load/actions、package-local BFF route を認証判断に使用してはならない（MUST NOT）。Admin auth UI は Product auth API または Product SDK を使用して operator session を作成してはならない（MUST NOT）。認証失敗 UI は operator 存在、passkey 登録状態、setup token 状態を推測できない秘匿的な文言を保たなければならない（MUST）。

**Customer Context**

Admin 認証は passkey、operator session、setup token、CSRF を扱うため、画面配信 package に server-side 認証処理が存在すると責務境界が崩れる。運営者は静的 Admin UI から安全に認証し、認証判断は Admin backend に集約される必要がある。

#### Scenario: Login UI は Admin backend auth API を呼び出す (ADMIN-AUTH-FE-S027)

- **GIVEN** Operator が `/login` を開いている
- **WHEN** email を入力して passkey login を開始する
- **THEN** UI は Admin api layer 経由で Admin backend の passkey start API を呼び出す
- **AND** package-local BFF route は呼び出されない

#### Scenario: Product auth SDK は operator session 作成に使われない (ADMIN-AUTH-FE-S028)

- **WHEN** Admin auth domain code が Product auth SDK を import して operator login を実装している
- **THEN** lint は dependency boundary violation として失敗する

#### Scenario: Operator login は accessToken だけをブラウザーから読める state に保持する (ADMIN-AUTH-FE-S033)

- **GIVEN** Operator が passkey login を完了する
- **WHEN** Admin auth domain state を確認する
- **THEN** operator accessToken と session metadata は memory state に存在する
- **AND** operator refreshToken 平文は memory state、localStorage、sessionStorage、IndexedDB、URL に存在しない

### Requirement: 認証済みオペレーターは自身の passkey を管理できる

認証済みオペレーターは画面上で自身の登録済み passkey credential 一覧を SHALL 確認できる。新しい passkey を追加する WebAuthn 登録フローを SHALL 提供し、特定 passkey の削除アクションを SHALL 提供する。Passkey management UI は browser WebAuthn API と `packages/web/admin/domain` の flow を使用し、`packages/web/admin/api` 経由で same-origin の `/api/v1/auth/passkeys*` API を呼び出さなければならない（SHALL）。credential handle / public key は認証 material として画面に露出せず、削除対象の識別には公開可能な passkey identifier と登録 metadata を使わなければならない（MUST）。最後の 1 件の削除操作は無効化しなければならない（MUST）。

**Customer Context**

オペレーターは複数の device で Admin Console にアクセスする。passkey を追加・削除できることで、device 追加や紛失時に安全な鍵管理が可能になる。passkey 管理 API は Admin backend が所有し、静的 frontend は server-side BFF を持たずに同一 Admin host の `/api/v1/*` を呼び出す。

#### Scenario: 登録済み passkey 一覧を表示する (ADMIN-AUTH-FE-S012)

- **GIVEN** オペレーターが認証済みで 2 件の passkey を登録済みである
- **WHEN** passkey 管理画面を表示する
- **THEN** 2 件の passkey が公開可能な passkey identifier / バックアップ状態 / 登録日時とともに一覧表示される

#### Scenario: 新しい passkey を追加できる (ADMIN-AUTH-FE-S013)

- **GIVEN** オペレーターが認証済みである
- **WHEN** 「passkey を追加」をクリックし WebAuthn 登録を完了する
- **THEN** 新しい passkey が一覧に追加され、既存 passkey は変化しない

#### Scenario: 最後の 1 件の passkey は削除ボタンが無効化される (ADMIN-AUTH-FE-S014)

- **GIVEN** オペレーターが passkey を 1 件のみ持つ
- **WHEN** passkey 管理画面を表示する
- **THEN** 削除ボタンが無効化または非表示になっている

#### Scenario: 2 件以上の場合は passkey を削除できる (ADMIN-AUTH-FE-S015)

- **GIVEN** オペレーターが passkey を 2 件以上持つ
- **WHEN** 特定 passkey の削除をクリックし確認する
- **THEN** その passkey が一覧から削除され、残りは保持される

#### Scenario: WebAuthn 登録がキャンセルされた場合は一覧が変化しない (ADMIN-AUTH-FE-S016)

- **GIVEN** オペレーターが passkey 追加フローを開始した
- **WHEN** WebAuthn ダイアログでキャンセルする
- **THEN** 一覧は変化せず、エラーメッセージが表示される
