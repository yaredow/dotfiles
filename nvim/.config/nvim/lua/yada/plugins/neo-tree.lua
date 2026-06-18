return {
  'nvim-neo-tree/neo-tree.nvim',
  dependencies = {
    'MunifTanjim/nui.nvim',
  },
  keys = {
    { '<leader>e', '<cmd>Neotree position=right toggle<cr>', desc = 'File explorer toggle' },
  },
  opts = {
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
  },
}
