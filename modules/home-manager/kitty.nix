# Exportable module: Kitty terminal
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.dani-modules.kitty;
in
{
  options.dani-modules.kitty = {
    enable = lib.mkEnableOption "dani-modules Kitty terminal";
    fontSize = lib.mkOption {
      type = lib.types.int;
      default = 10;
      description = "Kitty font size.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.kitty = {
      enable = true;
      package = pkgs.kitty;
      settings = {
        font_size = cfg.fontSize;
        wheel_scroll_min_lines = 1;
        confirm_os_window_close = 0;
        scrollback_lines = 999999;
        enable_audio_bell = false;
        mouse_hide_wait = 60;
        cursor_trail = 3;
        cursor_trail_decay = "0.1 0.4";
        tab_fade = "0.25 0.5 0.75 1";
        active_tab_font_style = "bold";
        inactive_tab_font_style = "bold";
        tab_bar_edge = "top";
        tab_bar_margin_width = 0;
        tab_bar_style = "powerline";
      };
    };
  };
}
