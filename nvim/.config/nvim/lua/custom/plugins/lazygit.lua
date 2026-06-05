vim.pack.add { 'https://github.com/kdheepak/lazygit.nvim' }

vim.keymap.set('n', '<leader>gg', function() lazygit() end, { desc = 'Open lazygit' })
