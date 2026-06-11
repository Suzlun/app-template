{ pkgs, lib, ... }:

let
  nodejs = if pkgs ? nodejs_24 then pkgs.nodejs_24 else pkgs.nodejs;
  go = if pkgs ? go_1_26 then pkgs.go_1_26 else pkgs.go;
  postgresql = if pkgs ? postgresql_18 then pkgs.postgresql_18 else pkgs.postgresql;
  openspecVersion = "1.3.1";
  pnpmVersion = "11.5.1";
  corepackBin = "${nodejs}/bin/corepack";

  openspec = pkgs.writeShellApplication {
    name = "openspec";
    runtimeInputs = [
      nodejs
    ];
    text = ''
      export npm_config_yes=true
      exec npm exec --yes --package "@fission-ai/openspec@${openspecVersion}" -- openspec "$@"
    '';
  };
in
{
  packages = [
    nodejs
    go
    postgresql
    pkgs.bash
    pkgs.curl
    pkgs.docker-compose
    pkgs.git
    pkgs.gnumake
    pkgs.jq
    pkgs.openssl
    pkgs.pkg-config
    pkgs.redis
    pkgs.ripgrep
    pkgs.wget
    openspec
  ];

  env = {
    AGENT_BROWSER_EXECUTABLE_PATH = lib.mkDefault "/usr/bin/chromium";
    CONFIG_PATH = lib.mkDefault ".config/local.toml";
    ADMIN_CONFIG_PATH = lib.mkDefault ".config/local.admin.toml";
    TOOLCHAIN_NODE_VERSION = "24.12.0";
    TOOLCHAIN_PNPM_VERSION = pnpmVersion;
    TOOLCHAIN_GO_VERSION = "1.26.4";
    TOOLCHAIN_GORM_VERSION = "1.31.0";
    TOOLCHAIN_GOLANG_MIGRATE_VERSION = "4.18.3";
    TOOLCHAIN_OAPI_CODEGEN_VERSION = "2.4.1";
    TOOLCHAIN_TYPESPEC_VERSION = "1.8.0";
    TOOLCHAIN_OPENSPEC_VERSION = openspecVersion;
    TOOLCHAIN_AGENT_BROWSER_VERSION = "0.27.0";
  };

  enterShell = ''
    export DEVENV_CACHE_ROOT="$DEVENV_ROOT/.cache"
    export GOPATH="$DEVENV_CACHE_ROOT/go"
    export GOMODCACHE="$GOPATH/pkg/mod"
    export GOCACHE="$DEVENV_CACHE_ROOT/go-build"
    export PLAYWRIGHT_BROWSERS_PATH="$DEVENV_CACHE_ROOT/ms-playwright"
    export PNPM_HOME="$DEVENV_CACHE_ROOT/pnpm"
    export COREPACK_HOME="$DEVENV_CACHE_ROOT/corepack"

    mkdir -p \
      "$GOPATH" \
      "$GOMODCACHE" \
      "$GOCACHE" \
      "$PLAYWRIGHT_BROWSERS_PATH" \
      "$PNPM_HOME" \
      "$COREPACK_HOME"

    export PATH="$PNPM_HOME:$GOPATH/bin:$PATH"
    "${corepackBin}" enable --install-directory "$PNPM_HOME" >/dev/null
    hash -r
  '';
}
