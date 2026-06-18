return {
  'akinsho/toggleterm.nvim',
  keys = {
    { '<leader>th', '<cmd>ToggleTerm<cr>', desc = '[T]erminal toggle', mode = { 'n', 't' } },
    { '<leader>tn', '<cmd>2ToggleTerm<cr>', desc = '[T]erminal [N]ew', mode = { 'n', 't' } },
  },
  opts = {
    size = function(term)
      if term.direction == 'horizontal' then
        return math.floor(vim.o.lines * 0.3)
      elseif term.direction == 'vertical' then
        return math.floor(vim.o.columns * 0.3)
      end
    end,
    open_mapping = nil,
    direction = 'horizontal',
    close_on_exit = true,
    start_in_insert = true,
    persist_size = false,
    shade_terminals = false,
  },
}
