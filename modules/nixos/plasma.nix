# Exportable NixOS module: KDE Plasma 6 desktop
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.dani-modules.plasma;
in
{
  options.dani-modules.plasma = {
    enable = lib.mkEnableOption "KDE Plasma 6 desktop";
    wayland = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Use Wayland session.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.xserver.enable = true;
    services.displayManager.sddm = {
      enable = true;
      wayland.enable = cfg.wayland;
    };
    services.desktopManager.plasma6.enable = true;
    services.displayManager.defaultSession = "plasma";

    programs.kde-pim.merkuro = true;
    programs.kdeconnect = {
      enable = true;
    };

    environment.systemPackages = with pkgs; [
      kdePackages.qtimageformats
      kdePackages.kimageformats
      kdePackages.polkit-kde-agent-1
      kdePackages.plasma-browser-integration
      wl-clipboard
    ];

    xdg.portal = {
      enable = true;
      xdgOpenUsePortal = true;
      wlr.enable = true;
      extraPortals = [ pkgs.kdePackages.xdg-desktop-portal-kde ];
      configPackages = [ pkgs.kdePackages.plasma-workspace ];
    };

    networking.firewall = {
      allowedTCPPortRanges = [
        {
          from = 1714;
          to = 1764;
        }
      ];
      allowedUDPPortRanges = [
        {
          from = 1714;
          to = 1764;
        }
      ];
    };
  };
}
