local function read_active()
  local f = io.open(vim.fn.stdpath('config') .. '/lua/theme.lua', 'r')
  if not f then return 'tokyonight-night' end
  local content = f:read '*a'
  f:close()
  return content:match('return "(.+)"') or 'tokyonight-night'
end
local active = read_active()

local function colorscheme_spec(plugin, name, colorscheme, opts, setup)
  return {
    plugin,
    name = name,
    lazy = active ~= colorscheme,
    priority = active == colorscheme and 1000 or nil,
    opts = opts,
    config = function(_, o) setup(o) end,
  }
end

return {
  -- Guess indentation
  { 'NMAC427/guess-indent.nvim', opts = {} },

  -- File icons
  { 'nvim-tree/nvim-web-devicons', lazy = true },

  -- Git signs
  {
    'lewis6991/gitsigns.nvim',
    event = 'BufReadPost',
    opts = {
      signs = {
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },
    },
  },

  -- Which-key
  {
    'folke/which-key.nvim',
    event = 'VeryLazy',
    opts = {
      delay = 0,
      icons = { mappings = vim.g.have_nerd_font },
      spec = {
        { '<leader>s', group = '[S]earch', mode = { 'n', 'v' } },
        { '<leader>t', group = '[T]erminal' },
        { '<leader>b', group = '[B]uffer' },
        { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } },
        { '<leader>l', group = '[L]SP' },
      },
    },
  },

  -- Colorschemes
  colorscheme_spec('folke/tokyonight.nvim', nil, 'tokyonight-night',
    { styles = { comments = { italic = false } } },
    function(opts) require('tokyonight').setup(opts) end),

  colorscheme_spec('catppuccin/nvim', 'catppuccin', 'catppuccin-mocha',
    { flavour = 'mocha' },
    function(opts) require('catppuccin').setup(opts) end),

  colorscheme_spec('ellisonleao/gruvbox.nvim', 'gruvbox', 'gruvbox',
    { contrast = 'hard', transparent_mode = false },
    function(opts) require('gruvbox').setup(opts) end),

  -- Todo comments
  { 'folke/todo-comments.nvim', event = 'BufReadPost', opts = { signs = false } },

  -- Mini.nvim
  {
    'nvim-mini/mini.nvim',
    event = 'VeryLazy',
    config = function()
      require('mini.ai').setup {
        mappings = { around_next = 'aa', inside_next = 'ii' },
        n_lines = 500,
      }
      require('mini.surround').setup()
      local statusline = require 'mini.statusline'
      statusline.setup { use_icons = vim.g.have_nerd_font }
      statusline.section_location = function() return '%2l:%-2v' end
    end,
  },

  -- Fidget (LSP progress)
  { 'j-hui/fidget.nvim', event = 'LspAttach', opts = {} },
}
