# nix-modules

Reusable NixOS and home-manager modules.

## Usage

Add this flake as an input:

```nix
{
  inputs = {
    nix-modules.url = "github:Dani-rev-96/nix-modules";
  };
}
```

### NixOS Modules

Import individual modules:

```nix
{ inputs, ... }:
{
  imports = [ inputs.nix-modules.nixosModules.podman ];
  dani-modules.podman.enable = true;
}
```

### Home-Manager Modules

```nix
{ inputs, ... }:
{
  imports = [ inputs.nix-modules.nixosModules.vscode ];
  dani-modules.vscode.enable = true;
}
```

### Available Modules

| Module | Type | Description |
|---|---|---|
| `shell` | home-manager | zsh + zoxide + eza + bat + fzf |
| `vscode` | home-manager | VSCode with extensions and settings |
| `neovim` | home-manager | Neovim with kickstart config |
| `git` | home-manager | Git + delta |
| `development` | home-manager | Development tools and language servers |
| `kitty` | home-manager | Kitty terminal |
| `pipewire-virtual-surround` | NixOS | PipeWire virtual 7.1 surround |
| `podman` | NixOS | Podman with Docker compat |
| `amd-gpu` | NixOS | AMD GPU setup with ROCm |
| `plasma` | NixOS | KDE Plasma 6 |
| `options` | NixOS | Flake-config option declarations |
| `default` | NixOS | All options registered |

### Overlay

The flake also provides an overlay with custom packages:

```nix
nixpkgs.overlays = [ inputs.nix-modules.overlays.default ];
```

Packages: `my-nvim-kickstart`, `opentrack_custom`, `goverlay_latest`, `vulkan-hdr-layer`
