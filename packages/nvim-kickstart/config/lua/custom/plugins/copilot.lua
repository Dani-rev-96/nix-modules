-- GitHub Copilot stack (blink.cmp completion source + chat).
--
-- Gated by the per-project AI selection resolved in init.lua:
--   completion (copilot.lua + blink-copilot) -> vim.g.ai_completion == 'copilot'
--   chat (CopilotChat.nvim)                  -> vim.g.ai_chat == 'copilot'
--
-- Completion is wired through blink.cmp: copilot.lua runs only as the LSP
-- backend (its own inline ghost text + panel are disabled) and `blink-copilot`
-- exposes it as the `copilot` source, registered in lsp.lua when this mode is
-- active. Copilot suggestions therefore appear in the normal blink completion
-- menu and are accepted with blink's usual keymap (<C-y>), not a separate key.
--
-- Nothing here is downloaded or loaded unless the active mode enables it, so
-- `none` / `minuet` projects pay no Copilot cost.
-- Switch modes with `$NVIM_AI` or a `.nvim-profile` file (see init.lua).
return {
  {
    'zbirenbaum/copilot.lua',
    enabled = vim.g.ai_completion == 'copilot',
    cmd = 'Copilot',
    event = 'InsertEnter',
    opts = {
      -- Suggestions are surfaced through blink.cmp (blink-copilot), so disable
      -- copilot.lua's own inline UI to avoid duplicate ghost text next to the
      -- completion menu. The LSP client still runs and feeds blink-copilot.
      suggestion = { enabled = false },
      panel = { enabled = false },
    },
  },
  {
    -- blink.cmp source that turns the Copilot LSP into menu completions.
    -- Loaded on demand when blink requires the `blink-copilot` module.
    'fang2hou/blink-copilot',
    enabled = vim.g.ai_completion == 'copilot',
    dependencies = { 'zbirenbaum/copilot.lua' },
  },
  {
    'CopilotC-Nvim/CopilotChat.nvim',
    enabled = vim.g.ai_chat == 'copilot',
    dependencies = {
      { 'zbirenbaum/copilot.lua' },
      { 'nvim-lua/plenary.nvim', branch = 'master' },
    },
    build = 'make tiktoken',
    opts = {
      -- See CopilotChat.nvim Configuration section for options
    },
  },
}
