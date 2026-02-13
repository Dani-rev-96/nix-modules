# Exportable NixOS module: AMD GPU (ROCm, Vulkan, Mesa)
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.dani-modules.amd-gpu;
in
{
  options.dani-modules.amd-gpu = {
    enable = lib.mkEnableOption "AMD GPU driver setup";
    rocm = lib.mkEnableOption "ROCm/OpenCL support";
    mesaGit = lib.mkEnableOption "Mesa from git source";
    openclPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ pkgs.rocmPackages.clr.icd ];
      description = "OpenCL ICD packages.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.xserver.videoDrivers = [ "modesetting" ];

    hardware.graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages =
        with pkgs;
        [
          vulkan-loader
          vulkan-validation-layers
          vulkan-extension-layer
        ]
        ++ (lib.optionals cfg.rocm cfg.openclPackages);
    };

    hardware.graphics.extraPackages32 = with pkgs.pkgsi686Linux; [
      vulkan-loader
      vulkan-validation-layers
      vulkan-extension-layer
    ];

    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      AMD_VULKAN_ICD = "RADV";
    };

    systemd.tmpfiles.rules = lib.mkIf cfg.rocm [
      "L+    /opt/rocm   -    -    -     -    ${pkgs.rocmPackages.clr}"
    ];
  };
}
