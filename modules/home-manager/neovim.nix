# Exportable module: Neovim configuration
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.dani-modules.neovim;
in
{
  options.dani-modules.neovim = {
    enable = lib.mkEnableOption "dani-modules Neovim setup";
  };

  config = lib.mkIf cfg.enable {
    programs.neovim = {
      enable = true;
      defaultEditor = true;
      package = pkgs.neovim-unwrapped;
      vimdiffAlias = true;
      viAlias = true;
      vimAlias = true;
      withNodeJs = true;
      withRuby = true;
      withPython3 = true;
      plugins = with pkgs.vimPlugins.nvim-treesitter-parsers; [
        # Only parser grammars (.so files) as individual plugins — no nvim-treesitter runtime.
        # This avoids conflicts with Neovim 0.12's native treesitter.
        # Needed so neotest's subprocess can find parsers in the runtimepath.
        typescript
        javascript
        vue
        bash
        lua
        json
        html
        css
        scss
        java
        markdown
        markdown_inline
        vimdoc
        query
        diff
      ];
      extraPackages = with pkgs; [
        lua
        ripgrep
        gnumake
        unzip
        lua51Packages.lua
        luajitPackages.luarocks
        (pkgs.python3.withPackages (python-pkgs: [
          python-pkgs.pip
        ]))
        cargo
        jdk
        go
        lua-language-server
        stylua
      ];
    };

    xdg.configFile."nvim" = lib.mkIf (pkgs ? my-nvim-kickstart) {
      source = config.lib.file.mkOutOfStoreSymlink "${pkgs.my-nvim-kickstart}";
      recursive = true;
    };
  };
}
