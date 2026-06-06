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

  -- Disable arrow keys:
  -- vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
  -- vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
  -- vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
  -- vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

  -- Move windows with Ctrl+Shift+hjkl (collides in some terminals):
  -- vim.keymap.set('n', '<C-S-h>', '<C-w>H', { desc = 'Move window left' })
  -- vim.keymap.set('n', '<C-S-l>', '<C-w>L', { desc = 'Move window right' })
  -- vim.keymap.set('n', '<C-S-j>', '<C-w>J', { desc = 'Move window down' })
  -- vim.keymap.set('n', '<C-S-k>', '<C-w>K', { desc = 'Move window up' })
end

-- ============================================================
-- Search (Telescope)
-- ============================================================
local function search()
  local builtin = require 'telescope.builtin'

  vim.keymap.set('n', '<leader>sh', builtin.help_tags,         { desc = '[S]earch [H]elp' })
  vim.keymap.set('n', '<leader>sk', builtin.keymaps,           { desc = '[S]earch [K]eymaps' })
  vim.keymap.set('n', '<leader>sf', builtin.find_files,       { desc = '[S]earch [F]iles' })
  vim.keymap.set('n', '<leader>ss', builtin.builtin,           { desc = '[S]earch [S]elect Telescope' })
  vim.keymap.set({ 'n', 'v' }, '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
  vim.keymap.set('n', '<leader>sg', builtin.live_grep,        { desc = '[S]earch by [G]rep' })
  vim.keymap.set('n', '<leader>sd', builtin.diagnostics,      { desc = '[S]earch [D]iagnostics' })
  vim.keymap.set('n', '<leader>sr', builtin.resume,            { desc = '[S]earch [R]esume' })
  vim.keymap.set('n', '<leader>s.', builtin.oldfiles,         { desc = '[S]earch Recent Files ("." for repeat)' })
  vim.keymap.set('n', '<leader>sc', builtin.commands,         { desc = '[S]earch [C]ommands' })
  vim.keymap.set('n', '<leader><leader>', builtin.buffers,    { desc = '[ ] Find existing buffers' })

  vim.keymap.set('n', '<leader>/', function()
    builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
      winblend = 10,
      previewer = false,
    })
  end, { desc = '[/] Fuzzily search current buffer' })

  vim.keymap.set('n', '<leader>s/', function()
    builtin.live_grep { grep_open_files = true, prompt_title = 'Live Grep in Open Files' }
  end, { desc = '[S]earch [/] in Open Files' })

  vim.keymap.set('n', '<leader>sn', function() builtin.find_files { cwd = vim.fn.stdpath 'config' } end, { desc = '[S]earch [N]eovim files' })
end

-- ============================================================
-- Navigation (Flash)
-- ============================================================
local function navigation()
  vim.keymap.set({ 'n', 'x', 'o' }, 's', function() require('flash').jump() end,        { desc = 'Flash' })
  vim.keymap.set({ 'n', 'x', 'o' }, 'S', function() require('flash').treesitter() end, { desc = 'Flash Treesitter' })
  vim.keymap.set('o', 'r', function() require('flash').remote() end,                    { desc = 'Remote Flash' })
end

-- ============================================================
-- Formatting
-- ============================================================
local function formatting()
  vim.keymap.set({ 'n', 'v' }, '<leader>f', function() require('conform').format { async = true } end, { desc = '[F]ormat buffer' })
end

-- ============================================================
-- Diagnostics (global, not LSP-only)
-- ============================================================
local function diagnostics()
  -- 0.12 registers ]d / [d without descriptions; re-register with desc
  -- so they appear in which-key.
  vim.keymap.set('n', ']d', function() vim.diagnostic.jump { count = 1 } end,  { desc = 'Next [D]iagnostic' })
  vim.keymap.set('n', '[d', function() vim.diagnostic.jump { count = -1 } end, { desc = 'Previous [D]iagnostic' })
  vim.keymap.set('n', 'gl', vim.diagnostic.open_float,                        { desc = '[L]ine diagnostic' })
end

-- ============================================================
-- LSP keymap framework
-- ============================================================
-- Apply a buffer-local LSP keymap spec, capability-conditional.
-- The spec lives in lua/yada/plugins/lsp.lua. Entry shape:
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
  search()
  navigation()
  formatting()
  diagnostics()
end

return M
