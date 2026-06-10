# Codex実装指示書: app-template基盤整理とSvelteアプリ時代コードの完全撤去

## 0. この指示書の目的

この指示書は、`Suzlun/app-template` を **Flutterアプリ構築テンプレートの基盤** にするための、Codex向け実装指示である。

今回の作業は、Flutterアプリ本体を作る作業ではない。

今回の目的は、`www-template` 由来のSvelteアプリ時代の余計なコード、ディレクトリ、lint、test、build、codegen、Dev Container前提、ドキュメント、Agent設定を完全に排除し、後続作業でFlutterアプリを安全に追加できるNix/devenvベースの基盤を作ることである。

---

## 1. 最重要方針

### 1.1 ゴール

以下の状態にする。

```text
app-template
  - Flutterアプリ構築テンプレートの土台である
  - ただし、今回のPRではFlutterアプリ本体を作らない
  - 開発環境はNix/devenvを正とする
  - Dev Containerは完全廃止する
  - Docker Composeはインフラ再現とBE/Web runtime用途として残す
  - Svelteアプリ時代のpackages/frontend系コードは完全に削除する
  - Web補助群はpackages/web配下へ整理する
  - BackendとTypeSpecは残す
```

### 1.2 今回やること

```text
- Dev Containerの完全廃止
- Nix/devenv化
- Compose群の維持と再配置
- 既存workspaceコンテナのruntime化
- packages/web を packages/web/lp へ移動
- packages/frontend/ui を packages/web/ui へ移動
- packages/frontend/i18n を packages/web/i18n へ移動
- packages/admin/* を packages/web/admin/* へ移動
- packages/frontend/app を削除
- packages/frontend/domain を削除
- packages/frontend/api を削除
- packages/frontend ディレクトリを最終的に削除
- packages/frontend前提のlint/test/build/codegen/path alias/docs/Agent設定を削除
- @www-template/* scopeを@app-template/*へ変更
- www-template表記をapp-templateへ変更
- README、AGENTS、CONTRIBUTING、Zed設定、CIを新構成へ更新
```

### 1.3 今回絶対にやらないこと

以下はすべてスコープ外である。やってはいけない。

```text
- flutter createを実行しない
- packages/appを作らない
- root pubspec.yamlを作らない
- Dart workspaceを作らない
- Flutterアーキテクチャを決めない
- Flutter routing/state management設計を入れない
- Flutter lintルールを追加しない
- Flutter CIを追加しない
- flutter analyzeを標準検証に入れない
- flutter testを標準検証に入れない
- flutter build apkを標準検証に入れない
- flutter build iosを標準検証に入れない
- Dart API client生成を追加しない
- 仮のFlutter実装を置かない
- 後続作業用のTODOコメントや仮置きファイルを残さない
```

### 1.4 互換性を残さない

この移行は破壊的変更として扱う。

以下は禁止する。

```text
- 旧パスから新パスへのsymlink
- 旧npm package名を残した互換package
- 旧tsconfig path aliasを残すこと
- 旧import名を残すこと
- 旧script名を互換目的で残すこと
- deprecated wrapperを置くこと
- 後で消す予定の互換コードを置くこと
```

旧構造を支えるコードは、一時的互換ではなく削除する。

---

## 2. 現状の前提

作業開始時点で、リポジトリには `www-template` 由来の前提が残っている。

確認すべき代表例:

```text
package.json
  - nameがwww-template
  - descriptionがSvelte frontend, TypeSpec, Go backendのmonorepo説明
  - dev:app/build:app/test:clientなどが旧Svelte app前提
  - gen:api-sdkがpackages/frontend/apiへProduct TS SDKを生成
  - lint:eslint:frontendがpackages/frontend/app/domain/api/ui/i18nを対象にする

pnpm-workspace.yaml
  - packages/frontend/*
  - packages/web
  - packages/admin/*

.devcontainer/
  - devcontainer.json
  - Dockerfile
  - compose.yaml
  - README.md
  - scripts/post-create.sh

scripts/devcontainer/run.sh
  - hostからDev Container内のtoolchainを使うwrapper

AGENTS.md
  - Dev Container前提
  - packages/frontend/app/domain/api/ui前提
  - scripts/devcontainer/run.sh前提

README.md
  - Zed + Dev Container推奨
  - packages/frontend構成説明
```

これらはすべて新方針に合わせて更新または削除する。

---

## 3. Codexの作業ルール

### 3.1 最初に読むもの

作業開始時に必ず次を読む。

```text
AGENTS.md
package.json
pnpm-workspace.yaml
tsconfig.base.json
eslint.config.js
vitest.config.ts
playwright.config.ts
.github/workflows/ci.yml
README.md
CONTRIBUTING.md
CODING_STANDARDS.md
.devcontainer/devcontainer.json
.devcontainer/compose.yaml
.devcontainer/Dockerfile
scripts/devcontainer/run.sh
```

ただし、既存AGENTS.mdのDev Container前提のコマンドポリシーは今回の移行対象である。

今回の作業では `scripts/devcontainer/run.sh` を使ってはいけない。これは削除対象である。

### 3.2 作業時の基本姿勢

```text
- 旧構造の互換性を残さない
- 消すべきものは消す
- 迷ったらFlutter app本体を作らない方向に倒す
- 迷ったら旧Svelte app時代のコードを削除する方向に倒す
- ただしWeb LP、Web UI、Web i18n、Web Admin、Backend、TypeSpecは残す
- TODOや仮実装で逃げない
- テストを弱めない
- supply-chain hardening設定を弱めない
- pnpm workspaceのsecurity系設定を削らない
- lintを通すためだけにルールを広範囲に無効化しない
```

### 3.3 コマンド実行方針

Nix/devenvを導入する前は、ファイル調査やgit操作のみを行う。

Nix/devenv導入後は、検証コマンドを原則として以下の形式で実行する。

```sh
devenv shell -- pnpm <script>
```

または、flakeがdevShellを正しくexportしている場合は次も許可する。

```sh
nix develop --command pnpm <script>
```

ただし、どちらを採用する場合でもREADME、AGENTS、CI、Zed tasksの表記を統一すること。

---

## 4. Phase 1: 現状調査

### 4.1 旧構造参照の洗い出し

まず次を実行する。

```sh
git grep -n "www-template" || true
git grep -n "@www-template" || true
git grep -n "packages/frontend" || true
git grep -n "packages/admin" || true
git grep -n "packages/web" || true
git grep -n "devcontainer" || true
git grep -n "Dev Container" || true
git grep -n "scripts/devcontainer" || true
git grep -n "@www-template/app" || true
git grep -n "@www-template/domain" || true
git grep -n "@www-template/api" || true
```

調査結果をもとに、移動、削除、置換対象を確定する。

### 4.2 対象分類

#### 削除対象

```text
packages/frontend/app
packages/frontend/domain
packages/frontend/api
packages/frontend
.devcontainer/devcontainer.json
.devcontainer/scripts/post-create.sh
.devcontainer/README.md
scripts/devcontainer/run.sh
```

#### 移動対象

```text
packages/web              -> packages/web/lp
packages/frontend/ui      -> packages/web/ui
packages/frontend/i18n    -> packages/web/i18n
packages/admin/app        -> packages/web/admin/app
packages/admin/api        -> packages/web/admin/api
packages/admin/domain     -> packages/web/admin/domain
.devcontainer/compose.yaml -> compose.yaml または compose/infra.yaml
.devcontainer/Dockerfile  -> docker/runtime/Dockerfile
.devcontainer/signoz      -> compose/signoz または docker/signoz
```

#### 残す対象

```text
packages/backend
packages/typespec
scripts/go
scripts/codegen
scripts/security
.config/local.toml
.config/local.admin.toml
.github/workflows/ci.yml
.zed
.opencode
openspec
```

ただし、残す対象の中に旧frontend構造やDev Container前提が書かれている場合は更新または削除する。

---

## 5. Phase 2: Nix/devenv導入

### 5.1 追加するファイル

rootに以下を追加する。

```text
flake.nix
flake.lock
devenv.nix
devenv.yaml
devenv.lock
```

### 5.2 Nix/devenvの責務

Nix/devenvは、このリポジトリの標準toolchainを提供する。

最低限含めるもの:

```text
Node.js
pnpm
Go
gopls
goimports
golangci-lint
golang-migrate
oapi-codegen
TypeSpec compiler
wrangler
git
jq
bash
shellcheck
gitleaks
osv-scanner
Playwright実行に必要なブラウザまたは依存
```

必要なら含めてよいもの:

```text
Flutter SDK
Android SDK
Android platform tools
JDK
CocoaPods
```

ただし、Flutter SDK、Android SDK、CocoaPodsを入れる場合でも、今回はFlutter app本体を作らない。

### 5.3 Flutter toolchainの扱い

今回の目的はFlutter app本体ではなく基盤作成である。

したがって、Flutter toolchainをdevenvに入れる場合でも、許可される範囲は以下に限定する。

```text
- flutterコマンドがdevenv内で利用可能になる
- Android SDK/JDKがdevenv内で利用可能になる
- 手動確認用にdoctor:flutter scriptを置く
```

標準検証に入れてはいけないもの:

```text
- flutter analyze
- flutter test
- flutter build apk
- flutter build ios
```

`package.json` に入れてよいscriptは次の程度に留める。

```json
{
  "scripts": {
    "doctor:flutter": "flutter doctor -v"
  }
}
```

ただし、Flutter SDKを今回入れない判断をした場合は、このscriptも追加しない。

### 5.4 cache隔離

devenvのshell entryでは、可能な範囲で開発cacheをrepo配下に寄せる。

推奨:

```sh
export PROJECT_ROOT="$PWD"
export XDG_CACHE_HOME="$PROJECT_ROOT/.cache/xdg"
export NPM_CONFIG_CACHE="$PROJECT_ROOT/.cache/npm"
export PNPM_HOME="$PROJECT_ROOT/.cache/pnpm-home"
export GOCACHE="$PROJECT_ROOT/.cache/go-build"
export GOMODCACHE="$PROJECT_ROOT/.cache/go-mod"
export PLAYWRIGHT_BROWSERS_PATH="$PROJECT_ROOT/.cache/ms-playwright"
export PUB_CACHE="$PROJECT_ROOT/.cache/pub"
export GRADLE_USER_HOME="$PROJECT_ROOT/.cache/gradle"
export ANDROID_USER_HOME="$PROJECT_ROOT/.cache/android"
export ANDROID_AVD_HOME="$PROJECT_ROOT/.cache/android/avd"
```

作成する必要があるディレクトリはshell entryで `mkdir -p` する。

### 5.5 .gitignore更新

`.gitignore` に不足があれば追加する。

```gitignore
.cache/
.devenv/
.direnv/
```

今回はFlutter projectを作らないため、Flutter project固有のignoreは原則追加しない。

ただし、Flutter SDKをdevenvに含めて `flutter doctor` のみ実行する場合にrepo rootへ生成物が出るなら、その生成物だけignoreする。

### 5.6 Nixの検証

追加後、次を実行する。

```sh
nix flake check
nix develop --command node --version
nix develop --command pnpm --version
nix develop --command go version
```

`devenv shell` を標準にする場合は次も実行する。

```sh
devenv shell -- node --version
devenv shell -- pnpm --version
devenv shell -- go version
```

Flutter SDKを入れた場合だけ、次を任意で実行する。

```sh
devenv shell -- flutter doctor -v
```

この任意確認が失敗しても、今回の標準検証をブロックしない。失敗する場合はREADMEに「Flutter toolchainは次回の運用ルール策定で確定する」と逃げるのではなく、今回入れるなら原因を直す。直せないならFlutter toolchain自体を今回のNix定義から外す。

---

## 6. Phase 3: Dev Container完全廃止

### 6.1 削除するファイル

以下を削除する。

```text
.devcontainer/devcontainer.json
.devcontainer/scripts/post-create.sh
.devcontainer/README.md
scripts/devcontainer/run.sh
```

削除後、`.devcontainer` が空になった場合はディレクトリも残さない。

### 6.2 compose.yamlの移動

`.devcontainer/compose.yaml` は削除せず、Compose定義として移動する。

推奨:

```text
.devcontainer/compose.yaml
-> compose.yaml
```

`compose.yaml` はDev Container定義ではなく、ローカルインフラ再現とBE/Web runtime実行用にする。

### 6.3 Dockerfileの移動

`.devcontainer/Dockerfile` は必要であればruntime用途に移動する。

```text
.devcontainer/Dockerfile
-> docker/runtime/Dockerfile
```

ただし、Nix/devenvをtoolchainの正にするなら、DockerfileがNode/Go/pnpm/wrangler等のバージョン定義の第二の正になってはいけない。

選択肢:

```text
A. runtime containerはNix/devenvを使う薄い実行環境にする
B. runtime containerはBE/Webの実行に必要な最小toolchainだけを持つ
C. runtime containerを削除し、Composeは純粋にinfra serviceだけにする
```

今回のユーザー方針では、既存workspaceコンテナはBEとWeb群の実行環境にするため、AまたはBを採用する。

### 6.4 signoz設定の移動

現在のcomposeが `.devcontainer/signoz` を相対参照している場合、compose移動後に相対パスが壊れる。

次のいずれかへ移動する。

```text
.devcontainer/signoz
-> compose/signoz
```

または

```text
.devcontainer/signoz
-> docker/signoz
```

移動後、compose内のbind mountを必ず更新する。

例:

```yaml
volumes:
  - type: bind
    source: ./compose/signoz
    target: /etc/signoz
    read_only: true
```

### 6.5 Dev Container表記の撤去

次の文字列は、原則としてリポジトリから消す。

```text
devcontainer
Dev Container
scripts/devcontainer
.devcontainer
Open in Container
/workspaces/www-template
/workspaces/app-template
```

例外はない前提で作業する。

どうしてもドキュメントで過去の移行理由を残したい場合も、今回のリポジトリには残さない。テンプレートとしてのノイズになる。

---

## 7. Phase 4: Compose再定義

### 7.1 service構成

Composeは残す。

残すservice:

```text
postgres
valkey
opensearch
minio
mailpit
signoz-init-clickhouse
signoz-zookeeper
signoz-clickhouse
signoz-telemetrystore-migrator
signoz
signoz-otel-collector
runtime
```

`runtime` は既存の `workspace` serviceを置き換える。

### 7.2 workspace serviceのrename

既存のservice名:

```yaml
services:
  workspace:
```

新しいservice名:

```yaml
services:
  runtime:
```

`runtime` はDev Container用ではない。

責務:

```text
- Go backend実行
- Web LP実行
- Admin Web実行
- TypeSpec/codegen実行
- 必要な場合のpnpm install
```

### 7.3 workspace mount path

旧pathは禁止する。

削除対象:

```text
/workspaces/www-template
```

runtime container内のmount pathは以下のようにする。

```text
/workspace/app-template
```

または

```text
/repo
```

どちらかに統一する。

例:

```yaml
services:
  runtime:
    volumes:
      - .:/workspace/app-template:cached
    working_dir: /workspace/app-template
```

### 7.4 runtime environment更新

`www-template` を含む環境変数値は変更する。

例:

```yaml
CONFIG_PATH: /workspace/app-template/.config/local.toml
ADMIN_CONFIG_PATH: /workspace/app-template/.config/local.admin.toml
```

DB名、ユーザー名、パスワードは、SQL識別子として扱いやすいように `app_template` を推奨する。

```yaml
POSTGRES_DB: app_template
POSTGRES_USER: app_template
POSTGRES_PASSWORD: app_template
```

接続URLも合わせる。

```text
postgres://app_template:app_template@postgres:5432/app_template?sslmode=disable
```

### 7.5 ports整理

旧Svelte app用portは削除する。

削除候補:

```text
5174 旧app dev server
```

残す候補:

```text
5173 Web LP
5176 Web Admin
8080 Product API
8081 Admin API
8025 Mailpit UI
9001 MinIO Console
9200 OpenSearch
3301 SigNoz UI
4317 OTLP gRPC
4318 OTLP HTTP
```

`3001` など用途不明のportは、実際に使われていないなら削除する。

### 7.6 SigNoz profile化

SigNozは重いため、可能ならprofile化する。

例:

```yaml
services:
  signoz:
    profiles:
      - observability
```

関連serviceすべてに同じprofileを付ける。

ただし、既存の標準開発でSigNozを常時使う必要がある場合はprofile化しない。判断した理由をREADMEに書く。

---

## 8. Phase 5: ディレクトリ再配置

### 8.1 移動後の目標構造

最終的に以下の構造にする。

```text
.
├── flake.nix
├── flake.lock
├── devenv.nix
├── devenv.yaml
├── devenv.lock
├── compose.yaml
├── docker/
│   └── runtime/
│       └── Dockerfile
├── compose/
│   └── signoz/
├── packages/
│   ├── backend/
│   ├── typespec/
│   └── web/
│       ├── lp/
│       ├── ui/
│       ├── i18n/
│       └── admin/
│           ├── app/
│           ├── api/
│           └── domain/
├── scripts/
├── tests/
├── AGENTS.md
├── README.md
├── CONTRIBUTING.md
├── CODING_STANDARDS.md
├── package.json
├── pnpm-workspace.yaml
├── tsconfig.base.json
├── eslint.config.js
├── vitest.config.ts
└── playwright.config.ts
```

存在してはいけないもの:

```text
packages/frontend
packages/app
pubspec.yaml
.devcontainer
scripts/devcontainer
```

### 8.2 安全な移動手順

`packages/web` を `packages/web/lp` に直接移動すると入れ子衝突しやすい。必ず一時パスを使う。

例:

```sh
git mv packages/web packages/_web-lp-tmp
mkdir -p packages/web
git mv packages/_web-lp-tmp packages/web/lp
```

次に移動する。

```sh
mkdir -p packages/web/admin

git mv packages/frontend/ui packages/web/ui
git mv packages/frontend/i18n packages/web/i18n

git mv packages/admin/app packages/web/admin/app
git mv packages/admin/api packages/web/admin/api
git mv packages/admin/domain packages/web/admin/domain
```

削除する。

```sh
git rm -r packages/frontend/app
git rm -r packages/frontend/domain
git rm -r packages/frontend/api
rmdir packages/frontend
rmdir packages/admin || true
```

`packages/admin` が空なら残さない。

### 8.3 削除時の注意

`packages/frontend/domain` や `packages/frontend/api` の型やロジックをどこかへ移植しない。

今回はFlutter appを作らないため、Product app用domain/api層は削除する。

ただし、Admin用のdomain/apiは残す。移動先は以下。

```text
packages/web/admin/domain
packages/web/admin/api
```

---

## 9. Phase 6: package名とimport更新

### 9.1 package scope変更

変更する。

```text
@www-template/web          -> @app-template/web-lp
@www-template/ui           -> @app-template/web-ui
@www-template/i18n         -> @app-template/web-i18n
@www-template/admin-app    -> @app-template/web-admin-app
@www-template/admin-api    -> @app-template/web-admin-api
@www-template/admin-domain -> @app-template/web-admin-domain
@www-template/typespec     -> @app-template/typespec
```

削除対象。

```text
@www-template/app
@www-template/domain
@www-template/api
```

### 9.2 package.json更新対象

更新するファイル:

```text
package.json
packages/typespec/package.json
packages/web/lp/package.json
packages/web/ui/package.json
packages/web/i18n/package.json
packages/web/admin/app/package.json
packages/web/admin/api/package.json
packages/web/admin/domain/package.json
```

### 9.3 dependency更新

#### packages/web/lp/package.json

変更前の例:

```json
{
  "dependencies": {
    "@www-template/i18n": "workspace:*",
    "@www-template/ui": "workspace:*"
  }
}
```

変更後:

```json
{
  "dependencies": {
    "@app-template/web-i18n": "workspace:*",
    "@app-template/web-ui": "workspace:*"
  }
}
```

#### packages/web/admin/app/package.json

変更前の例:

```json
{
  "dependencies": {
    "@www-template/admin-domain": "workspace:*",
    "@www-template/i18n": "workspace:*",
    "@www-template/ui": "workspace:*"
  }
}
```

変更後:

```json
{
  "dependencies": {
    "@app-template/web-admin-domain": "workspace:*",
    "@app-template/web-i18n": "workspace:*",
    "@app-template/web-ui": "workspace:*"
  }
}
```

#### packages/web/admin/domain/package.json

変更前の例:

```json
{
  "dependencies": {
    "@www-template/admin-api": "workspace:*"
  }
}
```

変更後:

```json
{
  "dependencies": {
    "@app-template/web-admin-api": "workspace:*"
  }
}
```

### 9.4 import一括更新

更新する。

```text
@www-template/ui           -> @app-template/web-ui
@www-template/i18n         -> @app-template/web-i18n
@www-template/admin-api    -> @app-template/web-admin-api
@www-template/admin-domain -> @app-template/web-admin-domain
@www-template/web          -> @app-template/web-lp
```

削除対象。

```text
@www-template/app
@www-template/domain
@www-template/api
```

これらを参照するコードが残っている場合、そのコードは旧Svelte app時代の残骸として削除する。

---

## 10. Phase 7: pnpm workspace更新

### 10.1 packages更新

`pnpm-workspace.yaml` を更新する。

変更後:

```yaml
packages:
  - 'packages/typespec'
  - 'packages/web/lp'
  - 'packages/web/ui'
  - 'packages/web/i18n'
  - 'packages/web/admin/*'
```

削除する。

```yaml
- 'packages/frontend/*'
- 'packages/web'
- 'packages/admin/*'
```

### 10.2 security設定は維持する

次の設定は削除しない。

```yaml
registries:
minimumReleaseAge:
minimumReleaseAgeStrict:
minimumReleaseAgeIgnoreMissingTime:
trustPolicy:
blockExoticSubdeps:
strictDepBuilds:
verifyStoreIntegrity:
strictStorePkgContentCheck:
pmOnFail:
engineStrict:
verifyDepsBeforeRun:
auditLevel:
allowBuilds:
overrides:
```

これらはsupply-chain hardeningの設定であり、今回の移行で弱めてはならない。

### 10.3 lockfile更新

package移動とpackage名変更後に実行する。

```sh
devenv shell -- pnpm install --frozen-lockfile
```

これが失敗する場合は、lockfile更新が必要である可能性が高い。

その場合、次を実行する。

```sh
devenv shell -- pnpm install
```

ただし、依存のsecurity設定を緩めて通してはいけない。

---

## 11. Phase 8: TypeScript設定更新

### 11.1 tsconfig.base.json更新

削除するpaths:

```json
{
  "@www-template/app/*": [],
  "@www-template/web/*": [],
  "@www-template/domain": [],
  "@www-template/domain/*": [],
  "@www-template/api": [],
  "@www-template/api/*": [],
  "@www-template/ui": [],
  "@www-template/ui/*": [],
  "@www-template/i18n": [],
  "@www-template/i18n/*": [],
  "@www-template/admin-app/*": [],
  "@www-template/admin-domain": [],
  "@www-template/admin-domain/*": [],
  "@www-template/admin-api": [],
  "@www-template/admin-api/*": []
}
```

追加するpaths:

```json
{
  "@app-template/web-lp/*": ["packages/web/lp/src/*"],
  "@app-template/web-ui": ["packages/web/ui/src/index.ts"],
  "@app-template/web-ui/*": ["packages/web/ui/src/*"],
  "@app-template/web-i18n": ["packages/web/i18n/src/index.ts"],
  "@app-template/web-i18n/*": ["packages/web/i18n/src/*"],
  "@app-template/web-admin-app/*": ["packages/web/admin/app/src/*"],
  "@app-template/web-admin-domain": ["packages/web/admin/domain/src/index.ts"],
  "@app-template/web-admin-domain/*": ["packages/web/admin/domain/src/*"],
  "@app-template/web-admin-api": ["packages/web/admin/api/src/index.ts"],
  "@app-template/web-admin-api/*": ["packages/web/admin/api/src/*"]
}
```

### 11.2 各packageのtsconfig extends更新

ディレクトリ深さが変わるため、`extends` を確認する。

代表例:

```text
packages/web/lp
  old: packages/web
  rootからの深さが1段増える
  ../../tsconfig.base.json -> ../../../tsconfig.base.json のような修正が必要な可能性あり

packages/web/ui
  old: packages/frontend/ui
  rootからの深さは概ね同じ
  ただし相対importは確認する

packages/web/i18n
  old: packages/frontend/i18n
  rootからの深さは概ね同じ
  ただし相対importは確認する

packages/web/admin/app
  old: packages/admin/app
  rootからの深さが1段増える
  ../../../tsconfig.base.json -> ../../../../tsconfig.base.json のような修正が必要な可能性あり
```

機械的置換ではなく、各packageで `pnpm --filter ... check` が通ることを確認する。

---

## 12. Phase 9: ESLint再構成

### 12.1 基本方針

`eslint.config.js` は、旧frontend app/domain/apiを消した構成へ再整理する。

禁止:

```text
- 旧frontend app/domain/api用の定数を残す
- 旧frontend app/domain/api用のruleをコメントアウトして残す
- 旧pathに対するignoreで逃げる
- 旧path aliasを残す
```

### 12.2 削除する概念

```text
frontendApp
frontendDomain
frontendApi
frontendRoute
frontendNonReact
frontendAppSvelteKitImportFiles
frontendAppSvelteKitRouteModuleFiles
frontendAppSvelteKitHookModuleFiles
frontendAppSvelteKitServerOnlyFiles
frontendAppRoutePageFiles
frontendAppComponentFiles
packages/frontend/app
packages/frontend/domain
packages/frontend/api
```

### 12.3 移動して残す概念

```text
frontendWeb -> webLp
frontendUi -> webUi
frontendI18n -> webI18n
adminApp -> webAdminApp
adminApi -> webAdminApi
adminDomain -> webAdminDomain
```

path更新:

```text
packages/web/src                  -> packages/web/lp/src
packages/frontend/ui/src          -> packages/web/ui/src
packages/frontend/i18n/src        -> packages/web/i18n/src
packages/admin/app/src            -> packages/web/admin/app/src
packages/admin/api/src            -> packages/web/admin/api/src
packages/admin/domain/src         -> packages/web/admin/domain/src
```

### 12.4 Svelte config import更新

変更前の例:

```js
import adminSvelteConfig from './packages/admin/app/svelte.config.js';
import uiSvelteConfig from './packages/frontend/ui/svelte.config.js';
```

変更後:

```js
import adminSvelteConfig from './packages/web/admin/app/svelte.config.js';
import uiSvelteConfig from './packages/web/ui/svelte.config.js';
```

必要ならLPのSvelte configも参照する。

### 12.5 root script更新

`package.json` のlint scriptsを更新する。

削除する旧script:

```json
{
  "lint:eslint:frontend": "...",
  "lint:eslint:ui": "... old packages/frontend/ui ...",
  "lint:eslint:i18n": "... old packages/frontend/i18n ..."
}
```

推奨:

```json
{
  "lint:eslint": "pnpm lint:eslint:root && pnpm lint:eslint:web && pnpm lint:eslint:admin",
  "lint:eslint:web": "node --max-old-space-size=4096 --expose-gc scripts/eslint-gc.js --no-inline-config --max-warnings 0 packages/web/lp packages/web/ui packages/web/i18n",
  "lint:eslint:admin": "node --max-old-space-size=4096 --expose-gc scripts/eslint-gc.js --no-inline-config --max-warnings 0 packages/web/admin"
}
```

もしSvelteKit syncが必要な場合は、package側にscriptを定義し、rootからはpackage scriptを呼ぶ。

例:

```json
{
  "lint:eslint:web": "pnpm --filter @app-template/web-lp sync && node --max-old-space-size=4096 --expose-gc scripts/eslint-gc.js --no-inline-config --max-warnings 0 packages/web/lp packages/web/ui packages/web/i18n"
}
```

ただし既存AGENTSに `pnpm exec` 禁止がある場合、`exec` 直呼びは避ける。

### 12.6 stylelint更新

変更前:

```text
packages/frontend/ui/src/styles/**/*.css
```

変更後:

```text
packages/web/ui/src/styles/**/*.css
```

### 12.7 legacy path guard

可能なら、旧pathや旧scopeの混入を検出するscriptを追加する。

例:

```json
{
  "scripts": {
    "lint:legacy-paths": "bash scripts/lint/no-legacy-paths.sh"
  }
}
```

`pnpm lint` に組み込む。

ただし、このguardがREADMEやAGENTSの正当な説明まで誤検知しないように、そもそもREADMEやAGENTSにも旧path文字列を残さない方針にする。

`no-legacy-paths.sh` の例:

```sh
#!/usr/bin/env bash
set -euo pipefail

patterns=(
  '@www-template'
  'scripts/devcontainer'
  'Dev Container'
  '.devcontainer'
  'packages/frontend'
)

for pattern in "${patterns[@]}"; do
  if git grep -n -- "$pattern" -- ':!pnpm-lock.yaml' >/tmp/legacy-paths.txt; then
    cat /tmp/legacy-paths.txt >&2
    printf 'legacy pattern remains: %s\n' "$pattern" >&2
    exit 1
  fi
done
```

このscriptを追加する場合、`pnpm-lock.yaml` に旧importerが残らないことも別途確認する。

---

## 13. Phase 10: root package.json更新

### 13.1 metadata更新

変更する。

```json
{
  "name": "app-template",
  "description": "app-template monorepo foundation for Flutter app projects with Web support, TypeSpec contract, and Go backend"
}
```

`www-template` は残さない。

### 13.2 scripts更新方針

削除するscript:

```text
dev:app
build:app
test:clientの旧app依存
lint:eslint:frontendの旧app/domain/api依存
lint:api-admin-policy内のpackages/frontend/api参照
```

`dev:client` は `dev:web` のaliasとして残してもよいが、テンプレートとして曖昧なら削除する。

推奨は、明確なscriptだけ残すこと。

### 13.3 dev scripts

推奨:

```json
{
  "scripts": {
    "dev:web": "pnpm --filter @app-template/web-lp dev",
    "dev:admin": "pnpm --filter @app-template/web-admin-app dev",
    "dev:server": "go -C packages/backend run ./cmd/api",
    "dev:admin-server": "ADMIN_CONFIG_PATH=../../.config/local.admin.toml go -C packages/backend run ./cmd/admin-api",
    "dev:all": "concurrently \"pnpm dev:server\" \"pnpm dev:admin-server\" \"pnpm dev:web\" \"pnpm dev:admin\""
  }
}
```

`dev:app` は作らない。

### 13.4 build scripts

推奨:

```json
{
  "scripts": {
    "build:web": "pnpm --filter @app-template/web-lp build",
    "build:admin": "pnpm --filter @app-template/web-admin-app build",
    "build:client": "pnpm build:web && pnpm build:admin",
    "build:server": "bash scripts/go/build.sh",
    "build": "pnpm build:server && pnpm build:client"
  }
}
```

Flutter buildは入れない。

### 13.5 check scripts

推奨:

```json
{
  "scripts": {
    "check": "pnpm --filter @app-template/typespec check && pnpm --filter @app-template/web-lp check && pnpm --filter @app-template/web-ui check && pnpm --filter @app-template/web-i18n check && pnpm --filter @app-template/web-admin-api check && pnpm --filter @app-template/web-admin-domain check && pnpm --filter @app-template/web-admin-app check && bash scripts/go/build.sh"
  }
}
```

Flutter checkは入れない。

### 13.6 test scripts

推奨:

```json
{
  "scripts": {
    "test": "pnpm test:run",
    "test:run": "pnpm test:web && pnpm test:admin && pnpm test:root && bash scripts/go/test.sh",
    "test:web": "pnpm --filter @app-template/web-lp test && pnpm --filter @app-template/web-ui test:run && pnpm --filter @app-template/web-i18n test:run",
    "test:admin": "pnpm --filter @app-template/web-admin-api test && pnpm --filter @app-template/web-admin-domain test && pnpm --filter @app-template/web-admin-app test",
    "test:server": "bash scripts/go/test.sh",
    "test:root": "vitest run --project root",
    "test:e2e": "playwright test",
    "test:e2e:ui": "playwright test --ui",
    "test:e2e:debug": "playwright test --debug"
  }
}
```

Flutter testは入れない。

### 13.7 lint scripts

推奨:

```json
{
  "scripts": {
    "lint": "pnpm --filter @app-template/typespec lint:openapi && pnpm lint:eslint && pnpm lint:i18n:coverage && pnpm lint:stylelint && bash scripts/go/lint.sh && bash scripts/security/lint-security.sh && pnpm check:codegen && pnpm lint:api-admin-policy",
    "lint:eslint": "pnpm lint:eslint:root && pnpm lint:eslint:web && pnpm lint:eslint:admin",
    "lint:eslint:root": "node --max-old-space-size=4096 --expose-gc scripts/eslint-gc.js --no-inline-config --max-warnings 0 commitlint.config.js eslint.config.js playwright.config.ts vitest.config.ts scripts tests",
    "lint:eslint:web": "node --max-old-space-size=4096 --expose-gc scripts/eslint-gc.js --no-inline-config --max-warnings 0 packages/web/lp packages/web/ui packages/web/i18n",
    "lint:eslint:admin": "node --max-old-space-size=4096 --expose-gc scripts/eslint-gc.js --no-inline-config --max-warnings 0 packages/web/admin",
    "lint:i18n:coverage": "tsx scripts/i18n/check-locales.ts",
    "lint:stylelint": "stylelint \"packages/web/ui/src/styles/**/*.css\" --max-warnings 0"
  }
}
```

`lint:api-admin-policy` は参照pathを更新する。

変更前のような参照は禁止:

```text
packages/frontend/api
```

Product TS SDKを削除するなら、policy対象からProduct TS SDKを外し、Admin SDKとGo bindingsとTypeSpecに絞る。

### 13.8 format scripts

対象globは基本維持してよい。

ただし、Flutter/Dartは今回入れないので `dart format` は追加しない。

---

## 14. Phase 11: codegen更新

### 14.1 基本方針

Product app用TS SDKは削除する。

削除対象:

```text
packages/frontend/api
packages/frontend/api/src/generated/client.ts
```

Admin TS SDKは残す。

移動先:

```text
packages/web/admin/api/src/generated/client.ts
```

Dart API client生成は今回追加しない。

### 14.2 root scripts更新

推奨:

```json
{
  "scripts": {
    "gen": "pnpm gen:admin-sdk && pnpm gen:backend",
    "gen:openapi": "pnpm --filter @app-template/typespec gen:openapi && prettier --write packages/typespec/openapi/openapi.json packages/typespec/openapi/admin.openapi.json",
    "gen:admin-sdk": "pnpm gen:openapi && pnpm --filter @app-template/web-admin-api gen && prettier --write packages/web/admin/api/src/generated/client.ts",
    "gen:backend": "bash scripts/go/gen-backend.sh",
    "check:codegen": "bash scripts/codegen/check.sh"
  }
}
```

### 14.3 orval config更新

移動後のAdmin API package内にあるorval configを確認する。

確認項目:

```text
- OpenAPI input pathがpackages/typespec/openapi/admin.openapi.jsonを正しく指している
- output pathがpackages/web/admin/api/src/generated/client.tsを正しく指している
- import aliasが@app-template/web-admin-apiに変わっている
- 相対パスが移動後の深さに合っている
```

Product TS SDK用orval configは削除する。

### 14.4 scripts/codegen/check.sh更新

`check.sh` が次を参照している場合は削除または更新する。

```text
packages/frontend/api
packages/admin/api
```

変更後のAdmin SDK path:

```text
packages/web/admin/api
```

Product TS SDKのdrift checkは削除する。

Backend Go bindingsのdrift checkは維持する。

---

## 15. Phase 12: Vitest更新

### 15.1 root vitest.config.ts更新

削除するproject:

```ts
{
  extends: './packages/frontend/app/vitest.config.ts',
  root: './packages/frontend/app',
  test: {
    name: 'frontend-app',
  },
}
```

変更するproject:

```text
./packages/frontend/ui -> ./packages/web/ui
./packages/admin/app   -> ./packages/web/admin/app
```

nameも整理する。

推奨:

```ts
projects: [
  {
    extends: './packages/web/lp/vitest.config.ts',
    root: './packages/web/lp',
    test: {
      name: 'web-lp',
    },
  },
  {
    extends: './packages/web/ui/vitest.config.ts',
    root: './packages/web/ui',
    test: {
      name: 'web-ui',
    },
  },
  {
    extends: './packages/web/admin/app/vitest.config.ts',
    root: './packages/web/admin/app',
    test: {
      name: 'web-admin',
    },
  },
  {
    root: './',
    test: {
      name: 'root',
      include: ['tests/**/*.test.ts'],
      environment: 'node',
      globals: true,
    },
  },
];
```

存在しないconfigを参照しないこと。

### 15.2 package内vitest configの相対パス更新

移動後に以下を確認する。

```text
packages/web/lp/vitest.config.ts
packages/web/ui/vitest.config.ts
packages/web/admin/app/vitest.config.ts
```

rootへの相対パス、setup file、tsconfig pathが壊れていないこと。

---

## 16. Phase 13: Playwright更新

### 16.1 旧Svelte app起動を削除

`playwright.config.ts` のwebServerから旧app起動を削除する。

削除対象:

```ts
{
  command: 'pnpm --filter @www-template/app dev',
  port: 5174,
  reuseExistingServer: process.env.CI === undefined,
  timeout: 120 * 1000,
}
```

### 16.2 Web LPとbackendのみへ整理

最低限:

```ts
webServer: [
  {
    command: 'pnpm --filter @app-template/web-lp dev',
    url: 'http://localhost:5173',
    reuseExistingServer: process.env.CI === undefined,
    timeout: 120 * 1000,
  },
  {
    command: 'pnpm dev:server',
    url: 'http://localhost:8080/health',
    reuseExistingServer: process.env.CI === undefined,
    timeout: 120 * 1000,
  },
];
```

Admin E2Eが存在する場合のみ、Admin dev serverを追加する。

```ts
{
  command: 'pnpm --filter @app-template/web-admin-app dev',
  port: 5176,
  reuseExistingServer: process.env.CI === undefined,
  timeout: 120 * 1000,
}
```

### 16.3 tests/e2e更新

E2E内で次を参照している場合は削除または更新する。

```text
app.localhost
5174
旧Svelte app routes
旧auth app UI
```

削除する場合、テストを空にしてごまかさない。

残すべきE2Eだけ残す。

---

## 17. Phase 14: i18n更新

### 17.1 i18n package移動

変更:

```text
packages/frontend/i18n
-> packages/web/i18n
```

package名:

```text
@www-template/i18n
-> @app-template/web-i18n
```

### 17.2 scripts/i18n/check-locales.ts更新

`packages/frontend/i18n` や旧web/admin pathを参照している場合は更新する。

新path:

```text
packages/web/i18n
packages/web/lp
packages/web/admin/app
```

UI packageがi18nに依存しないというルールがある場合は維持する。

### 17.3 locale JSON path更新

ESLintやi18n coverageで次を更新する。

```text
packages/web/src/**/*.json              -> packages/web/lp/src/**/*.json
packages/frontend/app/src/**/*.json     -> 削除
packages/frontend/ui/src/**/*.json      -> packages/web/ui/src/**/*.json
packages/admin/app/src/**/*.json        -> packages/web/admin/app/src/**/*.json
```

---

## 18. Phase 15: Backend/TypeSpec周辺更新

### 18.1 Backendは残す

`packages/backend` は削除しない。

ただし、生成物やdocsが旧frontend TS SDKを前提にしている場合は更新する。

確認対象:

```text
scripts/go/gen-backend.sh
scripts/go/build.sh
scripts/go/test.sh
scripts/go/lint.sh
packages/backend/internal/generated
packages/backend/internal/adapter
packages/backend/internal/platform/config
.config/local.toml
.config/local.admin.toml
```

### 18.2 TypeSpecは残す

`packages/typespec` はAPI契約の正として残す。

package名:

```text
@www-template/typespec
-> @app-template/typespec
```

OpenAPI artifactは残す。

```text
packages/typespec/openapi/openapi.json
packages/typespec/openapi/admin.openapi.json
```

Product OpenAPIはBackend Go bindings用に必要なら残す。

Product TS SDKは削除する。

### 18.3 /api/admin policy更新

`lint:api-admin-policy` が旧Product TS SDK pathを参照している場合は更新する。

旧:

```text
packages/frontend/api/src/generated/
```

新方針:

```text
Product TS SDKは存在しないため対象から外す
Admin SDKはpackages/web/admin/api/src/generated/client.tsを確認対象にする
Go bindingsとTypeSpec/OpenAPIは引き続き確認する
```

---

## 19. Phase 16: CI更新

### 19.1 基本方針

CIはNix/devenv経由にする。

現在のようにGitHub ActionsでNode、pnpm、Goを個別setupする方式は廃止する。

### 19.2 CI案

`.github/workflows/ci.yml` を以下の方針にする。

```yaml
name: CI

on:
  push:
    branches:
      - main
      - develop
  pull_request:

jobs:
  verify:
    runs-on: ubuntu-latest
    timeout-minutes: 20

    services:
      postgres:
        image: postgres:18
        env:
          POSTGRES_USER: postgres
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: postgres
        ports:
          - 5432:5432
        options: >-
          --health-cmd "pg_isready -U postgres"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Install Nix
        uses: cachix/install-nix-action@v31
        with:
          github_access_token: ${{ secrets.GITHUB_TOKEN }}

      - name: Install dependencies
        run: nix develop --command pnpm install --frozen-lockfile

      - name: Check formatting
        run: nix develop --command pnpm format:check

      - name: Generate code
        run: nix develop --command pnpm gen

      - name: Lint
        run: nix develop --command pnpm lint

      - name: Type check
        run: nix develop --command pnpm check

      - name: Unit tests
        run: nix develop --command pnpm test:run
        env:
          BACKEND_POSTGRES_TEST_OWNER_URL: postgres://postgres:postgres@localhost:5432/postgres?sslmode=disable

      - name: Codegen drift check
        run: nix develop --command pnpm check:codegen

      - name: Build
        run: nix develop --command pnpm build
```

`devenv shell --` を標準にする場合は、すべて統一する。

```yaml
run: devenv shell -- pnpm lint
```

ただし、その場合CI上でdevenv CLIをどう提供するかを明確にし、検証する。

### 19.3 追加してはいけないCI step

```yaml
- run: flutter analyze
- run: flutter test
- run: flutter build apk
- run: flutter build ios
```

Flutter app本体が存在しないため、これらは今回入れない。

### 19.4 GitHub Actions permissions

必要最小限にする。

推奨:

```yaml
permissions:
  contents: read
```

書き込み権限が必要なstepがない限り追加しない。

---

## 20. Phase 17: Zed設定更新

### 20.1 .zed/tasks.json更新

既存taskがhostの `pnpm` を直接呼んでいる場合、Nix/devenv経由へ変更する。

例:

```json
{
  "label": "check",
  "command": "nix",
  "args": ["develop", "--command", "pnpm", "check"],
  "cwd": "$ZED_WORKTREE_ROOT",
  "use_new_terminal": false,
  "allow_concurrent_runs": false,
  "reveal": "always",
  "hide": "never",
  "save": "all"
}
```

またはdevenv標準なら:

```json
{
  "label": "check",
  "command": "devenv",
  "args": ["shell", "--", "pnpm", "check"],
  "cwd": "$ZED_WORKTREE_ROOT",
  "use_new_terminal": false,
  "allow_concurrent_runs": false,
  "reveal": "always",
  "hide": "never",
  "save": "all"
}
```

どちらかに統一する。

### 20.2 旧app task削除

削除する。

```text
dev:app
```

追加しない。

```text
flutter:run
flutter:analyze
flutter:test
flutter:build
```

Flutter SDKをdevenvに入れた場合のみ、任意で次を追加してよい。

```json
{
  "label": "doctor:flutter",
  "command": "nix",
  "args": ["develop", "--command", "pnpm", "doctor:flutter"],
  "cwd": "$ZED_WORKTREE_ROOT"
}
```

ただし、Flutter SDKを今回入れない場合は追加しない。

### 20.3 .zed/settings.json更新

Dev Container前提の設定があれば削除する。

path excludeへ追加してよいもの:

```json
{
  "file_scan_exclusions": ["**/.cache", "**/.devenv", "**/.direnv"]
}
```

Dart/Flutter language server設定は今回追加しない。

---

## 21. Phase 18: README更新

### 21.1 READMEの目的

READMEは新しいテンプレート利用者が読む文書である。

旧www-templateや旧Svelte app時代の移行説明を残さない。

### 21.2 READMEに書くこと

```text
# app-template

Flutterアプリ構築テンプレートの基盤リポジトリである。
現時点ではFlutterアプリ本体はまだ含めない。
Flutterアプリの構成、Dart workspace、lint、CI、Android/iOS運用は別途ルール策定後に追加する。

現在含むもの:
  - Web LP
  - Web UI package
  - Web i18n package
  - Web Admin
  - Go backend
  - TypeSpec API contract
  - Docker Composeによるローカルインフラ
  - Nix/devenvによる開発環境
```

### 21.3 READMEの構成案

```md
# app-template

## 概要

## 現在のスコープ

## 今回まだ含めないもの

## 技術スタック

## リポジトリ構成

## 開発環境

### Nixのインストール

### devenvの起動

### 依存インストール

## Docker Compose

### インフラ起動

### runtime service

## コマンド一覧

## 検証順

## API契約と生成物

## Web構成

### Web LP

### Web UI

### Web i18n

### Web Admin

## Backend構成

## Flutter app追加方針

## CI

## Security / supply-chain
```

### 21.4 READMEから消すこと

以下の表現を残さない。

```text
www-template
Dev Container
Open in Container
/workspaces/www-template
packages/frontend/app
packages/frontend/domain
packages/frontend/api
@www-template/app
@www-template/domain
@www-template/api
```

### 21.5 Flutter app追加方針の書き方

READMEには、今回Flutter app本体がないことを明記する。

例:

```md
## Flutter app追加方針

このリポジトリはFlutterアプリ構築テンプレートの基盤です。
ただし、Flutterアプリ本体はまだ含めていません。
Flutterアプリのディレクトリ構成、Dart workspace、lint、test、build、CI、Android/iOS運用ルールは、別途プロジェクト運用ルールとして定義してから追加します。
```

この節で具体的なFlutter architecture案を書かない。

---

## 22. Phase 19: AGENTS.md更新

### 22.1 AGENTS.mdの目的

AGENTS.mdはCodexや他Agentが作業する際のルールである。

今回の移行後は、Dev Containerや旧frontend app前提を完全に消す。

### 22.2 削除する記述

```text
scripts/devcontainer/run.sh
Dev Container
packages/frontend/app
packages/frontend/domain
packages/frontend/api
packages/frontend/ui
@www-template/*
dev:app as Svelte app
```

### 22.3 追加する記述

```text
- 検証コマンドはNix/devenv環境で実行する
- Web LPはpackages/web/lp
- Web UIはpackages/web/ui
- Web i18nはpackages/web/i18n
- Adminはpackages/web/admin/*
- Backendはpackages/backend
- API契約はpackages/typespec
- Flutterアプリ本体はまだ存在しない
- Flutter運用ルールが定義されるまでpackages/app、pubspec.yaml、Dart workspaceを追加しない
```

### 22.4 Commands更新案

```md
## Commands

- Install: `nix develop --command pnpm install`
- Generate all contracts: `nix develop --command pnpm gen`
- Typecheck: `nix develop --command pnpm check`
- Lint: `nix develop --command pnpm lint`
- Test: `nix develop --command pnpm test:run`
- Build: `nix develop --command pnpm build`
- Dev Web: `nix develop --command pnpm dev:web`
- Dev Admin: `nix develop --command pnpm dev:admin`
- Dev Product API: `nix develop --command pnpm dev:server`
- Dev Admin API: `nix develop --command pnpm dev:admin-server`
```

`devenv shell --` を採用する場合は、すべてそちらへ統一する。

---

## 23. Phase 20: CONTRIBUTING / CODING_STANDARDS / .opencode / openspec更新

### 23.1 CONTRIBUTING.md

次を更新する。

```text
- Dev Container手順を削除
- Nix/devenv手順へ変更
- 旧frontend pathを削除
- 旧Svelte appの検証手順を削除
- Flutter appは未追加であることを明記
```

### 23.2 CODING_STANDARDS.md

次を更新する。

```text
- packages/frontend/app/domain/api 前提を削除
- Web LP/UI/i18n/Adminの責務へ更新
- Flutter/Dart規約はまだ書かない
```

### 23.3 .opencode

`.opencode` 配下に旧frontend app/domain/api前提のagentやskillがある場合は更新または削除する。

方針:

```text
- 旧Svelte app専用agentは削除
- Web LP/UI/Adminに使えるagentならscopeを更新
- Flutter app agentはまだ作らない
- packages/appを前提にしたagentは作らない
```

確認コマンド:

```sh
git grep -n "packages/frontend" .opencode || true
git grep -n "@www-template" .opencode || true
git grep -n "Dev Container" .opencode || true
```

### 23.4 openspec

`openspec` は既存仕様やarchiveを含む。

旧frontend app/domain/apiやwww-template由来の記述がある場合、以下のいずれかを選ぶ。

```text
A. 現在のテンプレート利用者に不要なarchiveなら削除する
B. Backend/TypeSpec/Web Adminにまだ有用なら新pathへ更新する
```

禁止:

```text
- 旧構造の説明をarchiveだからという理由だけで残す
- git grepで旧pathが残る状態にする
```

今回のテンプレートでは、過去のwww-template移行履歴よりも、現在の正しい構成を優先する。

---

## 24. Phase 21: .config更新

### 24.1 www-template表記の削除

`.config` 配下で `www-template` を参照している場合は更新する。

推奨名:

```text
app_template
```

`app-template` はファイル名やdisplay nameにはよいが、DB名やDB userには `app_template` を推奨する。

### 24.2 local.toml / local.admin.toml

確認する。

```sh
git grep -n "www-template" .config || true
git grep -n "packages/frontend" .config || true
```

更新後、backend testやmigrationが通ることを確認する。

---

## 25. Phase 22: security scripts更新

### 25.1 scripts/security

`www-template` や旧frontend pathがあれば更新する。

```sh
git grep -n "www-template" scripts/security || true
git grep -n "packages/frontend" scripts/security || true
```

### 25.2 gitleaks/osv/govulncheck

既存のsecurity lintは維持する。

`pnpm lint` から外さない。

### 25.3 pnpm supply-chain hardening

`pnpm-workspace.yaml` の以下を弱めない。

```text
minimumReleaseAge
strictDepBuilds
trustPolicy
blockExoticSubdeps
verifyStoreIntegrity
strictStorePkgContentCheck
```

---

## 26. Phase 23: 最終検証

### 26.1 Nix/devenv検証

```sh
nix flake check
nix develop --command node --version
nix develop --command pnpm --version
nix develop --command go version
```

`devenv shell --` を標準にした場合:

```sh
devenv shell -- node --version
devenv shell -- pnpm --version
devenv shell -- go version
```

### 26.2 pnpm検証

```sh
nix develop --command pnpm install --frozen-lockfile
nix develop --command pnpm gen
nix develop --command pnpm format:check
nix develop --command pnpm lint
nix develop --command pnpm check
nix develop --command pnpm test:run
nix develop --command pnpm check:codegen
nix develop --command pnpm build
```

またはdevenv標準なら:

```sh
devenv shell -- pnpm install --frozen-lockfile
devenv shell -- pnpm gen
devenv shell -- pnpm format:check
devenv shell -- pnpm lint
devenv shell -- pnpm check
devenv shell -- pnpm test:run
devenv shell -- pnpm check:codegen
devenv shell -- pnpm build
```

### 26.3 Compose検証

```sh
docker compose config
docker compose up -d postgres valkey opensearch minio mailpit
docker compose ps
docker compose down
```

SigNozをprofile化した場合:

```sh
docker compose --profile observability config
docker compose --profile observability up -d
docker compose --profile observability down
```

### 26.4 filesystem完了条件

すべて成功すること。

```sh
test ! -d packages/frontend
test ! -d packages/app
test ! -f pubspec.yaml
test ! -d .devcontainer
test ! -f scripts/devcontainer/run.sh
test -f devenv.nix
test -f flake.nix
test -f compose.yaml
test -d packages/web/lp
test -d packages/web/ui
test -d packages/web/i18n
test -d packages/web/admin/app
test -d packages/web/admin/api
test -d packages/web/admin/domain
```

### 26.5 legacy grep完了条件

原則としてすべてmatchなしにする。

```sh
git grep -n "packages/frontend" && exit 1 || true
git grep -n "@www-template" && exit 1 || true
git grep -n "www-template" && exit 1 || true
git grep -n "scripts/devcontainer" && exit 1 || true
git grep -n "Dev Container" && exit 1 || true
git grep -n ".devcontainer" && exit 1 || true
git grep -n "@www-template/app" && exit 1 || true
git grep -n "@www-template/domain" && exit 1 || true
git grep -n "@www-template/api" && exit 1 || true
```

ただし、`pnpm-lock.yaml` や生成物に一時的に旧名が残る場合は、依存更新漏れとして扱い、根本修正する。

### 26.6 Flutterを入れていないことの確認

必ず確認する。

```sh
test ! -d packages/app
test ! -f pubspec.yaml
! git grep -n "flutter create"
! git grep -n "flutter analyze"
! git grep -n "flutter test"
! git grep -n "flutter build apk"
! git grep -n "flutter build ios"
```

例外:

`README` の「今回まだ含めないもの」などにFlutter command名を書くとgrepに引っかかる。したがって、完了条件にするならREADMEやAGENTSにも具体的なFlutter command名を残さない。

推奨は、ドキュメントでは「Flutterの標準検証は未導入」と書き、具体command文字列を残さないこと。

---

## 27. Phase 24: 最終差分レビュー観点

### 27.1 削除漏れ確認

以下が残っていたら失敗。

```text
packages/frontend
packages/admin
.devcontainer
scripts/devcontainer
@www-template/* imports
旧Svelte app用 dev:app/build:app/test project
旧Product TS SDK
```

### 27.2 互換性残し確認

以下があれば削除する。

```text
旧pathへのsymlink
旧package名のpackage.json
deprecated wrapper
compat alias
legacy import alias
旧script alias
```

### 27.3 docs整合性確認

README、AGENTS、CONTRIBUTING、CODING_STANDARDSが同じ構成を説明していること。

矛盾例:

```text
READMEはNixと言っているがAGENTSはDev Containerと言っている
package.jsonは@app-templateだがREADMEは@www-templateと言っている
pnpm-workspaceはpackages/web/lpだがtsconfigはpackages/webを見ている
CIはNixだがZed taskはhost pnpm前提
```

### 27.4 CI再現性確認

GitHub Actionsがローカルと同じコマンド経路を使っていること。

```text
local: nix develop --command pnpm check
CI:    nix develop --command pnpm check
```

または

```text
local: devenv shell -- pnpm check
CI:    devenv shell -- pnpm check
```

混在させない。

---

## 28. 想定されるハマりどころと対処

### 28.1 git mvでpackages/webをpackages/web/lpに移せない

直接移動すると入れ子衝突が起きる。

対処:

```sh
git mv packages/web packages/_web-lp-tmp
mkdir -p packages/web
git mv packages/_web-lp-tmp packages/web/lp
```

### 28.2 tsconfigのextendsが壊れる

移動後に深さが変わる。

対処:

```sh
git grep -n "tsconfig.base.json" packages/web
```

各packageで `pnpm --filter <package> check` を実行して確認する。

### 28.3 SvelteKit generated filesが旧pathを参照する

`.svelte-kit` は生成物なので削除して再生成する。

```sh
find packages -name .svelte-kit -type d -prune -exec rm -rf {} +
nix develop --command pnpm check
```

### 28.4 pnpm lockfileに旧importerが残る

対処:

```sh
nix develop --command pnpm install
```

その後確認:

```sh
grep -n "packages/frontend\|@www-template\|packages/admin" pnpm-lock.yaml && exit 1 || true
```

ただし、`packages/web/admin` は新pathとして許可する。

### 28.5 ESLint configが大きく壊れる

`eslint.config.js` は既存の旧frontend概念が多い。

対処方針:

```text
- 旧frontend app/domain/api関連を全削除
- webLp/webUi/webI18n/webAdmin*の定数へ再整理
- 旧名の変数を残さない
- ruleを無効化して通さない
```

### 28.6 OpenSpec archiveが旧pathを大量に持っている

今回のテンプレートでは旧履歴を残す価値より、テンプレート利用者にノイズを残さない価値を優先する。

対処:

```text
- 不要なarchiveは削除
- 残すなら新構成へ更新
- grep完了条件を満たす
```

### 28.7 Nixで特定versionが見つからない

Node/Go/pnpmなどで既存versionがnixpkgsにない場合、勝手に近いversionへ変更しない。

対処:

```text
1. flakeでpinするnixpkgsを確認する
2. 利用可能なattributeを確認する
3. package.json engines、README、CIと整合するversionにする
4. どうしても同じversionを再現できない場合は、変更理由を最終報告に明記する
```

ただし、Homebrewやグローバルinstallへ逃げない。

### 28.8 Flutter SDKを入れるとNixが重くなる

今回Flutter app本体は作らない。

対処:

```text
- Flutter SDKをdevenvから外してよい
- ただしREADMEに「Flutter app本体とFlutter toolchain確定は後続の運用ルール策定で扱う」と書く
- packages/appやpubspec.yamlは作らない
```

---

## 29. 最終報告フォーマット

Codexは作業完了時に、以下の形式で報告する。

````md
## 実施内容

- Dev Containerを撤去した
- Nix/devenvを追加した
- Composeをruntime/infra用途へ再配置した
- Web群をpackages/web配下へ再配置した
- 旧Svelte app/domain/api層を削除した
- package scopeを@app-templateへ更新した
- lint/test/build/codegen/CI/docsを新構成へ更新した

## 削除した主な旧構造

- packages/frontend/app
- packages/frontend/domain
- packages/frontend/api
- .devcontainer
- scripts/devcontainer/run.sh
- @www-template/\* imports

## 残した主な構造

- packages/web/lp
- packages/web/ui
- packages/web/i18n
- packages/web/admin/\*
- packages/backend
- packages/typespec
- compose.yaml

## Flutterに関する扱い

- Flutterアプリ本体は追加していない
- packages/appは存在しない
- root pubspec.yamlは存在しない
- Flutter lint/test/build/CIは追加していない
- 必要に応じてFlutter toolchainの準備だけをNix側に留めた

## 実行した検証

```sh
nix flake check
nix develop --command pnpm install --frozen-lockfile
nix develop --command pnpm gen
nix develop --command pnpm format:check
nix develop --command pnpm lint
nix develop --command pnpm check
nix develop --command pnpm test:run
nix develop --command pnpm check:codegen
nix develop --command pnpm build
docker compose config
```
````

## 残存確認

```sh
test ! -d packages/frontend
test ! -d packages/app
test ! -f pubspec.yaml
test ! -d .devcontainer
git grep -n "@www-template" && exit 1 || true
git grep -n "packages/frontend" && exit 1 || true
git grep -n "Dev Container" && exit 1 || true
```

## 注意点

- 未解決の検証失敗がある場合は、該当コマンド、エラー、原因、対応状況を明記する
- Flutter app追加は別PRで扱う

````

---

## 30. 受け入れ条件チェックリスト

### 30.1 ファイル構造

- [ ] `packages/frontend` が存在しない
- [ ] `packages/app` が存在しない
- [ ] root `pubspec.yaml` が存在しない
- [ ] `.devcontainer` が存在しない
- [ ] `scripts/devcontainer/run.sh` が存在しない
- [ ] `devenv.nix` が存在する
- [ ] `flake.nix` が存在する
- [ ] `compose.yaml` が存在する
- [ ] `packages/web/lp` が存在する
- [ ] `packages/web/ui` が存在する
- [ ] `packages/web/i18n` が存在する
- [ ] `packages/web/admin/app` が存在する
- [ ] `packages/web/admin/api` が存在する
- [ ] `packages/web/admin/domain` が存在する
- [ ] `packages/backend` が存在する
- [ ] `packages/typespec` が存在する

### 30.2 package / import

- [ ] root package名が `app-template`
- [ ] package scopeが `@app-template/*`
- [ ] `@www-template/*` が残っていない
- [ ] `@www-template/app` が残っていない
- [ ] `@www-template/domain` が残っていない
- [ ] `@www-template/api` が残っていない
- [ ] `@app-template/web-lp` が使われている
- [ ] `@app-template/web-ui` が使われている
- [ ] `@app-template/web-i18n` が使われている
- [ ] `@app-template/web-admin-*` が使われている

### 30.3 scripts

- [ ] `dev:app` が存在しない
- [ ] `build:app` が存在しない
- [ ] `check` が旧frontend app/domain/apiに依存していない
- [ ] `lint` が旧frontend app/domain/apiに依存していない
- [ ] `test:run` が旧frontend appに依存していない
- [ ] `build` が旧Svelte appに依存していない
- [ ] `gen` がProduct TS SDKを生成していない
- [ ] Admin SDK生成先が `packages/web/admin/api` になっている

### 30.4 Nix/devenv

- [ ] `nix flake check` が通る
- [ ] `nix develop --command pnpm --version` が通る
- [ ] `nix develop --command go version` が通る
- [ ] CIがNix/devenv経由になっている
- [ ] READMEがNix/devenv前提になっている
- [ ] AGENTSがNix/devenv前提になっている

### 30.5 Compose

- [ ] Composeがrootまたは明確なcompose配下に移動している
- [ ] Dev Container用の記述がない
- [ ] `workspace` serviceがruntime用途へ変更されている、または `runtime` にrenameされている
- [ ] `/workspaces/www-template` が残っていない
- [ ] postgres/valkey/opensearch/minio/mailpitが残っている
- [ ] SigNoz関連serviceが残っている、またはprofile化されている
- [ ] `docker compose config` が通る

### 30.6 Docs / Agents

- [ ] READMEにDev Container推奨が残っていない
- [ ] READMEに旧frontend app/domain/api構成が残っていない
- [ ] AGENTSにDev Container前提が残っていない
- [ ] AGENTSに旧frontend app/domain/api責務が残っていない
- [ ] CONTRIBUTINGがNix/devenv前提になっている
- [ ] CODING_STANDARDSが新構成と矛盾していない
- [ ] `.opencode` に旧frontend app/domain/api前提が残っていない

### 30.7 Flutterスコープ管理

- [ ] Flutter projectを作っていない
- [ ] `packages/app` を作っていない
- [ ] root `pubspec.yaml` を作っていない
- [ ] Dart workspaceを作っていない
- [ ] Flutter lint/test/build/CIを追加していない
- [ ] Flutter architecture案をREADMEやAGENTSに書いていない

---

## 31. 作業完了の定義

この作業は、以下がすべて満たされたときに完了とする。

```text
- Svelte app時代のProduct app層が完全に消えている
- packages/frontendが存在しない
- Dev Containerが完全に消えている
- Nix/devenvが開発環境の正になっている
- Composeはinfra/runtime用途として残っている
- Web LP/UI/i18n/Adminがpackages/web配下に整理されている
- BackendとTypeSpecが新構成で検証可能である
- CIとローカル検証が同じNix/devenv経路を使う
- Flutter app本体はまだ存在しない
- Flutterを後から追加できる空の基盤になっている
````
