return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    lazy = false,
    config = function()
      require("neo-tree").setup({
        window = {
          position = "right",
          mappings = {
            ["h"] = "close_node",
            ["l"] = "open",
          },
        },
        default_component_config = {
          name = {
            format = function(config, node)
              local name = node.name
              if node:get_depth() == 1 then
                name = vim.fn.fnamemodify(node.path, ":t") .. "/"
              end
              return name
            end,
          },
        },
      })
    end,
  }
}
