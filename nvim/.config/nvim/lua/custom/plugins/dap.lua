vim.pack.add {
  'https://github.com/mfussenegger/nvim-dap',
  'https://github.com/leoluz/nvim-dap-go',
  'https://github.com/rcarriga/nvim-dap-ui',
  'https://github.com/nvim-neotest/nvim-nio',
}

require('dap-go').setup {}

local dap = require 'dap'
local dapui = require 'dapui'

dapui.setup()

dap.listeners.after.event_initialized['dapui_config'] = function() dapui.open() end
dap.listeners.after.event_terminated['dapui_config'] = function() dapui.close() end
dap.listeners.after.event_exited['dapui_config'] = function() dapui.close() end

vim.keymap.set('n', '<F5>', dap.continue, { desc = 'DAP: Continue' })
vim.keymap.set('n', '<F10>', dap.step_over, { desc = 'DAP: Step over' })
vim.keymap.set('n', '<F11>', dap.step_into, { desc = 'DAP: Step into' })
vim.keymap.set('n', '<F12>', dap.step_out, { desc = 'DAP: Step out' })
vim.keymap.set('n', '<leader>db', dap.toggle_breakpoint, { desc = 'DAP: Toggle breakpoint' })
vim.keymap.set('n', '<leader>dB', function() dap.set_breakpoint(vim.fn.input 'Breakpoint condition: ') end, { desc = 'DAP: Conditional breakpoint' })
vim.keymap.set('n', '<leader>dr', dap.repl.open, { desc = 'DAP: Open REPL' })
vim.keymap.set('n', '<leader>du', dapui.toggle, { desc = 'DAP: Toggle UI' })
vim.keymap.set('n', '<leader>dt', function() require('dap-go').debug_test() end, { desc = 'DAP: Debug nearest test' })
vim.keymap.set('n', '<leader>dl', function() require('dap-go').debug_last_test() end, { desc = 'DAP: Debug last test' })
