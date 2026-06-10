#!/usr/bin/env bash

set -euo pipefail

# Step 1: repository root を固定し、どの作業ディレクトリから実行しても同じ tracked file を検査する。
repo_root="$(git rev-parse --show-toplevel)"
cd "${repo_root}"

# Step 2: OpenSpec の変更説明は過去構造を引用するため対象外にし、active code/docs/config は検査対象に残す。
files=()
while IFS= read -r file; do
  files+=("${file}")
done < <(
  git ls-files \
    ':!:openspec/**' \
    ':!:scripts/lint/no-legacy-paths.sh' \
    ':!:packages/web/lp/public/**/*.svg' \
    ':!:pnpm-lock.yaml'
)

# Step 3: 削除済み Product Svelte app と旧 Admin package tree の識別子を定義する。
patterns=(
  'packages/frontend'
  'packages/admin'
  '@app-template/app'
  '@app-template/domain'
  '@app-template/api'
  '@app-template/admin-app'
  '@app-template/admin-domain'
  '@app-template/admin-api'
  '@app-template/ui'
  '@app-template/i18n'
  'dev:app'
  'app.localhost:5174'
)

# Step 4: 旧識別子が残る file/line を全部表示してから失敗し、最初の 1 件だけで隠れないようにする。
found=0
for pattern in "${patterns[@]}"; do
  if git grep -n -F "${pattern}" -- "${files[@]}"; then
    found=1
  fi
done

if [ "${found}" -ne 0 ]; then
  printf '%s\n' 'legacy Product frontend or old package identifier remains in active files.' >&2
  exit 1
fi
