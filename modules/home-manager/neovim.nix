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

    # Symlink treesitter parser .so files into ~/.local/share/nvim/site/parser/
    # This path is always in Neovim's rtp (including neotest's subprocess).
    # Avoids conflicts with Neovim 0.12's native treesitter (no nvim-treesitter plugin runtime).
    xdg.dataFile =
      let
        parsers = with pkgs.vimPlugins.nvim-treesitter-parsers; {
          inherit
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
            ;
        };
        # nvim-treesitter source for query files (highlights, indents, injections, etc.)
        tsQueries = "${pkgs.vimPlugins.nvim-treesitter}/runtime/queries";
        # Languages that need query files (not bundled with Neovim 0.12 runtime)
        queryLangs = [
          "typescript"
          "javascript"
          "vue"
          "html"
          "css"
          "scss"
          "json"
          "java"
          "bash"
          "diff"
          "jsdoc"
          "jsx"
          "tsx"
          "regex"
          "ecma"
        ];
      in
      # Parser .so symlinks
      (lib.mapAttrs' (
        name: drv:
        lib.nameValuePair "nvim/site/parser/${name}.so" {
          source = "${drv}/parser/${name}.so";
        }
      ) parsers)
      //
        # Query directory symlinks (highlights.scm, indents.scm, etc.)
        (builtins.listToAttrs (
          builtins.concatMap (
            lang:
            if builtins.pathExists (tsQueries + "/${lang}") then
              [
                {
                  name = "nvim/site/queries/${lang}";
                  value = {
                    source = "${tsQueries}/${lang}";
                    recursive = true;
                  };
                }
              ]
            else
              [ ]
          ) queryLangs
        ));

    xdg.configFile."nvim" = lib.mkIf (pkgs ? my-nvim-kickstart) {
      source = config.lib.file.mkOutOfStoreSymlink "${pkgs.my-nvim-kickstart}";
      recursive = true;
    };
  };
}
