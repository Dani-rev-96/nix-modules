# Flake-wide configuration options.
# This replaces the old defaultVariables.nix with a proper NixOS module option system.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.flake-config;
in
{
  options.flake-config = {
    # ── User identity ──────────────────────────────────────────────────────────
    user = {
      name = lib.mkOption {
        type = lib.types.str;
        default = "daniel";
        description = "Primary user name for this host.";
      };
      email = lib.mkOption {
        type = lib.types.str;
        default = "danielgrundler@gmail.com";
        description = "Primary user email (used for git etc.).";
      };
      fullName = lib.mkOption {
        type = lib.types.str;
        default = "Daniel Grundler";
        description = "Full display name.";
      };
      flakeDir = lib.mkOption {
        type = lib.types.str;
        default = "~/Workspace/nix-flakes";
        description = "Path to the nix-flakes checkout.";
      };
    };

    # ── Desktop settings ───────────────────────────────────────────────────────
    desktop = {
      enable = lib.mkEnableOption "desktop environment and GUI tooling";

      environment = lib.mkOption {
        type = lib.types.enum [
          "plasma"
          "hyprland"
          "none"
        ];
        default = "plasma";
        description = "Which desktop environment to use.";
      };

      fontSize = lib.mkOption {
        type = lib.types.int;
        default = 12;
        description = "Base font size used across editors and terminals.";
      };

      browser = lib.mkOption {
        type = lib.types.str;
        default = "brave";
        description = "Default browser command.";
      };

      terminal = lib.mkOption {
        type = lib.types.str;
        default = "kitty";
        description = "Default terminal emulator command.";
      };
    };

    # ── Hyprland ───────────────────────────────────────────────────────────────
    hyprland = {
      monitors = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "monitor=,preferred,auto,1" ];
        description = "Hyprland monitor configuration lines.";
      };
      theme = lib.mkOption {
        type = lib.types.str;
        default = "dark";
        description = "Hyprland color theme.";
      };
    };

    # ── GPU ────────────────────────────────────────────────────────────────────
    gpu = {
      vendor = lib.mkOption {
        type = lib.types.enum [
          "amd"
          "nvidia"
          "intel"
          "none"
        ];
        default = "none";
        description = "GPU vendor for driver configuration.";
      };
      rocm = lib.mkEnableOption "ROCm / OpenCL support for AMD GPUs";
      mesaGit = lib.mkEnableOption "Mesa from git (bleeding-edge drivers)";
    };

    # ── Networking ─────────────────────────────────────────────────────────────
    network = {
      homelab = lib.mkEnableOption "homelab extra-hosts and builder configs";

      substituters = {
        enable = lib.mkEnableOption "custom binary cache substituters";
        machines = lib.mkOption {
          type = lib.types.listOf (
            lib.types.submodule {
              options = {
                hostName = lib.mkOption { type = lib.types.str; };
                port = lib.mkOption {
                  type = lib.types.int;
                  default = 4998;
                };
              };
            }
          );
          default = [ ];
          description = "Build machines to use as substituters.";
        };
      };
    };

    # ── Development ────────────────────────────────────────────────────────────
    development = {
      enable = lib.mkEnableOption "development tools and language servers";
      java = lib.mkEnableOption "Java/JDT development tooling";
      embedded = lib.mkEnableOption "Embedded/PlatformIO development";
      web = lib.mkEnableOption "Web development (Deno, Node, Vue)";
    };

    # ── Gaming ─────────────────────────────────────────────────────────────────
    gaming = {
      enable = lib.mkEnableOption "gaming support (Steam, Lutris, etc.)";
      vr = lib.mkEnableOption "VR support (Monado, OpenComposite)";
    };

    # ── Containers ─────────────────────────────────────────────────────────────
    containers = {
      podman = lib.mkEnableOption "Podman container runtime";
      k3s = {
        enable = lib.mkEnableOption "k3s Kubernetes";
        role = lib.mkOption {
          type = lib.types.enum [
            "server"
            "agent"
          ];
          default = "agent";
          description = "k3s role.";
        };
        serverAddr = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "k3s server address (for agents).";
        };
      };
    };

    # ── Audio ──────────────────────────────────────────────────────────────────
    audio = {
      virtualSurround = lib.mkEnableOption "PipeWire virtual 7.1 surround via HRIR convolver";
    };
  };
}
