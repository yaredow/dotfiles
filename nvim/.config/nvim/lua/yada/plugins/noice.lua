return {
  'folke/noice.nvim',
  dependencies = {
    'MunifTanjim/nui.nvim',
    'nvim-lua/plenary.nvim',
  },
  event = 'VeryLazy',
  opts = {
    cmdline = { view = 'cmdline_popup' },
    views = {
      cmdline_popup = { position = { row = 5, col = '50%' } },
    },
  },
}
