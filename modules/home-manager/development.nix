# Exportable module: Development tools
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.dani-modules.development;
in
{
  options.dani-modules.development = {
    enable = lib.mkEnableOption "dani-modules development tools";
    java = lib.mkEnableOption "Java development (JDT, Maven)";
    embedded = lib.mkEnableOption "Embedded development (PlatformIO, AVR, ESP)";
    web = lib.mkEnableOption "Web development (Deno, TypeScript 7, TypeScript LSP)";
    nix = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Nix language tooling (nixd, nixfmt, nil).";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages =
      with pkgs;
      # Always included
      (lib.optionals cfg.nix [
        nixfmt
        nixd
        nil
      ])
      ++ [
        fd
        gh
        lynx
        pkg-config
        yaml-language-server
        lua-language-server
        tree-sitter
      ]
      ++ (lib.optionals cfg.web [
        deno
        # TS7 native compiler + LSP (`tsc --lsp`), global fallback for nvim.
        # Newer nixpkgs ship TS7 as `typescript` (and `typescript-go` is a throwing
        # alias); older ones still have TS5 as `typescript` and TS7 as `typescript-go`.
        (if lib.versionAtLeast typescript.version "7" then typescript else typescript-go)
        typescript-language-server
        vscode-langservers-extracted
      ])
      ++ (lib.optionals cfg.java [
        jdt-language-server
      ])
      ++ (lib.optionals cfg.embedded [
        platformio-core
        avrdude
        esptool
        espflash
      ]);

    programs.direnv = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };
  };
}
