vim.pack.add { 'https://github.com/akinsho/bufferline.nvim' }

require('bufferline').setup {
  options = {
    mode = 'buffers',
    separator_style = 'thin',
    show_buffer_close_icons = false,
    show_close_icon = false,
    close_command = function(n) require('mini.bufremove').delete(n, true) end,
    right_mouse_command = function(n) require('mini.bufremove').delete(n, true) end,
    diagnostics = 'nvim_lsp',
    show_buffer_icon = vim.g.have_nerd_font,
  },
}

-- AstroNvim-style buffer navigation
vim.keymap.set('n', ']b', '<cmd>BufferLineCycleNext<cr>', { desc = 'Next buffer' })
vim.keymap.set('n', '[b', '<cmd>BufferLineCyclePrev<cr>', { desc = 'Prev buffer' })
vim.keymap.set('n', '<S-l>', '<cmd>BufferLineCycleNext<cr>', { desc = 'Next buffer' })
vim.keymap.set('n', '<S-h>', '<cmd>BufferLineCyclePrev<cr>', { desc = 'Prev buffer' })
vim.keymap.set('n', '>b', '<cmd>BufferLineMoveNext<cr>', { desc = 'Move buffer right' })
vim.keymap.set('n', '<b', '<cmd>BufferLineMovePrev<cr>', { desc = 'Move buffer left' })

vim.keymap.set('n', '<leader>bp', '<cmd>BufferLinePick<cr>', { desc = 'Pick buffer' })
vim.keymap.set('n', '<leader>bd', function() require('mini.bufremove').delete() end, { desc = 'Delete buffer' })
vim.keymap.set('n', '<leader>bc', function() require('mini.bufremove').delete(0, true) end, { desc = 'Close other buffers' })
vim.keymap.set('n', '<leader>bC', function() vim.cmd('BufferLineCloseAllButPinned') end, { desc = 'Close all but pinned' })
