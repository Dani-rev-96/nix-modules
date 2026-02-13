# Exportable module: Shell (zsh + zoxide + eza + bat + fzf)
# Can be imported in any home-manager config:
#   imports = [ inputs.dani-flake.nixosModules.shell ];
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.dani-modules.shell;
in
{
  options.dani-modules.shell = {
    enable = lib.mkEnableOption "dani-modules shell (zsh + tools)";
  };

  config = lib.mkIf cfg.enable {
    programs.zoxide.enable = true;
    programs.eza.enable = true;
    programs.bat = {
      enable = true;
      package = pkgs.bat;
      extraPackages = [
        pkgs.bat-extras.batdiff
        pkgs.bat-extras.batman
        pkgs.bat-extras.batgrep
        pkgs.bat-extras.batwatch
      ];
    };
    programs.fzf.enable = true;
    programs.zsh = {
      enable = true;
      enableCompletion = false;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      history.size = 9999999;
    };
  };
}
