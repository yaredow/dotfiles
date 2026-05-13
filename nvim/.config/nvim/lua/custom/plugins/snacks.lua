vim.pack.add { 'https://github.com/folke/snacks.nvim' }

require('snacks').setup {
  dashboard = {
    enabled = true,
    sections = {
      { section = 'header' },
      { section = 'keys', gap = 1, padding = 1 },
    },
  },
  notifier = { enabled = true },
  lazygit = { enabled = true },
}

vim.keymap.set('n', '<leader>gg', function() Snacks.lazygit() end, { desc = 'Lazygit' })
