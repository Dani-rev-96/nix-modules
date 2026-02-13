{
  description = "Reusable NixOS and home-manager modules by Dani";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    {
      # ── Exportable NixOS / home-manager modules ──────────────────────────────
      # Usage:
      #   inputs.nix-modules.url = "github:Dani-rev-96/nix-modules";
      #   modules = [ inputs.nix-modules.nixosModules.vscode ];
      nixosModules = import ./modules/exports.nix;

      # ── Overlay with custom packages ─────────────────────────────────────────
      overlays = {
        default = final: prev: {
          my-nvim-kickstart = final.callPackage ./packages/nvim-kickstart { };
          opentrack_custom = final.qt5.callPackage ./packages/opentrack { };
          goverlay_latest = final.callPackage ./packages/goverlay { };
          vulkan-hdr-layer = final.callPackage ./packages/vkHdrLayer { };
        };
      };
    };
}
