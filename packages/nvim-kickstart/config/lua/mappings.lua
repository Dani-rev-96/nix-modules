local map = vim.keymap.set

map('n', '<tab>', function()
  require('nvchad.tabufline').next()
end, { desc = 'buffer goto next' })

map('n', '<S-tab>', function()
  require('nvchad.tabufline').prev()
end, { desc = 'buffer goto prev' })

map('n', '<leader>x', function()
  require('nvchad.tabufline').close_buffer()
end, { desc = 'buffer close' })

map('n', '<leader>tc', '<cmd>NvCheatsheet<CR>', { desc = 'toggle nvcheatsheet' })

map('n', '<leader>sGc', function() require('fzf-lua').git_commits() end, { desc = '[G]it [C]ommits' })
map('n', '<leader>sGt', function() require('fzf-lua').git_status() end, { desc = '[G]it [S]tatus' })

-- terminal
map('t', '<C-x>', '<C-\\><C-N>', { desc = 'terminal escape terminal mode' })

-- new terminals
map('n', '<leader>H', function()
  require('nvchad.term').new { pos = 'sp' }
end, { desc = 'terminal new horizontal term' })

map('n', '<leader>V', function()
  require('nvchad.term').new { pos = 'vsp' }
end, { desc = 'terminal new vertical term' })

-- toggleable
map({ 'n', 't' }, '<A-v>', function()
  require('nvchad.term').toggle { pos = 'vsp', id = 'vtoggleTerm' }
end, { desc = 'terminal toggleable vertical term' })

map({ 'n', 't' }, '<A-h>', function()
  require('nvchad.term').toggle { pos = 'sp', id = 'htoggleTerm' }
end, { desc = 'terminal toggleable horizontal term' })

map({ 'n', 't' }, '<A-i>', function()
  require('nvchad.term').toggle { pos = 'float', id = 'floatTerm' }
end, { desc = 'terminal toggle floating term' })

-- CodeCompanion
map({ 'n', 'v' }, '<C-a>', '<cmd>CodeCompanionActions<cr>', { desc = 'CodeCompanion actions' })
map({ 'n', 'v' }, '<leader>cc', '<cmd>CodeCompanionChat Toggle<cr>', { desc = 'CodeCompanion chat toggle' })
map('v', 'ga', '<cmd>CodeCompanionChat Add<cr>', { desc = 'CodeCompanion add to chat' })
