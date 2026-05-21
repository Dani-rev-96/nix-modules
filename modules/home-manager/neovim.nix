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
      plugins =
        let
          # Only parser grammars (.so files) — no nvim-treesitter plugin runtime.
          # This avoids conflicts with Neovim 0.12's native treesitter.
          # Needed so neotest's subprocess can parse TypeScript/JS test files.
          fullTs = pkgs.vimPlugins.nvim-treesitter.withPlugins (p: [
            p.typescript
            p.javascript
            p.vue
            p.bash
            p.lua
            p.json
            p.html
            p.css
            p.scss
            p.java
            p.markdown
            p.markdown_inline
            p.vimdoc
            p.query
            p.diff
          ]);
          # Extract only the parser/ directory (no nvim-treesitter Lua runtime)
          parsersOnly = pkgs.runCommandLocal "treesitter-parsers-only" { } ''
            mkdir -p $out/parser
            cp ${fullTs}/parser/*.so $out/parser/
          '';
        in
        [
          parsersOnly
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
