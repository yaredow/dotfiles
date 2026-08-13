return {
  {
    'folke/flash.nvim',
    event = 'VeryLazy',
    opts = { modes = { jump = { search = { mode = 'search' } } } },
    keys = {
      { 's', function() require('flash').jump() end, desc = 'Flash', mode = { 'n', 'x', 'o' } },
      { 'S', function() require('flash').treesitter() end, desc = 'Flash Treesitter', mode = { 'n', 'x', 'o' } },
      { 'r', function() require('flash').remote() end, desc = 'Remote Flash', mode = 'o' },
    },
  },
}
