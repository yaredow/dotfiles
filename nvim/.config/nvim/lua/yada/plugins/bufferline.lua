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

-- Buffer navigation
vim.keymap.set('n', ']b', '<cmd>BufferLineCycleNext<cr>', { desc = 'Next buffer' })
vim.keymap.set('n', '[b', '<cmd>BufferLineCyclePrev<cr>', { desc = 'Prev buffer' })
vim.keymap.set('n', '<S-l>', '<cmd>BufferLineCycleNext<cr>', { desc = 'Next buffer' })
vim.keymap.set('n', '<S-h>', '<cmd>BufferLineCyclePrev<cr>', { desc = 'Prev buffer' })
vim.keymap.set('n', '>b', '<cmd>BufferLineMoveNext<cr>', { desc = 'Move buffer right' })
vim.keymap.set('n', '<b', '<cmd>BufferLineMovePrev<cr>', { desc = 'Move buffer left' })

vim.keymap.set('n', '<leader>bn', '<cmd>BufferLineCycleNext<cr>', { desc = 'Next buffer' })
vim.keymap.set('n', '<leader>bp', '<cmd>BufferLineCyclePrev<cr>', { desc = 'Prev buffer' })
vim.keymap.set('n', '<leader>bP', '<cmd>BufferLinePick<cr>', { desc = 'Pick buffer' })
vim.keymap.set('n', '<leader>bd', function() require('mini.bufremove').delete() end, { desc = 'Delete buffer' })
vim.keymap.set('n', '<leader>bc', function() require('mini.bufremove').delete(0, true) end, { desc = 'Close other buffers' })
vim.keymap.set('n', '<leader>bC', function()
  -- bufferline stores pinned buffers in `vim.g.BufferlinePinnedBuffers` as
  -- a comma-separated list of file paths (no public getter for bufnrs).
  local pin_names = {}
  for name in tostring(vim.g.BufferlinePinnedBuffers or ''):gmatch('[^,]+') do
    pin_names[name] = true
  end
  local current = vim.api.nvim_get_current_buf()
  for _, b in ipairs(vim.fn.getbufinfo { buflisted = 1 }) do
    if b.bufnr ~= current and not pin_names[b.name] then
      require('mini.bufremove').delete(b.bufnr, true)
    end
  end
end, { desc = 'Close all but pinned' })
