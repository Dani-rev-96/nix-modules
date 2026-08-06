return {
  {
    'olimorris/codecompanion.nvim',
    -- Gated by the per-project AI selection resolved in init.lua.
    -- Only loads when the active mode selects the self-hosted chat backend.
    enabled = vim.g.ai_chat == 'codecompanion',
    dependencies = {
      'nvim-lua/plenary.nvim',
      -- NOTE: Do NOT depend on 'nvim-treesitter/nvim-treesitter' here.
      -- Loading that plugin registers custom query predicate/directive handlers
      -- (query_predicates.lua) that conflict with Neovim 0.12's native treesitter
      -- injection processing, crashing on html_tags injections in .vue files.
      -- CodeCompanion works with the native parsers provided via Nix.
    },
    opts = {
      adapters = {
        http = {
          lemonade = function()
            return require('codecompanion.adapters').extend('openai_compatible', {
              env = {
                url = 'https://lemonade.dani-home.de',
                api_key = 'LEMONADE_API_KEY',
                chat_url = '/v1/chat/completions',
                models_endpoint = '/v1/models',
              },
              schema = {
                model = {
                  default = 'Qwen3.6-35B-A3B-Claude-4.7:Q8_0',
                },
              },
            })
          end,
        },
      },
      interactions = {
        chat = {
          adapter = 'lemonade',
        },
        inline = {
          adapter = 'lemonade',
        },
        cmd = {
          adapter = 'lemonade',
        },
      },
    },
  },
}
