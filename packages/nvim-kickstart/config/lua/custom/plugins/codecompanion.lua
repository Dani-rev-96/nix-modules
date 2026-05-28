return {
  {
    'olimorris/codecompanion.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-treesitter/nvim-treesitter',
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
