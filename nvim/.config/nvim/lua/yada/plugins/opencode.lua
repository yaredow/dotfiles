vim.pack.add { 'https://github.com/nickjvandyke/opencode.nvim' }

vim.g.opencode_opts = {
  server = {
    start = function()
      vim.cmd 'leftabove vsplit term://opencode --port'
    end,
  },
}

vim.o.autoread = true

local function toggle_opencode()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.api.nvim_buf_get_name(buf):match 'term://.*opencode' then
      vim.api.nvim_win_close(win, true)
      return
    end
  end
  vim.g.opencode_opts.server.start()
end

vim.keymap.set('n', '<leader>aa', toggle_opencode, { desc = 'Toggle OpenCode' })
