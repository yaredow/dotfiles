vim.pack.add({ {
    src = "https://github.com/kylechui/nvim-surround",
    version = vim.version.range("4.x"),
    hooks = {
        init = function(spec)
            require("nvim-surround").setup()
            -- Set up keymaps for v4
            vim.keymap.set("v", "W", require("nvim-surround").visual_surround, { noremap = true, silent = true })
        end,
    },
} })
