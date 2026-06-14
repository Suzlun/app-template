## Purpose

公開 Web LP と Admin Console の frontend ロケール要件を定義し、URL ロケール、保存済み Admin 言語設定、辞書網羅性、表示面ごとの i18n 所有境界を扱う。

## Requirements

### Requirement: 公開 Web はパスベースのロケール表示を SHALL 提供する

システムは、対応する公開ロケールごとにロケール接頭辞付き公開ルートを SHALL 提供する。対応する公開ロケールは `ja` と `en` でなければならない（MUST）。公開サイトは URL のロケール区分で選択したロケール辞書から公開コンテンツを SHALL 表示する。公開 root ルートは、安全な言語判定と決定的な既定ロケールを使って、対応ロケールルートへ SHALL 誘導する。未対応ロケールのパス区分では、無効なロケールの翻訳済みコンテンツを表示してはならない（MUST NOT）。ロケール付き公開ページは、ブラウザ、検索エンジン、支援技術がページ言語を識別できる言語別メタデータを SHALL 提供する。

**Customer Context**

公開サイトの閲覧者は、URL を共有した相手にも同じ言語でページを見せたい。ブラウザや端末の言語設定だけに依存すると、共有リンク、検索結果、ブックマークで表示言語が安定せず、公開サイトとしての説明責任と SEO が弱くなる。

**要求**

- システムは、対応する公開ロケールごとにロケール接頭辞付き公開ルートを SHALL 提供する。
- 対応する公開ロケールは `ja` と `en` でなければならない（MUST）。
- 公開サイトは、URL のロケール区分で選択したロケール辞書から公開コンテンツを SHALL 表示する。
- 公開 root ルートは、安全な言語判定と決定的な既定ロケールを使って、対応ロケールルートへ SHALL 誘導する。
- 未対応ロケールのパス区分では、無効なロケールの翻訳済みコンテンツを表示してはならない（MUST NOT）。
- ロケール付き公開ページは、ブラウザ、検索エンジン、支援技術がページ言語を識別できる言語別メタデータを SHALL 提供する。

#### Scenario: 公開 root は対応ロケール URL へ誘導する (LOCALIZATION-FE-S001)

- **前提** 閲覧者が公開サイトの `/` を開く
- **操作** システムが表示言語を選択する
- **結果** 閲覧者は `ja` または `en` のロケール付き公開 URL へ到達する

#### Scenario: 公開ロケール URL は同じ言語の内容を表示する (LOCALIZATION-FE-S002)

- **前提** 閲覧者が `/ja` または `/en` を開く
- **操作** ページが表示される
- **結果** 見出し、説明文、ナビゲーション、CTA、メタデータは URL のロケールに対応した言語で表示される

#### Scenario: 未対応ロケールは翻訳済みページとして扱われない (LOCALIZATION-FE-S003)

- **前提** 閲覧者が未対応ロケールを含む公開 URL を開く
- **操作** システムがロケールを検証する
- **結果** システムは未対応ロケールのページ内容を表示せず、対応ロケールへの誘導または not found を返す

### Requirement: Admin Console はオペレーター言語設定で SHALL 表示される

システムは、認証済みオペレーターが読み込まれた後、そのオペレーター言語で Admin Console の文言を SHALL 表示する。Admin Console のレイアウトデータは、クライアント表示に使う認証済みオペレーターの言語を SHALL 含む。Admin Console は、認証済みオペレーターが自分の言語を更新できる設定画面を SHALL 提供する。Admin Console の operator locale 表示・更新は Admin operator 本人の設定として扱い、Product AccountSetting を読み書きしてはならない（MUST NOT）。Admin Console の認証前ルートは、安全な代替言語を SHALL 使用し、認証済みオペレーターを要求してはならない（MUST NOT）。Admin Console のナビゲーション、設定ラベル、テーブル空状態、検証メッセージ、操作フィードバックはロケール辞書から SHALL 取得する。Admin Console は、通常のプロフィール言語設定操作で別オペレーターの言語設定を変更できてはならない（MUST NOT）。

**Customer Context**

管理オペレーターはサポート対応や監査確認を複数端末で行う。管理画面の言語が端末ごとに変わると、操作ミスや教育コストが増えるため、オペレーター本人の保存済み設定で一貫した言語を表示する必要がある。

**要求**

- システムは、認証済みオペレーターが読み込まれた後、そのオペレーター言語で Admin Console の文言を SHALL 表示する。
- Admin Console のレイアウトデータは、クライアント表示に使う認証済みオペレーターの言語を SHALL 含む。
- Admin Console は、認証済みオペレーターが自分の言語を更新できる設定画面を SHALL 提供する。
- Admin Console の operator locale 表示・更新は Admin operator 本人の設定として扱い、Product AccountSetting を読み書きしてはならない（MUST NOT）。
- Admin Console の認証前ルートは、安全な代替言語を SHALL 使用し、認証済みオペレーターを要求してはならない（MUST NOT）。
- Admin Console のナビゲーション、設定ラベル、テーブル空状態、検証メッセージ、操作フィードバックはロケール辞書から SHALL 取得する。
- Admin Console は、通常のプロフィール言語設定操作で別オペレーターの言語設定を変更できてはならない（MUST NOT）。

#### Scenario: 認証済み Admin 画面は保存済みオペレーター言語で表示される (LOCALIZATION-FE-S007)

- **前提** オペレーターが保存済み言語 `en` を持つ
- **操作** オペレーターが Admin Console へログインする
- **結果** レイアウト、ナビゲーション、設定画面、操作メッセージは英語で表示される

#### Scenario: オペレーターは自分の言語設定を更新できる (LOCALIZATION-FE-S008)

- **前提** オペレーターが Admin Console の設定画面を開いている
- **操作** オペレーターが自分の表示言語を更新する
- **結果** 設定は保存され、以後の Admin Console 表示は選択した言語で表示される

#### Scenario: Admin 認証前画面は代替言語で表示される (LOCALIZATION-FE-S009)

- **前提** 未認証の利用者が Admin Console のログイン画面を開く
- **操作** operator locale が存在しない
- **結果** ログイン画面は対応ロケールの代替文言を表示し、operator DB の認証済み読み取りを要求しない

### Requirement: Frontend i18n 境界は辞書網羅性と表示面所有を SHALL 強制する

システムは、公開 Web LP と Admin Console が所有する locale JSON files について、対応ロケール `ja` と `en` の辞書 key 差分を SHALL 検出する。システムは、`packages/web/i18n` に表示面固有の locale JSON files が存在しないことを SHALL 検証する。システムは、ユーザー向け UI 文言が各表示面の locale JSON files と共有 i18n 実装を経由することを SHALL 強制し、未翻訳の直書き UI literal を SHALL 拒否する。`packages/web/ui` は、`@app-template/web-i18n` または表示面固有の i18n module を import してはならない（MUST NOT）。`packages/web/lp` と `packages/web/admin/app` は互いの locale JSON files を import してはならない（MUST NOT）。再利用 UI package は表示言語、固定 locale formatter、app 固有文言、または具体的な locale JSON files を必要とする component を所有してはならない（MUST NOT）。

**Customer Context**

利用者は表示面ごとの文言が同じ言語設定で欠けなく表示されることを期待する。辞書 key の欠落、表示面間の辞書共有、UI package 内の固定言語文言が残ると、設定した言語でも一部だけ別言語になり、アクセシビリティ、サポート、管理操作の信頼性が下がる。

**要求**

- システムは、公開 Web LP と Admin Console が所有する locale JSON files について、対応ロケール `ja` と `en` の辞書 key 差分を SHALL 検出する。
- システムは、`packages/web/i18n` に表示面固有の locale JSON files が存在しないことを SHALL 検証する。
- システムは、ユーザー向け UI 文言が各表示面の locale JSON files と共有 i18n 実装を経由することを SHALL 強制し、未翻訳の直書き UI literal を SHALL 拒否する。
- `packages/web/ui` は、`@app-template/web-i18n` または表示面固有の i18n module を import してはならない（MUST NOT）。
- `packages/web/lp` と `packages/web/admin/app` は互いの locale JSON files を import してはならない（MUST NOT）。
- 再利用 UI package は表示言語、固定 locale formatter、app 固有文言、または具体的な locale JSON files を必要とする component を所有してはならない（MUST NOT）。

#### Scenario: 辞書欠落 key は標準検証で失敗する (LOCALIZATION-FE-S010)

- **前提** 公開 Web LP または Admin Console が所有する locale JSON files で、対応ロケール `ja` と `en` の key に差分がある
- **操作** 標準 lint または辞書網羅性検証を実行する
- **結果** 欠落 key path と所有 package が報告され、検証は失敗する

#### Scenario: 未翻訳 UI literal と i18n import 境界違反は標準 lint で失敗する (LOCALIZATION-FE-S011)

- **前提** 対象 UI ソースに未翻訳のユーザー向け直書き文言、または shared UI からの `@app-template/web-i18n` import が存在する
- **操作** 標準 lint を実行する
- **結果** 違反した file と rule が報告され、検証は失敗する

#### Scenario: 再利用 UI は表示言語を所有せず具体 component は表示面へ移される (LOCALIZATION-FE-S013)

- **前提** locale JSON files、固定 locale formatter、または表示面固有文言を必要とする concrete component が存在する
- **操作** 実装者が component の配置と imports を検証する
- **結果** concrete component は `packages/web/lp` または `packages/web/admin/app` の所有 package に置かれ、`packages/web/ui` は localized label と formatter を props として受け取る reusable primitive だけを提供する
