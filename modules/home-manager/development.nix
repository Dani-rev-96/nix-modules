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
    web = lib.mkEnableOption "Web development (Deno, TypeScript LSP)";
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
      ]
      ++ (lib.optionals cfg.web [
        deno
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
