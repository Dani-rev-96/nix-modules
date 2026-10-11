{
  description = "Reusable NixOS and home-manager modules by Dani";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
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
          goverlay_latest = final.callPackage ./packages/goverlay { };
          zluda_custom = prev.callPackage ./packages/zluda { };
        };
      };

    }
    // flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ self.overlays.default ];
        };
      in
      {
        # Directly buildable targets for CI and the nix-build-infra prebuilder.
        packages = {
          zluda_custom = pkgs.zluda_custom;
          goverlay_latest = pkgs.goverlay_latest;
        };

        formatter = pkgs.nixfmt;

        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.nix-update
            pkgs.nixfmt
          ];
        };
      }
    );

}
