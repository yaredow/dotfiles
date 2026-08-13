return {
  'akinsho/bufferline.nvim',
  event = 'VeryLazy',
  dependencies = {
    'nvim-mini/mini.bufremove',
  },
  keys = {
    { '<leader>bn', '<cmd>BufferLineCycleNext<cr>', desc = 'Next buffer' },
    { '<leader>bp', '<cmd>BufferLineCyclePrev<cr>', desc = 'Prev buffer' },
    { '<leader>bP', '<cmd>BufferLinePick<cr>', desc = 'Pick buffer' },
    { '<leader>bd', function() require('mini.bufremove').delete() end, desc = 'Delete buffer' },
    { '<leader>bc', function() require('mini.bufremove').delete(0, true) end, desc = 'Close other buffers' },
    { '<leader>bC', function()
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
    end, desc = 'Close all but pinned' },
    { '<S-l>', '<cmd>BufferLineCycleNext<cr>', desc = 'Next buffer' },
    { '<S-h>', '<cmd>BufferLineCyclePrev<cr>', desc = 'Prev buffer' },
    { ']b', '<cmd>BufferLineCycleNext<cr>', desc = 'Next buffer' },
    { '[b', '<cmd>BufferLineCyclePrev<cr>', desc = 'Prev buffer' },
    { '>b', '<cmd>BufferLineMoveNext<cr>', desc = 'Move buffer right' },
    { '<b', '<cmd>BufferLineMovePrev<cr>', desc = 'Move buffer left' },
  },
  opts = {
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
  },
}
