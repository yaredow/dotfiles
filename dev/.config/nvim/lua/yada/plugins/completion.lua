return {
  -- LuaSnip
  {
    'L3MON4D3/LuaSnip',
    build = function()
      if vim.fn.has 'win32' == 1 then return end
      return 'make install_jsregexp'
    end,
    opts = { history = true, updateevents = 'TextChanged,TextChangedI' },
    config = function(_, opts)
      require('luasnip').setup(opts)
    end,
  },

  -- Blink.cmp
  {
    'saghen/blink.cmp',
    event = 'InsertEnter',
    dependencies = {
      'L3MON4D3/LuaSnip',
      'saghen/blink.lib',
    },
    opts = {
      keymap = {
        preset = 'enter',
        ['<Tab>'] = {
          function(cmp)
            local ok, sm = pcall(require, 'supermaven-nvim.completion_preview')
            if ok and sm.has_suggestion() then
              vim.schedule(function() sm.on_accept_suggestion() end)
              return true
            end
            return cmp.select_next()
          end,
          'fallback',
        },
        ['<C-j>'] = { 'select_next', 'fallback' },
        ['<C-k>'] = { 'select_prev', 'fallback' },
      },
      appearance = {
        nerd_font_variant = 'mono',
      },
      completion = {
        list = { selection = { preselect = true } },
        accept = { auto_brackets = { enabled = false } },
        documentation = { auto_show = false, auto_show_delay_ms = 500 },
      },
      sources = { default = { 'lsp', 'path', 'snippets' } },
      snippets = { preset = 'luasnip' },
      fuzzy = { implementation = 'lua' },
      signature = { enabled = true },
    },
  },
}
