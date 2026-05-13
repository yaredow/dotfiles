vim.pack.add { 'https://github.com/folke/trouble.nvim' }

require('trouble').setup {}

vim.keymap.set('n', '<leader>xx', function() require('trouble').toggle() end, { desc = 'Trouble: Toggle' })
vim.keymap.set('n', '<leader>xw', function() require('trouble').toggle('workspace_diagnostics') end, { desc = 'Trouble: Workspace diagnostics' })
vim.keymap.set('n', '<leader>xd', function() require('trouble').toggle('document_diagnostics') end, { desc = 'Trouble: Document diagnostics' })
vim.keymap.set('n', '<leader>xq', function() require('trouble').toggle('quickfix') end, { desc = 'Trouble: Quickfix' })
