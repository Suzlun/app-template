## MODIFIED Requirements

### Requirement: API surface は service ごとに分離生成される

TypeSpec は Product surface と Admin surface を別 service として表現しなければならない（SHALL）。Product surface の OpenAPI / Go bindings は Product routes のみを含み、Admin operations を含んではならない（MUST NOT）。Admin surface の OpenAPI / TypeScript SDK / Go bindings は Admin operations のみを含み、Product operations を含んではならない（MUST NOT）。Product surface と Admin surface はどちらも `/api/v1/*` path policy に従い、両者の到達境界は origin、service artifact、binary、generated package で分離されなければならない（MUST）。各 surface の生成 artifact は surface 名を含む path または package boundary で分離され、片方の artifact だけを参照しても他方の operation が到達可能になってはならない（MUST NOT）。Product TypeScript SDK は生成 artifact として提供してはならない（MUST NOT）。

**Customer Context**

Admin API は強権限 operation を含むため、Product API の公開契約や生成 SDK に混入すると、意図しない host から運営機能へ到達できるリスクが生じる。Flutter アプリ基盤では Product TypeScript SDK を提供しないため、Product frontend package を生成境界として維持すると、存在しない surface への依存が残る。

#### Scenario: Product OpenAPI に Admin operation が含まれない (API-CONTRACT-BE-S001)

- **GIVEN** TypeSpec から Product surface の OpenAPI を生成する
- **WHEN** 生成された OpenAPI paths を確認する
- **THEN** Product tag / operationId / schema に Admin operation は存在しない
- **AND** Product Go bindings に Admin operation は生成されない
- **AND** Product TypeScript SDK package は生成されない

#### Scenario: Admin OpenAPI に Product operation が含まれない (API-CONTRACT-BE-S002)

- **GIVEN** TypeSpec から Admin surface の OpenAPI を生成する
- **WHEN** 生成された OpenAPI paths を確認する
- **THEN** Admin tag / operationId / schema / generated export だけが含まれ、Product operation は含まれない

#### Scenario: Surface ごとの server URL が分離される (API-CONTRACT-BE-S003)

- **GIVEN** Product と Admin の OpenAPI artifact が生成されている
- **WHEN** 各 artifact の `servers` を確認する
- **THEN** Product artifact は Product backend host を表現し、Admin artifact は Admin backend host を表現する

### Requirement: Codegen drift check は surface isolation を検証する

codegen drift check は Product OpenAPI、Product Go bindings、Admin OpenAPI、Admin TypeScript SDK、Admin Go bindings をそれぞれ検証しなければならない（SHALL）。Product artifact に Admin operationId、Admin tag、Admin schema-only response、または Admin generated export が含まれる場合、check は失敗しなければならない（MUST）。Admin artifact に Product operationId、Product tag、Product schema-only response、または Product generated export が含まれる場合、check は失敗しなければならない（MUST）。Backend build と lint は Product binary / Product HTTP adapter が Product bindings のみを参照し、Admin binary / Admin HTTP adapter が Admin bindings のみを参照することを検証しなければならない（SHALL）。Frontend lint は Admin SDK が `packages/web/admin/api` に閉じることを検証しなければならない（SHALL）。Product TypeScript SDK の drift check は存在してはならない（MUST NOT）。

**Customer Context**

生成 artifact は実装と CI の境界であり、誤った artifact が commit されると Product host から Admin operation が見える可能性がある。Flutter アプリ基盤では Product TypeScript SDK を提供しないため、drift check が削除済み package を要求すると、不要な frontend app surface を復活させる圧力になる。

#### Scenario: Product artifact に Admin operation が混入すると check が失敗する (API-CONTRACT-BE-S006)

- **GIVEN** Product OpenAPI artifact または Product Go bindings に Admin account creation の operationId または Admin tag が含まれている
- **WHEN** codegen drift check を実行する
- **THEN** check は失敗し、Product artifact から Admin operation を除外する必要があることを報告する

#### Scenario: Binary ごとに参照できる bindings が限定される (API-CONTRACT-BE-S007)

- **GIVEN** Product binary の source が Admin generated bindings を import している
- **WHEN** backend lint または build boundary check を実行する
- **THEN** Product binary の Admin bindings import は拒否される

#### Scenario: Admin bindings は Admin HTTP adapter だけが import できる (API-CONTRACT-BE-S008)

- **WHEN** `internal/app`、`internal/application/**`、`internal/domain/**`、Product HTTP adapter、または Product binary が Admin generated bindings を import している
- **THEN** backend lint は generated binding boundary violation として失敗する

#### Scenario: Admin SDK は Admin frontend package 境界を越えない (API-CONTRACT-BE-S009)

- **WHEN** `packages/web/lp/**` または `packages/web/ui/**` が Admin SDK を import する、または `packages/web/admin/**` が Product TypeScript SDK package を import する
- **THEN** frontend lint は SDK package boundary violation として失敗する
