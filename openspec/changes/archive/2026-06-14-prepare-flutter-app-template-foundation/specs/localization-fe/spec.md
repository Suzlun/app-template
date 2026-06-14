## REMOVED Requirements

### Requirement: 認証済みアプリは AccountSetting.locale で SHALL 表示される

**Reason**

認証済み Product Svelte app と handwritten frontend domain を削除するため、`AccountSetting.locale` を Product frontend app に反映するUI仕様を維持しない。

**Migration**

公開 Web と Admin Console の locale requirements は維持する。将来 Flutter app が Account locale を扱う場合は、Flutter app の仕様として定義する。

## MODIFIED Requirements

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
