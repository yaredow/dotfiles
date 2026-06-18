-- All keymaps for the configuration. Globals are registered via M.setup().
-- Buffer-local LSP keymaps are data-driven; see the spec in
-- lua/yada/plugins/lsp.lua and the resolver in M.apply_lsp_keymaps.

local M = {}

-- ============================================================
-- General
-- ============================================================
local function general()
  vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>', { desc = 'Clear search highlight' })
  vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = '[Q]uickfix list' })
  vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

  vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Focus left window' })
  vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Focus right window' })
  vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Focus lower window' })
  vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Focus upper window' })
end

-- ============================================================
-- Diagnostics (global, not LSP-only)
-- ============================================================
local function diagnostics()
  vim.keymap.set('n', ']d', function() vim.diagnostic.jump { count = 1 } end,  { desc = 'Next [D]iagnostic' })
  vim.keymap.set('n', '[d', function() vim.diagnostic.jump { count = -1 } end, { desc = 'Previous [D]iagnostic' })
  vim.keymap.set('n', 'gl', vim.diagnostic.open_float,                        { desc = '[L]ine diagnostic' })
end

-- ============================================================
-- LSP keymap framework
-- ============================================================
-- Apply a buffer-local LSP keymap spec, capability-conditional.
-- The spec lives in lua/yada/plugins/lsp.lua (exported as YADA_LSP_KEYMAPS).
-- Entry shape:
--
--   {
--     lhs  = 'gd',                       -- left-hand side
--     rhs  = function() ... end,         -- right-hand side
--     desc = 'Goto Definition',          -- description
--     mode = 'n',                        -- mode(s); default 'n'
--     has  = 'definition',               -- capability; auto-prefixes textDocument/
--     cond = function(buf, client),      -- extra predicate
--     opts = { ... },                    -- extra vim.keymap.set opts
--   }
function M.apply_lsp_keymaps(buf, client, spec)
  if not (client and spec) then return end
  for _, km in ipairs(spec) do
    if km.has then
      local method = km.has:find '/' and km.has or ('textDocument/' .. km.has)
      if not client:supports_method(method, buf) then goto continue end
    end
    if km.cond and not km.cond(buf, client) then goto continue end
    local opts = vim.tbl_extend('force', { buffer = buf, silent = true, desc = km.desc }, km.opts or {})
    vim.keymap.set(km.mode or 'n', km.lhs, km.rhs, opts)
    ::continue::
  end
end

-- ============================================================
-- Entry point
-- ============================================================
function M.setup()
  general()
  diagnostics()
end

return M
