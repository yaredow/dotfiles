vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

vim.pack.add({
  {
    src = "https://github.com/nvim-neo-tree/neo-tree.nvim",
    version = vim.version.range("3"),
  },
  "https://github.com/nvim-lua/plenary.nvim",
  "https://github.com/MunifTanjim/nui.nvim",
  "https://github.com/nvim-tree/nvim-web-devicons",
})

require('neo-tree').setup({
  -- You can add more config here later
  close_if_last_window = false,

  window = {
    position = "right",
    width = 35,
    mappings = {
      ["<space>"] = "none",     -- free up space (you use it as leader)
      ["l"] = "open",            -- open folder / file
      ["h"] = "close_node",      -- close folder
    },
  },
  
  filesystem = {
    follow_current_file = { enabled = true },
    use_libuv_file_watcher = true,
  },
})


vim.keymap.set('n', '<leader>e', function()
  require('neo-tree.command').execute({ toggle = true, source = "filesystem", position = "right" })
end, { desc = 'Neo-tree: Toggle' })

vim.keymap.set('n', '<leader>o', function()
  require('neo-tree.command').execute({ focus = true, source = "filesystem" })
end, { desc = 'Neo-tree: Focus' })
