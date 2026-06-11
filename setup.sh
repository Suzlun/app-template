#!/usr/bin/env bash

set -euo pipefail

# Step 1: script の配置場所を repository root として固定し、どこから実行しても同じ path を参照できるようにする。
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$SCRIPT_DIR"

# Step 2: 引数で上書きできる初期動作を定義し、対話確認・dry-run・bootstrap 範囲を後続処理から参照できるようにする。
DRY_RUN=0
ASSUME_YES=0
SKIP_DOCKER=0
SKIP_BOOTSTRAP=0
SKIP_GEN=0

# Step 3: platform 判定結果を 1 度だけ保持し、Nix と Docker の導入分岐を OS ごとに安定して切り替える。
OS_NAME="$(uname -s)"
ARCH_NAME="$(uname -m)"
PACKAGE_MANAGER=""

# Step 4: repository root を shell command に安全に埋め込める形へ escape し、`bash -lc` 経由でも誤解釈を避ける。
REPO_ROOT_SHELL="$(printf '%q' "$REPO_ROOT")"

usage() {
  cat <<'EOF'
Usage: ./setup.sh [options]

Options:
  --yes              すべての導入確認に自動で yes を返します
  --dry-run          実行せず、何を行うかだけを表示します
  --skip-docker      Docker / Docker Compose の確認と導入を行いません
  --skip-bootstrap   `pnpm install` と `pnpm gen` を実行しません
  --skip-gen         bootstrap 時の `pnpm gen` を省略します
  --help             このヘルプを表示します
EOF
}

log() {
  # Step 5: 通常の進捗は 1 箇所で prefix 付き表示に統一し、setup のどの段階かを読み手が見失わないようにする。
  printf '[setup] %s\n' "$*"
}

warn() {
  # Step 6: 継続可能だが注意が必要な状態は stderr へ分離し、失敗ではない警告だけを後から追えるようにする。
  printf '[setup] WARN: %s\n' "$*" >&2
}

die() {
  # Step 7: 続行不能な状態は即座に終了し、どの前提が満たされなかったかを明示して誤った後続実行を防ぐ。
  printf '[setup] ERROR: %s\n' "$*" >&2
  exit 1
}

command_exists() {
  # Step 8: command の存在確認を共通化し、install 判定の分岐が command 名の typo に左右されないようにする。
  command -v "$1" >/dev/null 2>&1
}

print_command() {
  # Step 9: dry-run 表示用の command 整形を共通化し、引数に空白が含まれても見た目と実行内容がずれないようにする。
  local arg

  printf '[setup] DRY-RUN:'
  for arg in "$@"; do
    printf ' %q' "$arg"
  done
  printf '\n'
}

run() {
  # Step 10: 直接実行する command はこの関数を通し、dry-run と通常実行で分岐を 1 箇所に閉じ込める。
  if [ "$DRY_RUN" -eq 1 ]; then
    print_command "$@"
    return 0
  fi

  "$@"
}

run_shell() {
  # Step 11: pipe や `cd && ...` が必要な command は `bash -lc` に集約し、呼び出し側で quote をばらけさせない。
  local command_text="$1"

  if [ "$DRY_RUN" -eq 1 ]; then
    printf '[setup] DRY-RUN: bash -lc %q\n' "$command_text"
    return 0
  fi

  bash -lc "$command_text"
}

confirm() {
  # Step 12: システム導入のような副作用が大きい操作だけ対話確認を入れ、`--yes` では無人実行できるようにする。
  local prompt="$1"
  local answer

  if [ "$ASSUME_YES" -eq 1 ] || [ "$DRY_RUN" -eq 1 ]; then
    return 0
  fi

  if [ ! -t 0 ]; then
    die "対話確認が必要です。無人実行する場合は --yes を指定してください。"
  fi

  printf '[setup] %s [y/N] ' "$prompt"
  read -r answer

  case "$answer" in
    y | Y | yes | YES | Yes)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

detect_package_manager() {
  # Step 13: host 側 package manager を 1 度だけ判定し、curl や Docker の不足時に同じ導入経路を再利用する。
  if [ -n "$PACKAGE_MANAGER" ]; then
    return 0
  fi

  if command_exists brew; then
    PACKAGE_MANAGER="brew"
  elif command_exists apt-get; then
    PACKAGE_MANAGER="apt-get"
  elif command_exists dnf; then
    PACKAGE_MANAGER="dnf"
  elif command_exists yum; then
    PACKAGE_MANAGER="yum"
  elif command_exists pacman; then
    PACKAGE_MANAGER="pacman"
  else
    PACKAGE_MANAGER="unknown"
  fi
}

ensure_brew_shellenv() {
  # Step 14: Homebrew が既にある場合は shellenv を読み込み、install 直後でも同じ shell から brew command を使えるようにする。
  if [ -x /opt/homebrew/bin/brew ]; then
    # shellcheck disable=SC2046
    eval "$(/opt/homebrew/bin/brew shellenv)"
    return 0
  fi

  if [ -x /usr/local/bin/brew ]; then
    # shellcheck disable=SC2046
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

install_homebrew() {
  # Step 15: macOS で brew が無い場合だけ公式 installer を実行し、Docker 補助 package の導入経路を確保する。
  if command_exists brew; then
    ensure_brew_shellenv
    return 0
  fi

  [ "$OS_NAME" = "Darwin" ] || die "Homebrew 自動導入は macOS のみ対応です。"

  confirm "Homebrew が見つかりません。公式 installer で導入しますか?" || die "Homebrew 導入が拒否されました。"
  run_shell '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
  ensure_brew_shellenv
  command_exists brew || die "Homebrew の導入後も brew command が見つかりません。"
}

install_with_package_manager() {
  # Step 16: curl や docker のような host package は package manager ごとに分岐し、導入 command を呼び出し元から隠蔽する。
  detect_package_manager

  case "$PACKAGE_MANAGER" in
    brew)
      run brew install "$@"
      ;;
    apt-get)
      run sudo apt-get update
      run sudo apt-get install -y "$@"
      ;;
    dnf)
      run sudo dnf install -y "$@"
      ;;
    yum)
      run sudo yum install -y "$@"
      ;;
    pacman)
      run sudo pacman -Sy --noconfirm "$@"
      ;;
    *)
      die "対応する package manager が見つからないため、必要 package（$*）を自動導入できません。"
      ;;
  esac
}

ensure_download_prerequisites() {
  # Step 17: Nix installer と Homebrew installer が依存する curl を先に確認し、欠けていれば最小限だけ先に補う。
  if command_exists curl; then
    return 0
  fi

  [ "$OS_NAME" = "Darwin" ] && install_homebrew
  confirm "curl が見つかりません。導入しますか?" || die "curl が必要です。"
  install_with_package_manager curl
  command_exists curl || die "curl の導入後も command が見つかりません。"
}

source_nix_environment() {
  # Step 18: Nix 導入直後でも current shell から `nix` と `devenv` を使えるよう、代表的な profile script を順に読み込む。
  export PATH="$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH"

  if [ -r /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
    # shellcheck disable=SC1091
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  fi

  if [ -r "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
    # shellcheck disable=SC1090
    . "$HOME/.nix-profile/etc/profile.d/nix.sh"
  fi
}

ensure_nix_config() {
  # Step 19: `nix-command` と `flakes` を毎回フラグ指定しなくて済むよう、user config に experimental feature を明示する。
  local config_dir="$HOME/.config/nix"
  local config_file="$config_dir/nix.conf"
  local config_line='experimental-features = nix-command flakes'

  if [ "$DRY_RUN" -eq 1 ]; then
    if [ -f "$config_file" ] && grep -Fqx "$config_line" "$config_file"; then
      log "Nix experimental feature 設定は既に存在します。"
    else
      printf '[setup] DRY-RUN: append %q to %q\n' "$config_line" "$config_file"
    fi
    return 0
  fi

  mkdir -p "$config_dir"
  touch "$config_file"

  if ! grep -Fqx "$config_line" "$config_file"; then
    printf '%s\n' "$config_line" >>"$config_file"
  fi
}

ensure_nix() {
  # Step 20: pinned toolchain の入口である Nix を確認し、無ければ公式 installer を実行して以後の setup を続行可能にする。
  source_nix_environment

  if command_exists nix; then
    ensure_nix_config
    return 0
  fi

  ensure_download_prerequisites
  confirm "Nix が見つかりません。公式 installer で導入しますか?" || die "Nix 導入が拒否されました。"
  run_shell 'curl -fsSL https://nixos.org/nix/install | sh -s -- --daemon'

  if [ "$DRY_RUN" -eq 1 ]; then
    return 0
  fi

  source_nix_environment
  command_exists nix || die "Nix の導入後も nix command が見つかりません。新しい shell を開いて再実行してください。"
  ensure_nix_config
}

ensure_devenv() {
  # Step 21: repository が前提とする `devenv shell -- ...` を使えるようにし、host Node.js や host pnpm 依存を排除する。
  source_nix_environment

  if command_exists devenv; then
    return 0
  fi

  confirm "devenv が見つかりません。Nix profile に追加しますか?" || die "devenv 導入が拒否されました。"
  run_shell 'nix profile install nixpkgs#devenv'

  if [ "$DRY_RUN" -eq 1 ]; then
    return 0
  fi

  source_nix_environment
  command_exists devenv || die "devenv の導入後も command が見つかりません。"
}

ensure_docker_compose_subcommand() {
  # Step 22: repository は `docker compose` を前提にしているため、standalone `docker-compose` しか無い環境でも plugin path を補完する。
  local plugin_dir="$HOME/.docker/cli-plugins"
  local standalone_path=""

  if command_exists docker && docker compose version >/dev/null 2>&1; then
    return 0
  fi

  if command_exists docker-compose; then
    standalone_path="$(command -v docker-compose)"
    run mkdir -p "$plugin_dir"
    run ln -sf "$standalone_path" "$plugin_dir/docker-compose"
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    return 0
  fi

  command_exists docker && docker compose version >/dev/null 2>&1 || die "`docker compose` が利用できません。"
}

docker_compose_ready() {
  # Step 23: `docker compose` subcommand の有無だけでなく daemon 応答まで確認し、後続の `compose config` が途中で落ちない状態だけを成功扱いにする。
  command_exists docker && docker compose version >/dev/null 2>&1 && docker info >/dev/null 2>&1
}

ensure_docker_macos() {
  # Step 24: macOS は Homebrew + Colima を既定経路とし、Docker Desktop 前提を置かずに CLI / Compose / daemon を自動でそろえる。
  ensure_brew_shellenv

  if ! command_exists docker; then
    confirm "Docker CLI が見つかりません。Homebrew で導入しますか?" || die "Docker CLI 導入が拒否されました。"
    run brew install docker
  fi

  if ! command_exists docker-compose && ! docker compose version >/dev/null 2>&1; then
    confirm "Docker Compose が見つかりません。Homebrew で導入しますか?" || die "Docker Compose 導入が拒否されました。"
    run brew install docker-compose
  fi

  if ! command_exists colima; then
    confirm "Docker daemon 用の Colima が見つかりません。Homebrew で導入しますか?" || die "Colima 導入が拒否されました。"
    run brew install colima
  fi

  ensure_docker_compose_subcommand

  if ! docker info >/dev/null 2>&1; then
    confirm "Docker daemon が起動していません。Colima を起動しますか?" || die "Docker daemon が起動していません。"
    run colima start
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    return 0
  fi

  ensure_docker_compose_subcommand
}

ensure_docker_linux() {
  # Step 25: Linux は distro ごとの差分が大きいため、まず主要 package manager だけ best-effort で導入し、不明環境は明示的に止める。
  detect_package_manager

  if ! command_exists docker; then
    confirm "Docker が見つかりません。host package manager で導入しますか?" || die "Docker 導入が拒否されました。"

    case "$PACKAGE_MANAGER" in
      apt-get)
        install_with_package_manager docker.io docker-compose-plugin
        ;;
      dnf)
        install_with_package_manager docker docker-compose-plugin
        ;;
      yum)
        install_with_package_manager docker docker-compose-plugin
        ;;
      pacman)
        install_with_package_manager docker docker-compose
        ;;
      *)
        die "この Linux 環境の Docker 自動導入にはまだ対応していません。Docker Engine / Docker Compose を事前に用意してください。"
        ;;
    esac
  fi

  if command_exists systemctl; then
    # Step 26: systemd 環境では docker service を起動し、daemon 未起動のまま compose が失敗する状態を避ける。
    run sudo systemctl enable --now docker
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    return 0
  fi

  ensure_docker_compose_subcommand

  if ! docker info >/dev/null 2>&1; then
    warn "Docker daemon へ接続できません。必要に応じて service 起動、docker group 追加、再ログインを行ってください。"
    die "Docker daemon が利用可能になるまで setup を継続できません。"
  fi
}

ensure_docker() {
  # Step 27: Compose runtime は標準開発経路の一部なので、skip 指定が無い限り platform ごとの導入関数を通して整える。
  if docker_compose_ready; then
    return 0
  fi

  case "$OS_NAME" in
    Darwin)
      install_homebrew
      ensure_docker_macos
      ;;
    Linux)
      ensure_docker_linux
      ;;
    *)
      die "Docker 自動導入は macOS / Linux だけを対象にしています。"
      ;;
  esac

  docker_compose_ready || die "Docker / Docker Compose の準備が完了しませんでした。"
}

verify_nix_toolchain() {
  # Step 28: install 直後に `nix` と `devenv` の基本 command を実行し、path だけ通って中身が壊れている状態を早期に検出する。
  run_shell "cd $REPO_ROOT_SHELL && nix flake metadata . >/dev/null"
  run_shell "cd $REPO_ROOT_SHELL && devenv --version >/dev/null"
  run_shell "cd $REPO_ROOT_SHELL && devenv shell -- pnpm --version"
  run_shell "cd $REPO_ROOT_SHELL && devenv shell -- go version"
}

bootstrap_repository() {
  # Step 29: repository 依存と generated artifact を setup 中にそろえ、clone 直後でも `pnpm` workflow に入れる状態まで仕上げる。
  run_shell "cd $REPO_ROOT_SHELL && devenv shell -- pnpm install --frozen-lockfile"

  if [ "$SKIP_GEN" -eq 0 ]; then
    run_shell "cd $REPO_ROOT_SHELL && devenv shell -- pnpm gen"
  fi

  if [ "$SKIP_DOCKER" -eq 0 ]; then
    # Step 30: Docker runtime の command path も setup 中に検証し、compose file の syntax 不整合を初手で検出する。
    run_shell "cd $REPO_ROOT_SHELL && docker compose config >/dev/null"
  fi
}

parse_args() {
  # Step 31: CLI option を先に正規化し、以後の関数が global flag を見るだけで分岐できるようにする。
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --yes)
        ASSUME_YES=1
        ;;
      --dry-run)
        DRY_RUN=1
        ;;
      --skip-docker)
        SKIP_DOCKER=1
        ;;
      --skip-bootstrap)
        SKIP_BOOTSTRAP=1
        ;;
      --skip-gen)
        SKIP_GEN=1
        ;;
      --help | -h)
        usage
        exit 0
        ;;
      *)
        die "未知の引数です: $1"
        ;;
    esac
    shift
  done
}

main() {
  # Step 32: setup 全体の順序を 1 箇所へ集約し、Nix 導入前に devenv を触るような逆順実行を防ぐ。
  parse_args "$@"

  log "platform: ${OS_NAME} ${ARCH_NAME}"
  ensure_download_prerequisites
  ensure_nix
  ensure_devenv
  verify_nix_toolchain

  if [ "$SKIP_DOCKER" -eq 0 ]; then
    ensure_docker
  else
    log "Docker / Docker Compose の確認は --skip-docker により省略します。"
  fi

  if [ "$SKIP_BOOTSTRAP" -eq 0 ]; then
    bootstrap_repository
  else
    log "repository bootstrap は --skip-bootstrap により省略します。"
  fi

  # Step 33: 完了時に次の導線を明示し、setup 後に何をすればよいかを利用者が README を開き直さず把握できるようにする。
  log "完了しました。次に使う主な command:"
  log "  devenv shell -- pnpm infra:up"
  log "  devenv shell -- pnpm check"
  log "  devenv shell -- pnpm migrate:up"
  log "  devenv shell -- pnpm dev:all"
}

main "$@"
