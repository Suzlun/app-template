## Purpose

Product surface と Admin surface の API contract generation requirements をまとめる。TypeSpec service separation、Product OpenAPI / Product Go bindings / Admin OpenAPI / Admin TypeScript SDK / Admin Go bindings の surface isolation、shared model reuse、codegen drift checks を対象とする。

## Requirements

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

### Requirement: 共有 domain model は route surface と独立して再利用できる

TypeSpec は Account などの共有 schema model を surface から独立した shared module として参照できなければならない（SHALL）。共有 model module は route decorator または service-specific route namespace を定義してはならない（MUST NOT）。Product surface と Admin surface は必要な shared model を import できるが、他 surface の route namespace を import してはならない（MUST NOT）。同一概念の ID / error / pagination / audit correlation model は surface 間で互換性を保たなければならない（SHALL）。

**Customer Context**

Product と Admin は Account など同じ domain concept を扱うが、公開 route と運営 route は露出範囲が異なる。model 定義を重複させると不整合が発生し、route 定義を共有しすぎると Admin operation が Product surface に混入する。

#### Scenario: Shared model import は route を増やさない (API-CONTRACT-BE-S004)

- **GIVEN** Admin surface が共有 Account model を import する
- **WHEN** Admin OpenAPI を生成する
- **THEN** 共有 model の import によって Product route は Admin OpenAPI に追加されない

#### Scenario: Product surface は Admin route namespace を import できない (API-CONTRACT-BE-S005)

- **GIVEN** Product surface の TypeSpec source が Admin route namespace を import している
- **WHEN** contract lint を実行する
- **THEN** surface boundary violation として失敗する

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
