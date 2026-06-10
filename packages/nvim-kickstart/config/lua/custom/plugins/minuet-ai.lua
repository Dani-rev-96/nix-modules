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

      -- --- Safety-net: strip Markdown code fences / language labels ---
      -- Small/quantized coder models (like this Qwen-based MTP model) often
      -- ignore minuet's built-in "do not include markdown code block fences"
      -- guideline and either wrap completions in ``` fences or prefix them with
      -- the language name (e.g. a first line of `javascript`, or ```html).
      --
      -- minuet's OpenAI-compatible *chat* backend (complete_openai_base)
      -- hardcodes its text extraction and exposes NO response post-processing
      -- hook (only the FIM backend accepts a `get_text_fn`). So we wrap
      -- `parse_completion_items`, the single point where the raw model text is
      -- split into individual completion items, and clean each item there.
      -- This covers both the blink.cmp and virtualtext frontends.
      local function strip_code_fences(text)
        if type(text) ~= 'string' then
          return text
        end
        local lines = vim.split(text, '\n', { plain = true })

        if lines[1] and lines[1]:match '^%s*```' then
          -- Drop the opening ``` / ```lang fence ...
          table.remove(lines, 1)
          -- ... and the matching closing fence (last trailing ``` line).
          for i = #lines, 1, -1 do
            if lines[i]:match '^%s*```%s*$' then
              table.remove(lines, i)
              break
            elseif lines[i]:match '%S' then
              break
            end
          end
        elseif lines[1] and #lines > 1 then
          -- Some models emit a bare language label as the first line instead
          -- of a fence (e.g. `javascript`). Only strip it when it matches a
          -- known language / the current filetype, to avoid eating real code.
          local first = lines[1]:gsub('%s+$', ''):lower()
          local langs = {
            javascript = true, js = true, javascriptreact = true, jsx = true,
            typescript = true, ts = true, typescriptreact = true, tsx = true,
            vue = true, html = true, css = true, scss = true, sass = true,
            json = true, jsonc = true, yaml = true, yml = true, toml = true,
            lua = true, nix = true, bash = true, sh = true, shell = true,
            python = true, py = true, markdown = true, md = true,
          }
          if first ~= '' and (langs[first] or first == (vim.bo.filetype or '')) then
            table.remove(lines, 1)
          end
        end

        return table.concat(lines, '\n')
      end

      local minuet_common = require 'minuet.backends.common'
      if not minuet_common._minuet_strip_fence_patch then
        local original_parse = minuet_common.parse_completion_items
        minuet_common.parse_completion_items = function(items_raw, provider)
          return vim.tbl_map(strip_code_fences, original_parse(items_raw, provider))
        end
        minuet_common._minuet_strip_fence_patch = true
      end

      -- --- Model selection ---
      -- Both presets share the same Lemonade chat endpoint and differ only in
      -- the model id + a few model-specific request options. Switch the active
      -- completion model by changing `active_model` below.
      local models = {
        -- Previous model: Qwen3.5-based coder with MTP + "thinking" support.
        -- Kept here so we can switch back instantly. It enables "thinking" by
        -- default, so we must disable it per-request via chat_template_kwargs.
        ['Qwopus3.5-4B-Coder-MTP'] = {
          model = 'Qwopus3.5-4B-Coder-MTP',
          optional = {
            -- Cap output length to avoid request timeouts from long responses.
            max_tokens = 512,
            -- Disable Qwen "thinking" ONLY for minuet's requests (not globally
            -- in llama.cpp) via the Qwen chat-template flag:
            chat_template_kwargs = { enable_thinking = false },
          },
        },
        -- Active model: Qwen3-4B-Instruct-2507 (unsloth GGUF). Pure instruct
        -- tuning => NO thinking overhead and it tends to follow the
        -- "no code fences / no language label" guideline more reliably.
        -- No chat_template_kwargs needed (this model has no thinking mode).
        ['Qwen3-4B-Instruct-2507'] = {
          model = 'Qwen3-4B-Instruct-2507',
          optional = {
            -- Cap output length to avoid request timeouts from long responses.
            max_tokens = 512,
          },
        },
      }

      -- >>> Change this one line to switch models. <<<
      local active_model = 'Qwen3-4B-Instruct-2507'

      require('minuet').setup {
        -- Use the same openai_compatible provider as CodeCompanion so both
        -- AI features share the same backend (same endpoint, same API key).
        provider = 'openai_compatible',
        provider_options = {
          openai_compatible = {
            name = 'Lemonade',
            end_point = 'https://lemonade.dani-home.de/v1/chat/completions',
            model = models[active_model].model,
            api_key = 'LEMONADE_API_KEY',
            stream = true,
            -- --- Why chat completions (not FIM) + prefix-first ---
            -- Lemonade DOES expose /v1/completions, but its spec has NO `suffix`
            -- parameter, so native OpenAI-style FIM (prompt+suffix) is not
            -- supported. Manual-token FIM (<|fim_prefix|>...<|fim_suffix|>...
            -- <|fim_middle|>) would only work on a FIM-token *base* model.
            -- Qwopus3.5-4B-Coder-MTP is a chat/reasoning (instruct) model — it
            -- almost certainly lacks reliable FIM tokens — so we deliberately
            -- stay on the chat endpoint.
            --
            -- For the chat endpoint minuet defaults to PREFIX-FIRST for
            -- openai_compatible (prefix before suffix), which is the best fit
            -- for a Qwen chat model and lowest latency. We keep that default;
            -- overriding only `system.guidelines` below preserves it (we extend
            -- default_system_prefix_first, not the suffix-first variant).
            --
            -- Reinforce minuet's default guidelines. The defaults already tell
            -- the model not to emit code fences, but this small MTP model
            -- ignores that, so we append a much more explicit instruction.
            -- (Merged over the defaults via tbl_deep_extend; the strip shim
            -- above is the deterministic fallback when the model disobeys.)
            system = {
              guidelines = function()
                return require('minuet.config').default_system_prefix_first.guidelines
                  .. '\n\nIMPORTANT OUTPUT FORMAT: Return ONLY the raw code that'
                  .. ' belongs at <cursorPosition>. Never prepend the programming'
                  .. ' language name as a line (e.g. "javascript", "html", "vue").'
                  .. ' Never wrap the completion in Markdown code-block fences'
                  .. ' (``` or ```lang). Emit the code exactly as it must appear'
                  .. ' in the file.'
              end,
            },
            -- `optional` is merged verbatim into the request body. Model-
            -- specific request params live in the `models` table above (keyed
            -- by `active_model`); put any extra OpenAI-compatible parameters
            -- THERE, not at the provider top level (where minuet silently
            -- ignores them).
            optional = models[active_model].optional,
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
