return {
  {
    'milanglacier/minuet-ai.nvim',
    -- Minuet uses vim.system internally, no plenary dependency needed.
    -- blink.cmp is already loaded via lsp.lua.
    dependencies = {
      'saghen/blink.cmp',
    },
    config = function()
      -- Manually trigger minuet completions via blink.cmp
      -- (Set here because blink.cmp's keymap config only accepts built-in command strings)
      vim.keymap.set('i', '<A-y>', function()
        require('blink.cmp').show { providers = { 'minuet' } }
      end, { desc = 'Minuet: show AI completions' })

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
            stream = true,
            -- `optional` is merged verbatim into the request body. Put any extra
            -- OpenAI-compatible parameters HERE, not at the provider top level
            -- (where minuet silently ignores them).
            optional = {
              -- Cap output length to avoid request timeouts from long responses.
              max_tokens = 512,
              -- Qwopus3.5-4B-Coder-MTP is Qwen3.5-based and enables "thinking"
              -- by default. Disable it ONLY for minuet's requests (not globally
              -- in llama.cpp) via the Qwen chat-template flag, which llama.cpp
              -- forwards into the prompt template:
              chat_template_kwargs = { enable_thinking = false },
            },
          },
        },

        -- --- blink.cmp integration ---
        -- minuet is registered as a blink.cmp provider in lsp.lua, but it is
        -- intentionally NOT in `sources.default`, so it only runs on manual
        -- request (not on every keystroke). This is why `:Minuet` / blink status
        -- lists it under "Disabled sources" — that is expected and correct.
        --
        -- The manual trigger is set as a plain insert-mode keymap in this file's
        -- `config` (above the setup call), because blink.cmp v1's keymap table
        -- only accepts its built-in command strings, not arbitrary functions:
        --   vim.keymap.set('i', '<A-y>', function()
        --     require('blink.cmp').show { providers = { 'minuet' } }
        --   end)

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
        -- Max seconds to wait for a completion. Keep in sync with the blink
        -- `minuet` provider's `timeout_ms` (request_timeout * 1000) in lsp.lua.
        request_timeout = 5,

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
      }
    end,
  },
}
