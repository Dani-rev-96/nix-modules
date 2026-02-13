# Exportable module: Git configuration
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.dani-modules.git;
in
{
  options.dani-modules.git = {
    enable = lib.mkEnableOption "dani-modules git setup";
    email = lib.mkOption {
      type = lib.types.str;
      default = "danielgrundler@gmail.com";
      description = "Git user email.";
    };
    name = lib.mkOption {
      type = lib.types.str;
      default = "Daniel Grundler";
      description = "Git user name.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.git = {
      enable = true;
      lfs.enable = true;
      settings = {
        user.email = lib.mkDefault cfg.email;
        user.name = lib.mkDefault cfg.name;
        diff.colorMoved = "default";
        pull.rebase = true;
        fetch.writeCommitGraph = true;
        core.fsMonitor = true;
        column.ui = "auto";
        rerere.enable = true;
      };
      ignores = [ ".DS_Store" ];
    };
    programs.delta = {
      enable = true;
      options = {
        line-numbers = true;
        side-by-side = true;
      };
    };
  };
}
