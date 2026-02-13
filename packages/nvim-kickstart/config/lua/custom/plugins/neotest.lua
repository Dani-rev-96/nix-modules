local map = vim.keymap.set
return {
  {
    'nvim-neotest/neotest',
    dependencies = {
      'nvim-neotest/nvim-nio',
      'nvim-lua/plenary.nvim',
      'antoinemadec/FixCursorHold.nvim',
      'nvim-treesitter/nvim-treesitter',
      'marilari88/neotest-vitest',
      'thenbe/neotest-playwright',
      'rcasia/neotest-java',
      dependencies = 'nvim-telescope/telescope.nvim',
    },
    config = function()
      require('neotest').setup {
        adapters = {
          require 'neotest-vitest' {
            filter_dir = function(name, rel_path, root)
              return name ~= 'node_modules'
            end,
          },
          require('neotest-playwright').adapter {
            options = {
              persist_project_selection = true,
              enable_dynamic_test_discovery = true,
            },
          },
          -- require 'neotest-java' {
          --   -- config here
          --   incremental_build = true,
          -- },
        },
      }
      map('n', '<leader>Tn', function()
        require('neotest').run.run()
      end, { desc = 'neotest run nearest test' })
      --debug
      map('n', '<leader>Td', function()
        require('neotest').run.run { strategy = 'dap' }
      end, { desc = 'neotest debug nearest test' })
    end,
  },
}
