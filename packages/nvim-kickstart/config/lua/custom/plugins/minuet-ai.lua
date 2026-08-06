return {
  {
    'milanglacier/minuet-ai.nvim',
    -- Gated by the per-project AI selection resolved in init.lua.
    -- Only loads when the active mode selects minuet inline completion.
    enabled = vim.g.ai_completion == 'minuet',
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

      -- --- Model selection (per project, rebuild-free) ---
      -- Each entry is fully self-describing: it carries its own minuet
      -- `provider` and matching `provider_options`, so FIM and chat models can
      -- coexist and be switched per project. Optional `tuning` overrides the
      -- shared defaults further below.
      --
      -- Shared, chat-only guideline reinforcement. Small/quantized chat coder
      -- models ignore minuet's built-in "no code fences" rule, so we append a
      -- much more explicit instruction (the strip shim above is the
      -- deterministic fallback). FIM models don't use a system prompt.
      local function chat_guidelines()
        return require('minuet.config').default_system_prefix_first.guidelines
          .. '\n\nIMPORTANT OUTPUT FORMAT: Return ONLY the raw code that'
          .. ' belongs at <cursorPosition>. Never prepend the programming'
          .. ' language name as a line (e.g. "javascript", "html", "vue").'
          .. ' Never wrap the completion in Markdown code-block fences'
          .. ' (``` or ```lang). Emit the code exactly as it must appear'
          .. ' in the file.'
      end

      local models = {
        -- Default: Qwen3-Coder via TRUE fill-in-the-middle on /v1/completions.
        -- Qwen3-Coder's tokenizer ships the standard Qwen FIM tokens
        -- (<|fim_prefix|>/<|fim_suffix|>/<|fim_middle|>, verified against the HF
        -- tokenizer_config), so we build the PSM prompt manually. Lemonade's
        -- /v1/completions has NO `suffix` field, hence `template.suffix = false`
        -- and we inline the suffix into the prompt ourselves.
        ['Qwen3-Coder-30B-A3B-Instruct-GGUF'] = {
          provider = 'openai_fim_compatible',
          provider_options = {
            name = 'Lemonade FIM',
            end_point = 'https://lemonade.dani-home.de/v1/completions',
            model = 'Qwen3-Coder-30B-A3B-Instruct-GGUF',
            api_key = 'LEMONADE_API_KEY',
            stream = true,
            template = {
              -- Qwen PSM order: prefix, then suffix, then the middle marker.
              prompt = function(context_before_cursor, context_after_cursor, _)
                return '<|fim_prefix|>'
                  .. context_before_cursor
                  .. '<|fim_suffix|>'
                  .. context_after_cursor
                  .. '<|fim_middle|>'
              end,
              -- Suffix is inlined above; don't let minuet send a separate
              -- `suffix` request field (unsupported by this endpoint).
              suffix = false,
            },
            optional = {
              max_tokens = 256,
              temperature = 0.1,
              top_p = 0.9,
              -- Stop as soon as the model emits any FIM/segment/turn marker so
              -- it can't run past the middle span into repo/file scaffolding.
              stop = {
                '<|fim_pad|>',
                '<|endoftext|>',
                '<|file_sep|>',
                '<|repo_name|>',
                '<|im_end|>',
              },
            },
          },
          tuning = {
            -- 30B FIM model: single request, snappier trigger, larger context.
            throttle = 800,
            debounce = 250,
            request_timeout = 10,
            n_completions = 1,
            context_window = 32000,
          },
        },
        -- Previous chat/reasoning models on the /v1/chat/completions endpoint.
        -- Kept so we can switch back instantly (per project or via env var).
        ['qwen35-4b-instruct-mtp-mxfp4'] = {
          provider = 'openai_compatible',
          provider_options = {
            name = 'Lemonade',
            end_point = 'https://lemonade.dani-home.de/v1/chat/completions',
            model = 'qwen35-4b-instruct-mtp-mxfp4',
            api_key = 'LEMONADE_API_KEY',
            stream = true,
            system = { guidelines = chat_guidelines },
            optional = {
              -- Cap output length to avoid request timeouts from long responses.
              max_tokens = 512,
            },
          },
        },
        ['Qwopus3.5-4B-Coder-MTP'] = {
          provider = 'openai_compatible',
          provider_options = {
            name = 'Lemonade',
            end_point = 'https://lemonade.dani-home.de/v1/chat/completions',
            model = 'Qwopus3.5-4B-Coder-MTP',
            api_key = 'LEMONADE_API_KEY',
            stream = true,
            system = { guidelines = chat_guidelines },
            optional = {
              -- Cap output length to avoid request timeouts from long responses.
              max_tokens = 512,
              -- Disable Qwen "thinking" ONLY for minuet's requests via the Qwen
              -- chat-template flag (this model enables thinking by default).
              chat_template_kwargs = { enable_thinking = false },
            },
          },
        },
      }

      -- Resolve the active model per project (mirrors init.lua's AI-mode
      -- resolver): $NVIM_MINUET_MODEL wins, else a `.nvim-minuet-model` file
      -- searched upward from cwd (stops at $HOME), else the default below.
      local default_model = 'Qwen3-Coder-30B-A3B-Instruct-GGUF'
      local function resolve_minuet_model()
        local env = vim.env.NVIM_MINUET_MODEL
        if env and env ~= '' then
          return vim.trim(env)
        end
        local found = vim.fs.find('.nvim-minuet-model', {
          upward = true,
          path = vim.fn.getcwd(),
          stop = vim.env.HOME,
          type = 'file',
        })[1]
        if found then
          local ok, lines = pcall(vim.fn.readfile, found, '', 1)
          if ok and lines[1] then
            return vim.trim(lines[1])
          end
        end
        return default_model
      end

      local active_model = resolve_minuet_model()
      if not models[active_model] then
        vim.schedule(function()
          vim.notify(
            ('Unknown minuet model %q (NVIM_MINUET_MODEL / .nvim-minuet-model); using %q. Known: %s'):format(
              active_model,
              default_model,
              table.concat(vim.tbl_keys(models), ', ')
            ),
            vim.log.levels.WARN
          )
        end)
        active_model = default_model
      end
      vim.g.minuet_model = active_model

      local m = models[active_model]
      -- Per-model `tuning` overrides these shared defaults.
      local tuning = vim.tbl_extend('force', {
        throttle = 1500,
        debounce = 600,
        request_timeout = 5,
        n_completions = 3,
        context_window = 16000,
        context_ratio = 0.75,
      }, m.tuning or {})

      require('minuet').setup {
        -- Provider + provider-specific options come from the selected model
        -- entry above, so FIM and chat models can coexist and be picked per
        -- project without touching this call.
        provider = m.provider,
        provider_options = {
          [m.provider] = m.provider_options,
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
        -- Values come from the per-model `tuning` table (merged over shared
        -- defaults), so each model gets appropriate throttle/latency settings.
        throttle = tuning.throttle,
        debounce = tuning.debounce,
        -- Max seconds to wait for a completion. The blink `minuet` provider's
        -- `timeout_ms` in lsp.lua is a generous upper bound that covers this.
        request_timeout = tuning.request_timeout,

        -- Number of completion items to request per invocation.
        n_completions = tuning.n_completions,

        -- Context window size (characters). Larger = more context but slower.
        context_window = tuning.context_window,

        -- Ratio of pre-cursor vs post-cursor context when trimming to fit.
        context_ratio = tuning.context_ratio,

        -- Add a single-line entry alongside multi-line completions for
        -- smoother blink.cmp / virtual text experience.
        add_single_line_entry = true,

        -- Notification level: only show warnings and errors.
        notify = 'warn',
      }
    end,
  },
}
