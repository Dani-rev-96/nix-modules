return {
  'nvim-lua/plenary.nvim',
  { 'nvim-tree/nvim-web-devicons' },

  {
    'nvchad/base46',
    build = function()
      require('base46').load_all_highlights()
    end,
  },

  {
    'nvchad/ui',
    config = function()
      require 'nvchad'
    end,
  },

  'nvchad/volt', -- optional, needed for theme switcher
  -- or just use Telescope themes
}
