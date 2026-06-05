vim.pack.add { 'https://github.com/supermaven-inc/supermaven-nvim' }

require('supermaven-nvim').setup {
  keymaps = {
    accept_suggestion = '<Tab>',
    clear_suggestion = '<C-]>',
    accept_word = '<C-n>',
  },
  ignore_filetypes = { 'snacks_terminal' },
}
