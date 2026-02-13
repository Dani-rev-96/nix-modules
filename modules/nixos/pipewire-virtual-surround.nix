# Exportable NixOS module: PipeWire virtual 7.1 surround via HRIR convolver
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.dani-modules.pipewire-virtual-surround;
in
{
  options.dani-modules.pipewire-virtual-surround = {
    enable = lib.mkEnableOption "PipeWire virtual 7.1 surround sound via HeSuVi HRIR";
    hrirPath = lib.mkOption {
      type = lib.types.path;
      description = "Path to the 14-channel WAV HRIR file.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
      extraConfig.pipewire = {
        "92-low-latency" = {
          "context.properties" = {
            "default.clock.rate" = 48000;
            "default.clock.quantum" = 1024;
            "default.clock.min-quantum" = 1024;
            "default.clock.max-quantum" = 4096;
          };
        };
      };
      extraConfig.pipewire-pulse = {
        "92-low-latency" = {
          "context.modules" = [
            {
              name = "libpipewire-module-protocol-pulse";
              args = {
                "pulse.min.req" = "1024/48000";
                "pulse.default.req" = "1024/48000";
                "pulse.max.req" = "1024/48000";
                "pulse.min.quantum" = "1024/48000";
                "pulse.max.quantum" = "1024/48000";
              };
            }
          ];
          "stream.properties" = {
            "node.latency" = "1024/48000";
            "resample.quality" = 1;
          };
        };
      };
    };

    # The HRIR filter-chain would be configured in your user's pipewire config
    # pointing to cfg.hrirPath. This module sets up the PipeWire base.
  };
}
