vim.pack.add {
  'https://github.com/folke/noice.nvim',
  'https://github.com/MunifTanjim/nui.nvim',
  'https://github.com/nvim-lua/plenary.nvim',
}

require('noice').setup {
  cmdline = { view = 'cmdline_popup' },
  views = {
    cmdline_popup = { position = { row = 5, col = '50%' } },
  },
}
