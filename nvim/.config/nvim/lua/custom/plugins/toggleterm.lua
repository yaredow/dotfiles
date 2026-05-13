vim.pack.add { 'https://github.com/akinsho/toggleterm.nvim' }

require('toggleterm').setup {
  open_mapping = nil, -- we handle mappings ourselves
  direction = 'horizontal',
  size = 15,
  start_in_insert = true,
  close_on_exit = true,
}

function _G.set_terminal_keymaps()
  local opts = { buffer = 0 }
  vim.keymap.set('t', '<esc>', [[<C-\><C-n>]], opts)
  vim.keymap.set('t', '<C-h>', [[<Cmd>wincmd h<CR>]], opts)
  vim.keymap.set('t', '<C-j>', [[<Cmd>wincmd j<CR>]], opts)
  vim.keymap.set('t', '<C-k>', [[<Cmd>wincmd k<CR>]], opts)
  vim.keymap.set('t', '<C-l>', [[<Cmd>wincmd l<CR>]], opts)
end

vim.api.nvim_create_autocmd('TermOpen', {
  pattern = 'term://*toggleterm#*',
  callback = function() set_terminal_keymaps() end,
})

vim.keymap.set({ 'n', 't' }, '<leader>tt', '<Cmd>ToggleTermToggleAll<CR>', { desc = 'Toggle all terminals' })
vim.keymap.set({ 'n', 't' }, '<leader>tn', '<Cmd>TermNew<CR>', { desc = 'New terminal' })
vim.keymap.set('n', '<leader>ts', '<Cmd>TermSelect<CR>', { desc = 'Select terminal' })
vim.keymap.set({ 'n', 't' }, '<c-/>', '<Cmd>ToggleTerm<CR>', { desc = 'Toggle terminal' })
