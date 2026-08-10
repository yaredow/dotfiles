-- ============================================================
-- LEADER KEYS (must be set before lazy.nvim)
-- ============================================================
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Set if you have a Nerd Font in your terminal
vim.g.have_nerd_font = true

-- ============================================================
-- DISABLE NETRW (must be set before plugins load)
-- ============================================================
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- ============================================================
-- LAZY.NVIM (bootstrap + plugin loading)
-- ============================================================
vim.loader.enable()
require 'yada.config.lazy'

-- Colorscheme from theme-set.sh (writes lua/theme.lua — gitignored)
local ok, colorscheme = pcall(require, "theme")
vim.cmd.colorscheme(ok and colorscheme or "tokyonight-night")

-- ============================================================
-- CORE OPTIONS & AUTOCMDS
-- ============================================================
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('yada-highlight-yank', { clear = true }),
  callback = function() vim.hl.on_yank() end,
})

require 'yada.core.options'

-- ============================================================
-- KEYMAPS (must run after plugins load)
-- ============================================================
require('yada.core').setup()

-- vim: ts=2 sts=2 sw=2 et
