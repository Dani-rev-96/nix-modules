local attach_callback = function(event)
  -- NOTE: Remember that Lua is a real programming language, and as such it is possible
  -- to define small helper and utility functions so you don't have to repeat yourself.
  --
  -- In this case, we create a function that lets us more easily define mappings specific
  -- for LSP related items. It sets the mode, buffer and description for us each time.

  local client = vim.lsp.get_client_by_id(event.data.client_id)
  local bufnr = event.buf
  local map = function(keys, func, desc, mode)
    mode = mode or 'n'
    vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
  end

  local ts_organize_imports = function(client, bufnr)
    return client:exec_cmd({
      command = '_typescript.organizeImports',
      arguments = { vim.api.nvim_buf_get_name(bufnr) },
    }, { bufnr = bufnr })
  end
  -- local ts_fix_all = function(client, bufnr)
  --   return client:exec_cmd({
  --     command = '_typescript.fixAll',
  --     arguments = { vim.api.nvim_buf_get_name(bufnr) },
  --   }, { bufnr = bufnr })
  -- end
  -- local ts_remove_unused = function(client, bufnr)
  --   return client:exec_cmd({
  --     command = '_typescript.removeUnused',
  --     arguments = { vim.api.nvim_buf_get_name(bufnr) },
  --   }, { bufnr = bufnr })
  -- end

  -- Rename the variable under your cursor.
  --  Most Language Servers support renaming across files, etc.
  map('grn', vim.lsp.buf.rename, '[R]e[n]ame')

  -- Execute a code action, usually your cursor needs to be on top of an error
  -- or a suggestion from your LSP for this to activate.
  map('gra', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })

  -- Find references for the word under your cursor.
  map('grr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')

  -- Jump to the implementation of the word under your cursor.
  --  Useful when your language has ways of declaring types without an actual implementation.
  map('gri', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')

  -- Jump to the definition of the word under your cursor.
  --  This is where a variable was first declared, or where a function is defined, etc.
  --  To jump back, press <C-t>.
  -- map('grd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')
  --
  map('grd', function()
    vim.lsp.buf.definition({
      on_list = function(options)
        -- Save position in jumplist so <C-o> works after any navigation
        vim.cmd("normal! m'")
        local from = { vim.fn.bufnr('%'), vim.fn.line('.'), vim.fn.col('.'), 0 }
        vim.fn.settagstack(vim.fn.win_getid(), { items = { { tagname = vim.fn.expand('<cword>'), from = from } } }, 't')

        if #options.items == 1 then
          local item = options.items[1]
          local b = vim.fn.bufadd(item.filename)
          vim.bo[b].buflisted = true
          vim.api.nvim_win_set_buf(0, b)
          vim.api.nvim_win_set_cursor(0, { item.lnum, item.col - 1 })
        else
          vim.fn.setqflist({}, ' ', options)
          require('telescope.builtin').quickfix({prompt_title = 'LSP Definitions'})
        end
      end,
    })
  end, '[G]oto [D]efinition')

  -- WARN: This is not Goto Definition, this is Goto Declaration.
  --  For example, in C this would take you to the header.
  map('grD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

  -- Fuzzy find all the symbols in your current document.
  --  Symbols are things like variables, functions, types, etc.
  map('gO', require('telescope.builtin').lsp_document_symbols, 'Open Document Symbols')

  -- Fuzzy find all the symbols in your current workspace.
  --  Similar to document symbols, except searches over your entire project.
  map('gW', require('telescope.builtin').lsp_dynamic_workspace_symbols, 'Open Workspace Symbols')

  -- Jump to the type of the word under your cursor.
  --  Useful when you're not sure what type a variable is and you want to see
  --  the definition of its *type*, not where it was *defined*.
  map('grt', require('telescope.builtin').lsp_type_definitions, '[G]oto [T]ype Definition')

  if client and client.name == 'ts_ls' then
    map('gro', function()
      ts_organize_imports(client, bufnr)
    end, '[G]oto [O]rganize Imports')
    -- map('grf', function()
    --   ts_fix_all(client, bufnr)
    -- end, '[G]oto [F]ix all')
    -- map('gru', function()
    --   ts_remove_unused(client, bufnr)
    -- end, '[G]oto remove [U]nused')
  end

  -- Vue: jump from class name in template to style definition
  if client and client.name == 'vue_ls' then
    -- Follow LSP document links (vue_ls provides scoped-class-links)
    map('gL', function()
      local params = vim.lsp.util.make_text_document_params(bufnr)
      client:request('textDocument/documentLink', params, function(err, result)
        if err or not result or #result == 0 then
          vim.notify('No document links found', vim.log.levels.INFO)
          return
        end
        local cursor = vim.api.nvim_win_get_cursor(0)
        local row = cursor[1] - 1
        local col = cursor[2]
        for _, link in ipairs(result) do
          local range = link.range
          if row >= range.start.line and row <= range['end'].line and col >= range.start.character and col <= range['end'].character then
            if link.target then
              local uri, fragment = link.target:match '^(.-)#(.+)$'
              uri = uri or link.target
              local fname = vim.uri_to_fname(uri)
              if fragment then
                local sline = fragment:match '^L(%d+)'
                if sline then
                  vim.cmd('edit ' .. vim.fn.fnameescape(fname))
                  vim.api.nvim_win_set_cursor(0, { tonumber(sline), 0 })
                  vim.cmd 'normal! zz'
                  return
                end
              end
              vim.cmd('edit ' .. vim.fn.fnameescape(fname))
            end
            return
          end
        end
        vim.notify('No document link under cursor', vim.log.levels.INFO)
      end, bufnr)
    end, 'Follow Document [L]ink')

    -- Simple search fallback: jump to .classname in <style> block
    map('gsc', function()
      local word = vim.fn.expand '<cword>'
      if word == '' then
        return
      end
      local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
      local in_style = false
      local pattern = '%.' .. vim.pesc(word) .. '[%s%{,:%[>~+)]'
      for i, line in ipairs(lines) do
        if line:match '<style' then
          in_style = true
        end
        if in_style then
          local col = line:find(pattern)
          if col then
            vim.api.nvim_win_set_cursor(0, { i, col - 1 })
            vim.cmd 'normal! zz'
            return
          end
        end
        if line:match '</style>' then
          in_style = false
        end
      end
      vim.notify('Class .' .. word .. ' not found in <style> block', vim.log.levels.WARN)
    end, '[G]oto [S]tyle [C]lass')
  end

  -- This function resolves a difference between neovim nightly (version 0.11) and stable (version 0.10)
  ---@param client vim.lsp.Client
  ---@param method vim.lsp.protocol.Method
  ---@param bufnr? integer some lsp support methods only in specific files
  ---@return boolean
  local function client_supports_method(client, method, bufnr)
    if vim.fn.has 'nvim-0.11' == 1 then
      return client:supports_method(method, bufnr)
    else
      return client.supports_method(method, { bufnr = bufnr })
    end
  end

  -- The following two autocommands are used to highlight references of the
  -- word under your cursor when your cursor rests there for a little while.
  --    See `:help CursorHold` for information about when this is executed
  --
  -- When you move your cursor, the highlights will be cleared (the second autocommand).
  if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf) then
    local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
    vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
      buffer = event.buf,
      group = highlight_augroup,
      callback = vim.lsp.buf.document_highlight,
    })

    vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
      buffer = event.buf,
      group = highlight_augroup,
      callback = vim.lsp.buf.clear_references,
    })

    vim.api.nvim_create_autocmd('LspDetach', {
      group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
      callback = function(event2)
        vim.lsp.buf.clear_references()
        vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
      end,
    })
  end

  -- The following code creates a keymap to toggle inlay hints in your
  -- code, if the language server you are using supports them
  --
  -- This may be unwanted, since they displace some of your code
  if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
    map('<leader>th', function()
      vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
    end, '[T]oggle Inlay [H]ints')
  end
end

local java_filetypes = 'java'

local function has(plugin)
  return require('lazy.core.config').plugins[plugin] ~= nil
end

return {
  -- LSP Plugins
  {
    -- `lazydev` configures Lua LSP for your Neovim config, runtime and plugins
    -- used for completion, annotations and signatures of Neovim apis
    'folke/lazydev.nvim',
    ft = 'lua',
    opts = {
      library = {
        -- Load luvit types when the `vim.uv` word is found
        { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
      },
    },
  },
  -- lazy.nvim plugin spec
  {
    'Dani-rev-96/css-classes',
    build = 'npm install && npm run build',
    config = function()
      vim.lsp.enable('css_classes')
    end,
  },
  {
    -- Main LSP Configuration
    'neovim/nvim-lspconfig',
    dependencies = {
      -- Automatically install LSPs and related tools to stdpath for Neovim
      -- Mason must be loaded before its dependents so we need to set it up here.
      -- NOTE: `opts = {}` is the same as calling `require('mason').setup({})`
      { 'mason-org/mason.nvim', opts = {} },
      'mason-org/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',

      -- Useful status updates for LSP.
      { 'j-hui/fidget.nvim', opts = {} },

      -- Allows extra capabilities provided by blink.cmp
      'saghen/blink.cmp',
    },
    config = function()
      -- Brief aside: **What is LSP?**
      --
      -- LSP is an initialism you've probably heard, but might not understand what it is.
      --
      -- LSP stands for Language Server Protocol. It's a protocol that helps editors
      -- and language tooling communicate in a standardized fashion.
      --
      -- In general, you have a "server" which is some tool built to understand a particular
      -- language (such as `gopls`, `lua_ls`, `rust_analyzer`, etc.). These Language Servers
      -- (sometimes called LSP servers, but that's kind of like ATM Machine) are standalone
      -- processes that communicate with some "client" - in this case, Neovim!
      --
      -- LSP provides Neovim with features like:
      --  - Go to definition
      --  - Find references
      --  - Autocompletion
      --  - Symbol Search
      --  - and more!
      --
      -- Thus, Language Servers are external tools that must be installed separately from
      -- Neovim. This is where `mason` and related plugins come into play.
      --
      -- If you're wondering about lsp vs treesitter, you can check out the wonderfully
      -- and elegantly composed help section, `:help lsp-vs-treesitter`

      --  This function gets run when an LSP attaches to a particular buffer.
      --    That is to say, every time a new file is opened that is associated with
      --    an lsp (for example, opening `main.rs` is associated with `rust_analyzer`) this
      --    function will be executed to configure the current buffer

      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
        callback = attach_callback,
      })

      -- Diagnostic Config
      -- See :help vim.diagnostic.Opts
      vim.diagnostic.config {
        severity_sort = true,
        float = { border = 'rounded', source = 'if_many' },
        underline = { severity = vim.diagnostic.severity.ERROR },
        signs = vim.g.have_nerd_font and {
          text = {
            [vim.diagnostic.severity.ERROR] = '󰅚 ',
            [vim.diagnostic.severity.WARN] = '󰀪 ',
            [vim.diagnostic.severity.INFO] = '󰋽 ',
            [vim.diagnostic.severity.HINT] = '󰌶 ',
          },
        } or {},
        virtual_text = {
          source = 'if_many',
          spacing = 2,
          format = function(diagnostic)
            local diagnostic_message = {
              [vim.diagnostic.severity.ERROR] = diagnostic.message,
              [vim.diagnostic.severity.WARN] = diagnostic.message,
              [vim.diagnostic.severity.INFO] = diagnostic.message,
              [vim.diagnostic.severity.HINT] = diagnostic.message,
            }
            return diagnostic_message[diagnostic.severity]
          end,
        },
      }

      -- LSP servers and clients are able to communicate to each other what features they support.
      --  By default, Neovim doesn't support everything that is in the LSP specification.
      --  When you add blink.cmp, luasnip, etc. Neovim now has *more* capabilities.
      --  So, we create new capabilities with blink.cmp, and then broadcast that to the servers.
      local capabilities = require('blink.cmp').get_lsp_capabilities()
      -- capabilities.textDocument.completion.completionItem.labelDetailsSupport = true
      vim.g.markdown_fenced_languages = { 'ts=typescript' }
      local mason_path = vim.fn.stdpath 'data' .. '/mason'
      local vue_language_server_path = mason_path .. '/packages/vue-language-server/node_modules/@vue/language-server'
      local vue_plugin = {
        name = '@vue/typescript-plugin',
        location = vue_language_server_path,
        languages = { 'vue', 'javascript', 'typescript' },
        configNamespace = 'typescript',
      }

      -- Enable the following language servers
      --  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
      --
      --  Add any additional override configuration in the following tables. Available keys are:
      --  - cmd (table): Override the default command used to start the server
      --  - filetypes (table): Override the default list of associated filetypes for the server
      --  - capabilities (table): Override fields in capabilities. Can be used to disable certain LSP features.
      --  - settings (table): Override the default settings passed when initializing the server.
      --        For example, to see the options for `lua_ls`, you could go to: https://luals.github.io/wiki/settings/
      local servers = {
        -- clangd = {},
        -- gopls = {},
        -- pyright = {},
        -- rust_analyzer = {},
        -- ... etc. See `:help lspconfig-all` for a list of all the pre-configured LSPs
        --
        -- Some languages (like typescript) have entire language plugins that can be useful:
        --    https://github.com/pmizio/typescript-tools.nvim
        --
        -- But for many setups, the LSP (`ts_ls`) will work just fine
        -- ts_ls = {},
        --

        lua_ls = {
          settings = {
            Lua = {
              completion = {
                callSnippet = 'Replace',
              },
              -- You can toggle below to ignore Lua_LS's noisy `missing-fields` warnings
              -- diagnostics = { disable = { 'missing-fields' } },
            },
          },
        },
        nixd = {
          cmd = { 'nixd' },
          settings = {
            formatting = {
              command = { 'nixfmt' },
            },
          },
        },
        -- nil_ls = {
        --   settings = {
        --     nix = {
        --       flake = {
        --         autoArchive = true, -- Set to true, false, or null based on your preference
        --       },
        --     },
        --   },
        -- },
        denols = {
          filetypes = {
            'json',
            'jsonc',
            'markdown',
            'html',
            'css',

            'javascript',
            'javascriptreact',
            'jsx',

            'typescript',
            'typescriptreact',
            'tsx',
          },
        },
        yamlls = {
          capabilities = {
            textDocument = {
              foldingRange = {
                dynamicRegistration = false,
                lineFoldingOnly = true,
              },
            },
          },
          settings = {
            yaml = {
              redhat = { telemetry = { enabled = false } },
              keyOrdering = false,
              format = {
                enable = true,
              },
              validate = true,
              schemas = {
                ['http://json.schemastore.org/github-workflow'] = '.github/workflows/*',
                ['http://json.schemastore.org/github-action'] = '.github/action.{yml,yaml}',
                ['http://json.schemastore.org/ansible-stable-2.9'] = 'roles/tasks/*.{yml,yaml}',
                ['http://json.schemastore.org/prettierrc'] = '.prettierrc.{yml,yaml}',
                ['http://json.schemastore.org/kustomization'] = 'kustomization.{yml,yaml}',
                ['http://json.schemastore.org/ansible-playbook'] = '*play*.{yml,yaml}',
                ['http://json.schemastore.org/chart'] = 'Chart.{yml,yaml}',
                ['https://json.schemastore.org/dependabot-v2'] = '.github/dependabot.{yml,yaml}',
                ['https://json.schemastore.org/gitlab-ci'] = '*gitlab-ci*.{yml,yaml}',
                ['https://raw.githubusercontent.com/OAI/OpenAPI-Specification/main/schemas/v3.1/schema.json'] = '*api*.{yml,yaml}',
                ['https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json'] = '*docker-compose*.{yml,yaml}',
                ['https://raw.githubusercontent.com/argoproj/argo-workflows/master/api/jsonschema/schema.json'] = '*flow*.{yml,yaml}',
              },
            },
          },
        },
        ts_ls = {
          init_options = {
            plugins = {
              vue_plugin,
            },
          },
          filetypes = {
            'typescript',
            'javascript',
            'javascriptreact',
            'typescriptreact',
            'vue',
          },
          settings = {
            typescript = {
              inlayHints = {
                includeInlayParameterNameHints = 'all',
                includeInlayParameterNameHintsWhenArgumentMatchesName = true,
                includeInlayFunctionParameterTypeHints = true,
                includeInlayVariableTypeHints = true,
                includeInlayVariableTypeHintsWhenTypeMatchesName = true,
                includeInlayPropertyDeclarationTypeHints = true,
                includeInlayFunctionLikeReturnTypeHints = true,
                includeInlayEnumMemberValueHints = true,
              },
            },
          },
        },
        vue_ls = {
          filetypes = { 'vue' },
        },
        --   vtsls = {
        --     filetypes = {
        --       'typescript',
        --       'javascript',
        --       'javascriptreact',
        --       'typescriptreact',
        --       'vue',
        --     },
        --   },
        terraformls = {
          filetypes = { 'terraform' },
        },
        sqlls = {
          filetypes = { 'sql' },
        },
        docker_compose_language_service = {
          filetypes = { 'docker-compose' },
        },
        dockerls = {
          filetypes = { 'dockerfile' },
        },
        eslint = {
          settings = {
            workingDirectories = { mode = 'auto' },
          },
        },
        clangd = {
          filetypes = { 'c', 'cpp', 'objc', 'objcpp', 'cc', 'mpp', 'ixx' },
        },
        somesass_ls = {
          root_dir = function(bufnr, on_dir)
            on_dir(vim.uv.cwd())
          end,
          filetypes = { 'sass', 'scss' },
        },
        cssls = {
          root_dir = function(bufnr, on_dir)
            on_dir(vim.uv.cwd())
          end,
          filetypes = { 'css', 'scss', 'html', 'javascriptreact', 'typescriptreact' },
        },
        css_variables = {
          root_dir = function(bufnr, on_dir)
            on_dir(vim.uv.cwd())
          end,
          filetypes = { 'css', 'scss', 'less', 'vue', 'html' },
        },
        cssmodules_ls = {
          root_dir = function(bufnr, on_dir)
            on_dir(vim.uv.cwd())
          end,
          filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact', 'vue' },
        },
        emmet_language_server = {},
        css_classes = {
          filetypes = { 'html', 'vue', 'javascriptreact', 'typescriptreact', 'css', 'scss' },
          root_markers = { '.git' },
        },
      }

      if vim.fn.executable 'kubectl' == 1 then
        local kubernetes = {
          yamlls = {
            settings = {
              yaml = {
                schemas = {
                  [require('kubernetes').yamlls_schema()] = '*.{yml,yaml}',
                },
              },
            },
          },
        }
        servers = vim.tbl_deep_extend('force', {}, servers, kubernetes)
      end

      -- Ensure the servers and tools above are installed
      --
      -- To check the current status of installed tools and/or manually install
      -- other tools, you can run
      --    :Mason
      --
      -- You can press `g?` for help in this menu.
      --
      -- `mason` had to be setup earlier: to configure its options see the
      -- `dependencies` table for `nvim-lspconfig` above.
      --
      -- You can add other tools here that you want Mason to install
      -- for you, so that they are available from within Neovim.
      local ensure_installed = vim.tbl_keys(servers or {})

      ensure_installed = vim.tbl_filter(function(name)
        return name ~= 'clangd'
      end, ensure_installed)

      ensure_installed = vim.tbl_filter(function(name)
        return name ~= 'nixd'
      end, ensure_installed)

      ensure_installed = vim.tbl_filter(function(name)
        return name ~= 'css_classes'
      end, ensure_installed)

      vim.list_extend(ensure_installed, {
        'stylua', -- Used to format Lua code
        'jdtls',
        'prettier',
        'css-lsp',
        'cssmodules-language-server',
        'css-variables-language-server',
        'some-sass-language-server',
        -- 'vue_ls',
        -- 'vtsls',
      })
      require('mason-tool-installer').setup { ensure_installed = ensure_installed }

      -- require('mason-lspconfig').setup {
      --   ensure_installed = {}, -- explicitly set to an empty table (Kickstart populates installs via mason-tool-installer)
      --   automatic_installation = false,
      --   automatic_enable = false,
      --   handlers = {
      --     function(server_name)
      --       local server = servers[server_name] or {}
      --       print('lspconfig handler hit for server_name: ' .. server_name)
      --       -- This handles overriding only values explicitly passed
      --       -- by the server configuration above. Useful when disabling
      --       -- certain features of an LSP (for example, turning off formatting for ts_ls)
      --       server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
      --       -- vim.lsp.config(server_name, server)
      --       -- vim.lsp.enable(server_name)
      --       require('lspconfig')[server_name].setup(server)
      --     end,
      --   },
      -- }

      for server_name, server in pairs(servers) do
        server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
        -- require('lspconfig')[server_name].setup(server)
        vim.lsp.config(server_name, server)
        vim.lsp.enable(server_name)
        -- require('lspconfig')[server_name].setup(server)
      end
    end,
  },

  { -- Autoformat
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    keys = {
      {
        '<leader>f',
        function()
          require('conform').format { async = true, lsp_format = 'fallback' }
        end,
        mode = '',
        desc = '[F]ormat buffer',
      },
    },
    opts = {
      notify_on_error = false,
      format_on_save = function(bufnr)
        -- Disable "format_on_save lsp_fallback" for languages that don't
        -- have a well standardized coding style. You can add additional
        -- languages here or re-enable it for the disabled ones.
        local disable_filetypes = { c = true, cpp = true }
        if disable_filetypes[vim.bo[bufnr].filetype] then
          return nil
        else
          return {
            timeout_ms = 500,
            lsp_format = 'fallback',
          }
        end
      end,
      formatters_by_ft = {
        lua = { 'stylua' },
        typescript = { 'prettierd', 'prettier', stop_after_first = true },
        typescriptreact = { 'prettierd', 'prettier', stop_after_first = true },
        javascript = { 'prettierd', 'prettier', stop_after_first = true },
        javascriptreact = { 'prettierd', 'prettier', stop_after_first = true },
        vue = { 'prettierd', 'prettier', stop_after_first = true },
        ['*'] = { 'codespell' },
        ['_'] = { 'trim_whitespace' }, -- This will trim trailing whitespace in all files
        -- Conform can also run multiple formatters sequentially
        -- python = { "isort", "black" },
        --
        -- You can use 'stop_after_first' to run the first available formatter from the list
        -- javascript = { "prettierd", "prettier", stop_after_first = true },
      },
    },
  },

  { -- Autocompletion
    'saghen/blink.cmp',
    event = 'VimEnter',
    version = '1.*',
    dependencies = {
      -- Snippet Engine
      {
        'L3MON4D3/LuaSnip',
        version = '2.*',
        build = (function()
          -- Build Step is needed for regex support in snippets.
          -- This step is not supported in many windows environments.
          -- Remove the below condition to re-enable on windows.
          if vim.fn.has 'win32' == 1 or vim.fn.executable 'make' == 0 then
            return
          end
          return 'make install_jsregexp'
        end)(),
        dependencies = {
          -- `friendly-snippets` contains a variety of premade snippets.
          --    See the README about individual language/framework/plugin snippets:
          --    https://github.com/rafamadriz/friendly-snippets
          -- {
          --   'rafamadriz/friendly-snippets',
          --   config = function()
          --     require('luasnip.loaders.from_vscode').lazy_load()
          --   end,
          -- },
        },
        opts = {},
      },
      'folke/lazydev.nvim',
    },
    --- @module 'blink.cmp'
    --- @type blink.cmp.Config
    opts = {
      keymap = {
        -- 'default' (recommended) for mappings similar to built-in completions
        --   <c-y> to accept ([y]es) the completion.
        --    This will auto-import if your LSP supports it.
        --    This will expand snippets if the LSP sent a snippet.
        -- 'super-tab' for tab to accept
        -- 'enter' for enter to accept
        -- 'none' for no mappings
        --
        -- For an understanding of why the 'default' preset is recommended,
        -- you will need to read `:help ins-completion`
        --
        -- No, but seriously. Please read `:help ins-completion`, it is really good!
        --
        -- All presets have the following mappings:
        -- <tab>/<s-tab>: move to right/left of your snippet expansion
        -- <c-space>: Open menu or open docs if already open
        -- <c-n>/<c-p> or <up>/<down>: Select next/previous item
        -- <c-e>: Hide menu
        -- <c-k>: Toggle signature help
        --
        -- See :h blink-cmp-config-keymap for defining your own keymap
        preset = 'default',

        -- For more advanced Luasnip keymaps (e.g. selecting choice nodes, expansion) see:
        --    https://github.com/L3MON4D3/LuaSnip?tab=readme-ov-file#keymaps
      },

      appearance = {
        -- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
        -- Adjusts spacing to ensure icons are aligned
        nerd_font_variant = 'mono',
      },

      completion = {
        -- By default, you may press `<c-space>` to show the documentation.
        -- Optionally, set `auto_show = true` to show the documentation after a delay.
        documentation = { auto_show = true, auto_show_delay_ms = 500 },
        menu = {
          -- Don't automatically show the completion menu
          auto_show = true,

          -- nvim-cmp style menu
          draw = {
            columns = {
              { 'label', 'label_description', gap = 1 },
              { 'kind_icon', 'kind' },
            },
          },
        },
      },

      sources = {
        default = { 'lsp', 'path', 'snippets', 'lazydev' },

        providers = {
          lazydev = { module = 'lazydev.integrations.blink', score_offset = 100 },
        },
      },

      -- Show documentation when selecting a completion item

      snippets = { preset = 'luasnip' },

      -- Blink.cmp includes an optional, recommended rust fuzzy matcher,
      -- which automatically downloads a prebuilt binary when enabled.
      --
      -- By default, we use the Lua implementation instead, but you may enable
      -- the rust implementation via `'prefer_rust_with_warning'`
      --
      -- See :h blink-cmp-config-fuzzy for more information
      fuzzy = { implementation = 'lua' },

      -- Shows a signature help window while you type arguments for a function
      signature = { enabled = true },
    },
  },
  {
    'mfussenegger/nvim-jdtls',
    dependencies = {
      'folke/which-key.nvim',
      'saghen/blink.cmp',
    },
    ft = java_filetypes,
    opts = function()
      local cmd = { vim.fn.exepath 'jdtls' }
      if has 'mason.nvim' then
        local jdtls_path = vim.fn.expand '$MASON/packages/jdtls'
        local lombok_jar = jdtls_path .. '/lombok.jar'
        table.insert(cmd, string.format('--jvm-arg=-javaagent:%s', lombok_jar))
      end
      local lspconfig_util = require 'lspconfig.util'
      return {
        -- How to find the root dir for a given filename. The default comes from
        -- lspconfig which provides a function specifically for java projects.
        -- root_dir = rootDir,

        root_dir = function(fname)
          return lspconfig_util.root_pattern('.git', 'mvnw', 'gradlew', 'pom.xml', 'build.gradle')(fname)
        end,

        -- How to find the project name for a given root dir.
        project_name = function(root_dir)
          return root_dir and vim.fs.basename(root_dir)
        end,

        -- Where are the config and workspace dirs for a project?
        jdtls_config_dir = function(project_name)
          return vim.fn.stdpath 'cache' .. '/jdtls/' .. project_name .. '/config'
        end,
        jdtls_workspace_dir = function(project_name)
          return vim.fn.stdpath 'cache' .. '/jdtls/' .. project_name .. '/workspace'
        end,

        -- How to run jdtls. This can be overridden to a full java command-line
        -- if the Python wrapper script doesn't suffice.
        cmd = cmd,
        full_cmd = function(opts)
          local fname = vim.api.nvim_buf_get_name(0)
          local root_dir = opts.root_dir(fname)
          local project_name = opts.project_name(root_dir)
          local cmd = vim.deepcopy(opts.cmd)
          if project_name then
            vim.list_extend(cmd, {
              '-configuration',
              opts.jdtls_config_dir(project_name),
              '-data',
              opts.jdtls_workspace_dir(project_name),
            })
          end
          return cmd
        end,

        -- These depend on nvim-dap, but can additionally be disabled by setting false here.
        dap = { hotcodereplace = 'auto', config_overrides = {} },
        -- Can set this to false to disable main class scan, which is a performance killer for large project
        dap_main = {},
        test = true,
        settings = {
          java = {
            format = {
              settings = {
                url = vim.fn.getcwd() .. '/.vscode/java-formatter.xml',
                profile = 'Default', -- Replace with your profile name from the XML file
              },
            },
            inlayHints = {
              parameterNames = {
                enabled = 'all',
              },
            },
          },
        },
      }
    end,
    config = function(_, opts)
      -- Find the extra bundles that should be passed on the jdtls command-line
      -- if nvim-dap is enabled with java debug/test.
      local bundles = {} ---@type string[]
      if has 'mason.nvim' then
        local mason_registry = require 'mason-registry'
        if opts.dap and has 'nvim-dap' and mason_registry.is_installed 'java-debug-adapter' then
          local java_dbg_path = vim.fn.expand '$MASON/packages/java-debug-adapter'
          local jar_patterns = {
            java_dbg_path .. '/extension/server/com.microsoft.java.debug.plugin-*.jar',
          }
          -- java-test also depends on java-debug-adapter.
          if opts.test and mason_registry.is_installed 'java-test' then
            local java_test_path = vim.fn.expand '$MASON/packages/java-test'
            vim.list_extend(jar_patterns, {
              java_test_path .. '/extension/server/*.jar',
            })
          end
          for _, jar_pattern in ipairs(jar_patterns) do
            for _, bundle in ipairs(vim.split(vim.fn.glob(jar_pattern), '\n')) do
              table.insert(bundles, bundle)
            end
          end
        end
      end
      local function attach_jdtls()
        local fname = vim.api.nvim_buf_get_name(0)
        local function extend_or_override(defaults, overrides)
          return vim.tbl_deep_extend('force', defaults or {}, overrides or {})
        end

        local capabilities = require('blink.cmp').get_lsp_capabilities()
        capabilities.textDocument.completion.completionItem.labelDetailsSupport = true

        -- Configuration can be augmented and overridden by opts.jdtls
        local config = extend_or_override({
          cmd = opts.full_cmd(opts),
          root_dir = opts.root_dir(fname),
          init_options = {
            bundles = bundles,
          },
          settings = opts.settings,
          -- enable CMP capabilities
          -- require('blink.cmp')
          -- capabilities = has 'blink.cmp' and require('blink.cmp').default_capabilities() or nil,
          -- capabilities = has 'cmp-nvim-lsp' and require('cmp_nvim_lsp').default_capabilities() or nil,
          capabilities = capabilities,
        }, opts.jdtls)

        -- Existing server will be reused if the root_dir matches.
        require('jdtls').start_or_attach(config)
        -- not need to require("jdtls.setup").add_commands(), start automatically adds commands
      end

      -- Attach the jdtls for each java buffer. HOWEVER, this plugin loads
      -- depending on filetype, so this autocmd doesn't run for the first file.
      -- For that, we call directly below.
      vim.api.nvim_create_autocmd('FileType', {
        pattern = java_filetypes,
        callback = attach_jdtls,
      })

      -- Setup keymap and dap after the lsp is fully attached.
      -- https://github.com/mfussenegger/nvim-jdtls#nvim-dap-configuration
      -- https://neovim.io/doc/user/lsp.html#LspAttach
      vim.api.nvim_create_autocmd('LspAttach', {
        callback = function(args)
          attach_callback(args)

          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if client and client.name == 'jdtls' then
            local wk = require 'which-key'
            wk.add {
              {
                mode = 'n',
                buffer = args.buf,
                { '<leader>cx', group = 'extract' },
                { '<leader>cxv', require('jdtls').extract_variable_all, desc = 'Extract Variable' },
                { '<leader>cxc', require('jdtls').extract_constant, desc = 'Extract Constant' },
                { '<leader>cgs', require('jdtls').super_implementation, desc = 'Goto Super' },
                { '<leader>cgS', require('jdtls.tests').goto_subjects, desc = 'Goto Subjects' },
                { '<leader>co', require('jdtls').organize_imports, desc = 'Organize Imports' },
              },
            }
            wk.add {
              {
                mode = 'v',
                buffer = args.buf,
                { '<leader>cx', group = 'extract' },
                {
                  '<leader>cxm',
                  [[<ESC><CMD>lua require('jdtls').extract_method(true)<CR>]],
                  desc = 'Extract Method',
                },
                {
                  '<leader>cxv',
                  [[<ESC><CMD>lua require('jdtls').extract_variable_all(true)<CR>]],
                  desc = 'Extract Variable',
                },
                {
                  '<leader>cxc',
                  [[<ESC><CMD>lua require('jdtls').extract_constant(true)<CR>]],
                  desc = 'Extract Constant',
                },
              },
            }

            if has 'mason.nvim' then
              local mason_registry = require 'mason-registry'
              if opts.dap and has 'nvim-dap' and mason_registry.is_installed 'java-debug-adapter' then
                -- custom init for Java debugger
                require('jdtls').setup_dap(opts.dap)
                if opts.dap_main then
                  require('jdtls.dap').setup_dap_main_class_configs(opts.dap_main)
                end

                -- Java Test require Java debugger to work
                if opts.test and mason_registry.is_installed 'java-test' then
                  -- custom keymaps for Java test runner (not yet compatible with neotest)
                  wk.add {
                    {
                      mode = 'n',
                      buffer = args.buf,
                      { '<leader>t', group = 'test' },
                      {
                        '<leader>tt',
                        function()
                          require('jdtls.dap').test_class {
                            config_overrides = type(opts.test) ~= 'boolean' and opts.test.config_overrides or nil,
                          }
                        end,
                        desc = 'Run All Test',
                      },
                      {
                        '<leader>tr',
                        function()
                          require('jdtls.dap').test_nearest_method {
                            config_overrides = type(opts.test) ~= 'boolean' and opts.test.config_overrides or nil,
                          }
                        end,
                        desc = 'Run Nearest Test',
                      },
                      { '<leader>tT', require('jdtls.dap').pick_test, desc = 'Run Test' },
                    },
                  }
                end
              end
            end

            -- User can set additional keymaps in opts.on_attach
            if opts.on_attach then
              opts.on_attach(args)
            end
          end
        end,
      })

      -- Avoid race condition by calling attach the first time, since the autocmd won't fire.
      attach_jdtls()
    end,
  },
}
