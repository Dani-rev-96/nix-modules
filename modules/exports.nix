# Exportable NixOS modules that can be consumed as flake inputs.
# Usage in another flake:
#   inputs.nix-modules.url = "github:Dani-rev-96/nix-modules";
#   modules = [ inputs.nix-modules.nixosModules.vscode ];
{
  # ── Shell configuration (zsh + tools) ──────────────────────────────────────
  # Home-manager module
  shell = ./home-manager/shell.nix;

  # ── VSCode configuration ───────────────────────────────────────────────────
  # Home-manager module
  vscode = ./home-manager/vscode.nix;

  # ── Neovim configuration ──────────────────────────────────────────────────
  # Home-manager module
  neovim = ./home-manager/neovim.nix;

  # ── Git configuration ──────────────────────────────────────────────────────
  # Home-manager module
  git = ./home-manager/git.nix;

  # ── Development tools ──────────────────────────────────────────────────────
  # Home-manager module
  development = ./home-manager/development.nix;

  # ── Kitty terminal ─────────────────────────────────────────────────────────
  # Home-manager module
  kitty = ./home-manager/kitty.nix;

  # ── PipeWire virtual surround ──────────────────────────────────────────────
  # NixOS module
  pipewire-virtual-surround = ./nixos/pipewire-virtual-surround.nix;

  # ── Podman container setup ─────────────────────────────────────────────────
  # NixOS module
  podman = ./nixos/podman.nix;

  # ── AMD GPU setup ──────────────────────────────────────────────────────────
  # NixOS module
  amd-gpu = ./nixos/amd-gpu.nix;

  # ── Plasma desktop ────────────────────────────────────────────────────────
  # NixOS module
  plasma = ./nixos/plasma.nix;

  # ── Options (flake-config) ─────────────────────────────────────────────────
  options = ./options.nix;

  # ── Full default (all options + overlays) ──────────────────────────────────
  default = ./default.nix;
}
