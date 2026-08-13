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
      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns
        if not gs then return end
        local function map(lhs, rhs, desc)
          vim.keymap.set('n', lhs, rhs, { buffer = bufnr, desc = desc })
        end
        map(']h', gs.next_hunk, 'Next hunk')
        map('[h', gs.prev_hunk, 'Prev hunk')
        map('<leader>hs', gs.stage_hunk, '[H]unk stage')
        map('<leader>hr', gs.reset_hunk, '[H]unk reset')
        map('<leader>hS', gs.stage_buffer, '[H]unk stage buffer')
        map('<leader>hp', gs.preview_hunk, '[H]unk preview')
        map('<leader>hb', function() gs.blame_line { full = true } end, '[H]unk blame line')
      end,
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
      vim.keymap.set('x', 'W', 'sa', { remap = true, desc = 'Wrap with surrounding' })
    end,
  },

  -- Fidget (LSP progress)
  { 'j-hui/fidget.nvim', event = 'LspAttach', opts = {} },
}
