# Exportable NixOS module: Podman container runtime
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.dani-modules.podman;
in
{
  options.dani-modules.podman = {
    enable = lib.mkEnableOption "Podman with Docker compatibility";
    storageDriver = lib.mkOption {
      type = lib.types.str;
      default = "btrfs";
      description = "Container storage driver (btrfs, overlay, etc.).";
    };
    autoPrune = lib.mkEnableOption "weekly auto-prune of containers/images" // {
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation = {
      containers.enable = true;
      podman = {
        enable = true;
        autoPrune.enable = cfg.autoPrune;
        autoPrune.dates = "weekly";
        dockerCompat = true;
        dockerSocket.enable = true;
        defaultNetwork.settings = {
          dns_enabled = true;
        };
      };
      containers.storage.settings = {
        storage = {
          driver = cfg.storageDriver;
        };
      };
    };
    environment.systemPackages = [ pkgs.podman-compose ];
  };
}
