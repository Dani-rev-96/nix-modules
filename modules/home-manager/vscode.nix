# Exportable module: VSCode configuration
# Can be imported in any home-manager config:
#   imports = [ inputs.dani-flake.nixosModules.vscode ];
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.dani-modules.vscode;
in
{
  options.dani-modules.vscode = {
    enable = lib.mkEnableOption "dani-modules VSCode setup";

    fontSize = lib.mkOption {
      type = lib.types.int;
      default = 12;
      description = "Font size for editor and terminal.";
    };

    extraExtensions = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Additional VSCode extensions to install.";
    };

    java = lib.mkEnableOption "Java extensions";
    web = lib.mkEnableOption "Web development extensions (Vue, Deno, Playwright)";
    embedded = lib.mkEnableOption "Embedded/PlatformIO extensions";
    vim = lib.mkEnableOption "Vim keybindings (vscodevim)";
    neovim = lib.mkEnableOption "Neovim integration (vscode-neovim)";
  };

  config = lib.mkIf cfg.enable {
    programs.vscode = {
      enable = true;
      profiles.default = {
        extensions =
          let
            base = with pkgs.vscode-extensions; [
              bbenoist.nix
              jnoortheen.nix-ide
              mads-hartmann.bash-ide-vscode
              mikestead.dotenv
              editorconfig.editorconfig
              ms-ceintl.vscode-language-pack-de
              eamodio.gitlens
              ritwickdey.liveserver
              quicktype.quicktype
              christian-kohler.path-intellisense
              esbenp.prettier-vscode
              alefragnani.project-manager
              jock.svg
              vscode-icons-team.vscode-icons
              redhat.vscode-yaml
              formulahendry.code-runner
              ms-vscode-remote.remote-ssh
              ms-vscode-remote.remote-containers
              ms-vscode.test-adapter-converter
              redhat.vscode-xml
              humao.rest-client
              mkhl.direnv
            ];

            javaExts = lib.optionals cfg.java (
              (with pkgs.vscode-extensions; [
                redhat.java
                vscjava.vscode-java-pack
                vscjava.vscode-maven
                vscjava.vscode-gradle
                vscjava.vscode-java-debug
                vscjava.vscode-java-dependency
                vscjava.vscode-java-test
              ])
              ++ (lib.optionals (pkgs ? vscode-marketplace) (
                with pkgs.vscode-marketplace;
                [
                  vscjava.vscode-lombok
                ]
              ))
            );

            webExts = lib.optionals cfg.web (
              (with pkgs.vscode-extensions; [
                dbaeumer.vscode-eslint
                graphql.vscode-graphql-syntax
              ])
              ++ (lib.optionals (pkgs ? vscode-marketplace) (
                with pkgs.vscode-marketplace;
                [
                  jeff-hykin.better-dockerfile-syntax
                  vue.volar
                  sdras.vue-vscode-snippets
                  vitest.explorer
                  pucelle.vscode-css-navigation
                  ms-playwright.playwright
                  denoland.vscode-deno
                ]
              ))
            );

            embeddedExts = lib.optionals cfg.embedded (
              with pkgs.vscode-extensions;
              [
                platformio.platformio-vscode-ide
              ]
            );

            vimExts = lib.optionals cfg.vim (
              with pkgs.vscode-extensions;
              [
                vscodevim.vim
              ]
            );

            neovimExts = lib.optionals cfg.neovim (
              with pkgs.vscode-extensions;
              [
                asvetliakov.vscode-neovim
              ]
            );

            communityBase = lib.optionals (pkgs ? vscode-marketplace) (
              with pkgs.vscode-marketplace;
              [
                kisstkondoros.vscode-codemetrics
                ahmadalli.vscode-nginx-conf
              ]
            );
            filterAvailable =
              exts:
              builtins.filter (
                ext:
                let
                  platforms = ext.meta.platforms or [ ];
                in
                platforms == [ ] || builtins.elem pkgs.stdenv.hostPlatform.system platforms
              ) exts;
          in
          filterAvailable (
            base
            ++ javaExts
            ++ webExts
            ++ embeddedExts
            ++ vimExts
            ++ neovimExts
            ++ communityBase
            ++ cfg.extraExtensions
          );

        enableUpdateCheck = false;
        enableExtensionUpdateCheck = false;
        userSettings = {
          "workbench.iconTheme" = "vscode-icons";
          "workbench.colorTheme" = "Default Dark Modern";
          "redhat.telemetry.enabled" = false;
          "editor.fontFamily" = "JetBrainsMono Nerd Font Mono";
          "editor.fontSize" = cfg.fontSize;
          "editor.wordWrap" = "on";
          "editor.minimap.enabled" = true;
          "editor.formatOnSave" = true;
          "editor.smoothScrolling" = true;
          "terminal.integrated.fontSize" = cfg.fontSize;
          "terminal.integrated.scrollback" = 9999999;
          "projectManager.git.baseFolders" = [ "~/Workspace" ];
          "nix.enableLanguageServer" = true;
          "nix.serverPath" = "nixd";
          "nix.serverSettings" = {
            "nixd" = {
              "formatting" = {
                "command" = [ "nixfmt" ];
              };
            };
          };
          "terminal.integrated.defaultProfile.osx" = "zsh";
          "terminal.integrated.defaultProfile.linux" = "zsh";
          "java.jdt.ls.vmargs" =
            "--add-opens=jdk.jdi/com.sun.tools.jdi=ALL-UNNAMED -XX:+UseParallelGC -XX:GCTimeRatio=4 -XX:AdaptiveSizePolicyWeight=90 -Dsun.zip.disableMemoryMapping=true -Xmx2G -Xms100m -Xlog:disable";
        }
        // lib.optionalAttrs cfg.vim {
          "vim.useSystemClipboard" = true;
        }
        // lib.optionalAttrs cfg.neovim {
          "extensions.experimental.affinity" = {
            "asvetliakov.vscode-neovim" = 1;
          };
        };

        keybindings = lib.optionals cfg.vim [
          {
            key = "ctrl+y";
            command = "editor.action.inlineSuggest.commit";
            when = "inlineSuggestionVisible && editorTextFocus";
          }
          {
            key = "ctrl+j";
            command = "editor.action.inlineSuggest.commit";
            when = "inlineSuggestionVisible && editorTextFocus";
          }
          {
            key = "tab";
            command = "-editor.action.inlineSuggest.commit";
          }
          {
            key = "ctrl+n";
            command = "editor.action.inlineSuggest.showNext";
            when = "inlineSuggestionVisible && editorTextFocus";
          }
          {
            key = "ctrl+p";
            command = "editor.action.inlineSuggest.showPrevious";
            when = "inlineSuggestionVisible && editorTextFocus";
          }
          {
            key = "ctrl+y";
            command = "-redo";
          }
          {
            key = "ctrl+j";
            command = "chatEditor.action.acceptHunk";
            when = "chatEdits.cursorInChangeRange && chatEdits.hasEditorModifications && editorFocus && !chatEdits.isCurrentlyBeingModified || chatEdits.cursorInChangeRange && chatEdits.hasEditorModifications && notebookCellListFocused && !chatEdits.isCurrentlyBeingModified";
          }
          {
            key = "ctrl+y";
            command = "-chatEditor.action.acceptHunk";
            when = "chatEdits.cursorInChangeRange && chatEdits.hasEditorModifications && editorFocus && !chatEdits.isCurrentlyBeingModified || chatEdits.cursorInChangeRange && chatEdits.hasEditorModifications && notebookCellListFocused && !chatEdits.isCurrentlyBeingModified";
          }
          {
            key = "ctrl+y";
            command = "acceptSelectedSuggestion";
            when = "suggestWidgetHasFocusedSuggestion && suggestWidgetVisible && textInputFocus";
          }
          {
            key = "tab";
            command = "-acceptSelectedSuggestion";
            when = "suggestWidgetHasFocusedSuggestion && suggestWidgetVisible && textInputFocus";
          }
          {
            key = "u";
            command = "undo";
            when = "editorTextFocus && vim.mode == 'Normal'";
          }
          {
            key = "ctrl+r";
            command = "redo";
            when = "editorTextFocus && vim.mode == 'Normal'";
          }
          {
            key = "ctrl+z";
            command = "-undo";
          }
        ];
      };
    };

    home.packages = with pkgs; [
      nixd
      nil
    ];
  };
}
