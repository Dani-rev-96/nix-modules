return {
  {
    'milanglacier/minuet-ai.nvim',
    -- Minuet uses vim.system internally, no plenary dependency needed.
    -- blink.cmp is already loaded via lsp.lua.
    dependencies = {
      'saghen/blink.cmp',
    },
    config = function()
      require('minuet').setup {
        -- Use the same openai_compatible provider as CodeCompanion so both
        -- AI features share the same backend (same endpoint, same API key).
        provider = 'openai_compatible',
        provider_options = {
          openai_compatible = {
            name = 'Lemonade',
            end_point = 'https://lemonade.dani-home.de/v1/chat/completions',
            model = 'Qwopus3.5-4B-Coder-MTP',
            api_key = 'LEMONADE_API_KEY',
            reasoning = { effort = 'none' }, -- or "minimal", depending on the model (OpenRouter)
            reasoning_effort = 'none', -- or "minimal", depending on the model (various providers)
            thinking = { type = 'disabled' }, -- DeepSeek API
            stream = true,
            -- template = {
            --     prompt = function(context_before_cursor, context_after_cursor, _)
            --         return '<|fim_prefix|>'
            --             .. context_before_cursor
            --             .. '<|fim_suffix|>'
            --             .. context_after_cursor
            --             .. '<|fim_middle|>'
            --     end,
            --     suffix = false,
            -- },
          },
        },

        -- --- blink.cmp integration ---
        -- Add minuet as a blink.cmp source (configured in lsp.lua below).
        -- Manual trigger via <A-y> (no conflict with existing mappings).
        --
        -- blink.cmp source is registered in lsp.lua's blink.cmp opts:
        --   providers = {
        --     minuet = { name = 'minuet', module = 'minuet.blink', ... }
        --   }
        --
        -- Manual trigger keymap is set in lsp.lua's blink.cmp keymap:
        --   ['<A-y>'] = require('minuet').make_blink_map()

        -- --- Virtual text frontend ---
        -- Shows inline suggestions as virtual text. Keymaps don't conflict
        -- with existing mappings:
        --   <A-A>  accept whole completion
        --   <A-a>  accept one line
        --   <A-z>  accept N lines (prompts for count)
        --   <A-[>  previous completion / manual trigger
        --   <A-]>  next completion / manual trigger
        --   <A-e>  dismiss
        virtualtext = {
          -- Enable auto-trigger for common coding filetypes.
          -- You can still manually trigger in any filetype with <A-[> / <A-]>.
          auto_trigger_ft = {
            'lua',
            'typescript',
            'typescriptreact',
            'javascript',
            'javascriptreact',
            'vue',
            'nix',
            'toml',
            'yaml',
            'json',
            'css',
            'scss',
            'html',
            'bash',
            'sh',
          },
          keymap = {
            accept        = '<A-A>',
            accept_line   = '<A-a>',
            accept_n_lines = '<A-z>',
            prev          = '<A-[>',
            next          = '<A-]>',
            dismiss       = '<A-e>',
          },
        },

        -- --- General tuning ---
        -- Throttle/debounce to avoid excessive API calls while keeping
        -- responsiveness reasonable for a cloud model.
        throttle = 1500,
        debounce = 600,
        request_timeout = 3,

        -- Number of completion items to request per invocation.
        n_completions = 3,

        -- Context window size (characters). Adjust based on your model's
        -- context length and latency tolerance.
        context_window = 16000,

        -- Add a single-line entry alongside multi-line completions for
        -- smoother blink.cmp / virtual text experience.
        add_single_line_entry = true,

        -- Notification level: only show warnings and errors.
        notify = 'warn',
      },
    end,
  },
}
