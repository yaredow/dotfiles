vim.pack.add {
  'https://github.com/folke/noice.nvim',
  'https://github.com/MunifTanjim/nui.nvim',
  'https://github.com/nvim-lua/plenary.nvim',
}

require('noice').setup {
  presets = {
    bottom_search = true,
    command_palette = true,
    long_message_to_split = true,
    lsp_doc_border = true,
  },
}
