{ pkgs, lib, ... }:

let
  nodejs = if pkgs ? nodejs_24 then pkgs.nodejs_24 else pkgs.nodejs;
  go = if pkgs ? go_1_26 then pkgs.go_1_26 else pkgs.go;
  postgresql = if pkgs ? postgresql_18 then pkgs.postgresql_18 else pkgs.postgresql;
  openspecVersion = "1.3.1";

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
    GOPATH = lib.mkDefault "$DEVENV_ROOT/.cache/go";
    GOMODCACHE = lib.mkDefault "$DEVENV_ROOT/.cache/go/pkg/mod";
    GOCACHE = lib.mkDefault "$DEVENV_ROOT/.cache/go-build";
    PLAYWRIGHT_BROWSERS_PATH = lib.mkDefault "$DEVENV_ROOT/.cache/ms-playwright";
    PNPM_HOME = lib.mkDefault "$DEVENV_ROOT/.cache/pnpm";
    TOOLCHAIN_NODE_VERSION = "24.12.0";
    TOOLCHAIN_PNPM_VERSION = "11.5.1";
    TOOLCHAIN_GO_VERSION = "1.26.4";
    TOOLCHAIN_GORM_VERSION = "1.31.0";
    TOOLCHAIN_GOLANG_MIGRATE_VERSION = "4.18.3";
    TOOLCHAIN_OAPI_CODEGEN_VERSION = "2.4.1";
    TOOLCHAIN_TYPESPEC_VERSION = "1.8.0";
    TOOLCHAIN_OPENSPEC_VERSION = openspecVersion;
    TOOLCHAIN_AGENT_BROWSER_VERSION = "0.27.0";
  };

  enterShell = ''
    mkdir -p \
      "$DEVENV_ROOT/.cache/go" \
      "$DEVENV_ROOT/.cache/go-build" \
      "$DEVENV_ROOT/.cache/ms-playwright" \
      "$DEVENV_ROOT/.cache/pnpm"
    export PATH="$PNPM_HOME:$GOPATH/bin:$PATH"
    corepack enable --install-directory "$PNPM_HOME" >/dev/null
    corepack prepare pnpm@11.5.1 --activate >/dev/null
  '';
}
