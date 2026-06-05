vim.pack.add { 'https://github.com/folke/snacks.nvim' }

require('mini.icons').setup()

local ok, snacks = pcall(require, 'snacks')
if not ok then
  return
end

--- Snacks adds `1: user@host:path` to the winbar on split terminals; see:
--- https://github.com/folke/snacks.nvim/discussions/2125
local function terminal_win_opts(extra)
  return vim.tbl_deep_extend('force', {
    position = 'bottom',
    height = 0.3,
    wo = { winbar = '' },
    on_win = function(self)
      if self.win and vim.api.nvim_win_is_valid(self.win) then
        vim.wo[self.win].winbar = ''
      end
    end,
  }, extra or {})
end

--- Next unused terminal slot (Snacks keys terminals by `count`).
local function next_terminal_count()
  local max = 0
  for _, term in ipairs(snacks.terminal.list()) do
    local meta = term.buf and vim.b[term.buf].snacks_terminal
    if meta and meta.id then
      max = math.max(max, meta.id)
    end
  end
  return max + 1
end

snacks.setup {
  bigfile = { enabled = true },
  dashboard = {
    enabled = true,
    sections = {
      { section = 'header' },
      { section = 'keys', gap = 1, padding = 1 },
      { section = 'recent_files', limit = 5, cwd = true },
    },
  },
  picker = {
    sources = {
      explorer = {
        layout = { layout = { position = 'right' } },
      },
    },
  },
  notifier = { enabled = true, timeout = 3000 },
  terminal = {
    enabled = true,
    win = terminal_win_opts(),
  },
  indent = { enabled = true },
  input = { enabled = true },
  quickfile = { enabled = true },
  scope = { enabled = true },
  scroll = { enabled = true },
  statuscolumn = { enabled = true },
  words = { enabled = true },
  zen = { enabled = true },
}

-- Terminal: bottom split by default; each `count` is a separate session
vim.keymap.set('n', '<leader>th', function()
  snacks.terminal.toggle(nil, { win = terminal_win_opts() })
end, { desc = '[T]erminal toggle' })
vim.keymap.set('t', '<leader>th', function()
  local cur_buf = vim.api.nvim_get_current_buf()
  for _, t in ipairs(snacks.terminal.list()) do
    if t.buf == cur_buf then
      t:toggle()
      return
    end
  end
  snacks.terminal.toggle()
end, { desc = '[T]erminal toggle' })

vim.keymap.set('n', '<leader>tn', function()
  snacks.terminal.open(nil, {
    count = next_terminal_count(),
    win = terminal_win_opts(),
  })
end, { desc = '[T]erminal [N]ew' })
vim.keymap.set('t', '<leader>tn', function()
  snacks.terminal.open(nil, {
    count = next_terminal_count(),
    win = terminal_win_opts(),
  })
end, { desc = '[T]erminal [N]ew' })

-- snacks.terminal sets winbar after open; clear it (see discussion #2125)
local function clear_terminal_winbar(buf, win)
  if vim.bo[buf].filetype ~= 'snacks_terminal' then
    return
  end
  local wins = win and { win } or vim.fn.win_findbuf(buf)
  for _, w in ipairs(wins) do
    if vim.api.nvim_win_is_valid(w) then
      vim.wo[w].winbar = ''
    end
  end
end

vim.api.nvim_create_autocmd('TermOpen', {
  callback = function(ev)
    -- filetype is set shortly after TermOpen; run twice to beat snacks.winbar assignment
    vim.schedule(function() clear_terminal_winbar(ev.buf) end)
    vim.defer_fn(function() clear_terminal_winbar(ev.buf) end, 50)
  end,
})

vim.api.nvim_create_autocmd('BufWinEnter', {
  callback = function(ev)
    clear_terminal_winbar(ev.buf, ev.win)
  end,
})
