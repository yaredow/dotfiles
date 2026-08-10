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
    event_handlers = {
      {
        event = 'before_render',
        handler = function(state)
          if not state._short_root_name then
            local original_name = state.components.name
            state.components.name = function(config, node, s)
              local result = original_name(config, node, s)
              if result and result.text and node:get_depth() == 1 then result.text = vim.fn.fnamemodify(result.text, ':t') end
              return result
            end
            state._short_root_name = true
          end
        end,
      },
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
