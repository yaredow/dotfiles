vim.pack.add { 'https://github.com/nvim-neo-tree/neo-tree.nvim' }

require('neo-tree').setup {
  window = {
    position = 'right',
  },
  filesystem = {
    hijack_netrw_behavior = 'open_default',
    follow_current_file = {
      enabled = true,
      leave_dirs_open = false,
    },
    window = {
      mappings = {
        ['h'] = 'close_node',
        ['l'] = 'open',
      },
    },
  },
}

vim.keymap.set('n', '<leader>e', '<cmd>Neotree position=right toggle<cr>', { desc = 'File explorer toggle', silent = true })
