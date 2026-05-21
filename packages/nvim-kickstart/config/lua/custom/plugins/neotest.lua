return {
  {
    'nvim-neotest/neotest',
    dependencies = {
      'nvim-neotest/nvim-nio',
      'nvim-lua/plenary.nvim',
      'antoinemadec/FixCursorHold.nvim',
      'nvim-telescope/telescope.nvim',
      'marilari88/neotest-vitest',
      'thenbe/neotest-playwright',
      'rcasia/neotest-java',
    },
    keys = {
      { '<leader>Tn', function() require('neotest').run.run() end, desc = 'Run nearest test' },
      { '<leader>Tf', function() require('neotest').run.run(vim.fn.expand '%') end, desc = 'Run current file' },
      { '<leader>Ts', function() require('neotest').run.run { suite = true } end, desc = 'Run test suite' },
      { '<leader>Tl', function() require('neotest').run.run_last() end, desc = 'Re-run last test' },
      { '<leader>Td', function() require('neotest').run.run { strategy = 'dap' } end, desc = 'Debug nearest test' },
      { '<leader>Tx', function() require('neotest').run.stop() end, desc = 'Stop running test' },
      { '<leader>Ta', function() require('neotest').run.attach() end, desc = 'Attach to running test' },
      { '<leader>To', function() require('neotest').output_panel.toggle() end, desc = 'Toggle output panel' },
      { '<leader>TO', function() require('neotest').output.open { enter = true, auto_close = true } end, desc = 'Show test output (float)' },
      { '<leader>TS', function() require('neotest').summary.toggle() end, desc = 'Toggle summary' },
      { '<leader>Tw', function() require('neotest').watch.toggle() end, desc = 'Watch nearest test' },
      { '<leader>TW', function() require('neotest').watch.toggle(vim.fn.expand '%') end, desc = 'Watch current file' },
    },
    config = function()
      ---@diagnostic disable-next-line: missing-fields
      require('neotest').setup {
        log_level = vim.log.levels.WARN,
        status = {
          enabled = true,
          signs = true,
          virtual_text = true,
        },
        output = {
          enabled = true,
          open_on_run = false,
        },
        output_panel = {
          enabled = true,
          open = 'botright split | resize 15',
        },
        diagnostic = {
          enabled = true,
          severity = vim.diagnostic.severity.ERROR,
        },
        summary = {
          enabled = true,
          animated = true,
          expand_errors = true,
          follow = true,
          mappings = {
            expand = { '<CR>', '<2-LeftMouse>' },
            expand_all = 'e',
            jumpto = 'i',
            output = 'o',
            run = 'r',
            stop = 'u',
            short = 'O',
            attach = 'a',
            watch = 'w',
          },
        },
        icons = {
          passed = '✓',
          failed = '✗',
          running = '⟳',
          skipped = '○',
          unknown = '?',
        },
        adapters = {
          require 'neotest-vitest' {
            filter_dir = function(name, _rel_path, _root)
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
          --   incremental_build = true,
          -- },
        },
      }
    end,
  },
}
