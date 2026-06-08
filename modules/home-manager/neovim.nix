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
        # The orgmode plugin ships its own treesitter grammar but compiles it at
        # runtime via a C compiler (which our Neovim env intentionally lacks).
        # Build it declaratively instead and symlink it outside orgmode's own
        # parser dir, so orgmode detects it as installed and skips compilation.
        # Tag must match orgmode's required grammar version (`required_version`
        # in orgmode/utils/treesitter/install.lua).
        orgParser = pkgs.tree-sitter.buildGrammar {
          language = "org";
          version = "2.0.4";
          src = pkgs.fetchFromGitHub {
            owner = "nvim-orgmode";
            repo = "tree-sitter-org";
            rev = "2.0.4";
            hash = "sha256-76ImC8GMW+yAKG++AHryUi+MYTmtJ5ogygC+bgNMErA=";
          };
        };
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
        # Includes both language-specific queries AND shared/virtual query directories
        # that are used via `; inherits:` directives (e.g., vue inherits html_tags).
        queryLangs = [
          # Language-specific query directories
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
          # Shared/virtual query directories (no parser, only queries)
          "ecma" # used by: javascript, qmljs, glimmer_javascript
          "jsx" # used by: typescript, tsx
          "tsx"
          "jsdoc" # injected by ecma for JSDoc comments
          "regex" # injected by ecma, query for regex patterns
          "html_tags" # used by: vue, angular, blade, svelte, astro, html (indents)
          "php_only" # used by: php (highlights/indents/injections)
          "gotmpl" # used by: helm (indents/injections/locals/folds)
          "hcl" # used by: terraform (indents/injections)
          "printf" # injected by c/cpp for printf format strings
          "doxygen" # injected by c/cpp for Doxygen comments
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
        # orgmode grammar (buildGrammar outputs the .so directly at $out/parser)
        {
          "nvim/site/parser/org.so".source = "${orgParser}/parser";
        }
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
