vim.pack.add { 'https://github.com/folke/snacks.nvim' }

require('mini.icons').setup()

local ok, snacks = pcall(require, 'snacks')
if ok then
  snacks.setup {
  bigfile = { enabled = true },
  dashboard = {
    enabled = true,
    sections = {
      { section = 'header' },
      { section = 'keys', gap = 1, padding = 1 },
      { section = 'recent_files', limit = 5, cwd = true },
    },
  },
  explorer = { enabled = true, replace_netrw = true },
  picker = {
    sources = {
      explorer = {
        layout = { layout = { position = 'right' } },
      },
    },
  },
  notifier = { enabled = true, timeout = 3000 },
  terminal = { enabled = true },
  indent = { enabled = true },
  input = { enabled = true },
  quickfile = { enabled = true },
  scope = { enabled = true },
  scroll = { enabled = true },
  statuscolumn = { enabled = true },
  words = { enabled = true },
  zen = { enabled = true },
  lazygit = { enabled = true },
}

  vim.keymap.set('n', '<leader>e', function() snacks.explorer() end, { desc = 'Explorer toggle', silent = true })
end
