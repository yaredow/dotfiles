return {
  'folke/snacks.nvim',
  dependencies = {
    { 'nvim-mini/mini.icons', opts = {} },
  },
  opts = {
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
    terminal = { enabled = false },
    indent = { enabled = true },
    input = { enabled = true },
    quickfile = { enabled = true },
    scope = { enabled = true },
    scroll = { enabled = true },
    statuscolumn = { enabled = true },
    words = { enabled = true },
    zen = { enabled = true },
  },
}
