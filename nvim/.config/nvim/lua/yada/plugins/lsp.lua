-- LSP server configs + buffer-local keymap spec.

-- ============================================================
-- Server configs
-- ============================================================
---@type table<string, vim.lsp.Config>
local servers = {
  -- clangd = {},
  gopls = {
    settings = {
      gopls = {
        gofumpt = true,
        staticcheck = true,
        usePlaceholders = false,
        analyses = { unusedparams = true, unreachable = true, nilness = true, shadow = true },
        hints = {
          assignVariableTypes = true,
          compositeLiteralFields = true,
          functionTypeParameters = true,
          parameterNames = true,
          rangeVariableTypes = true,
        },
        codelenses = { toggle_gc_details = false, run_govulncheck = false, whyline = false },
      },
    },
  },
  -- pyright = {},
  -- rust_analyzer = {},
  ts_ls = {
    settings = {
      typescript = { inlayHints = { parameterTypes = { enabled = true } } },
      javascript = { inlayHints = { parameterTypes = { enabled = true } } },
    },
  },
  stylua = {},
  qmlls = { cmd = { '/usr/lib/qt6/bin/qmlls' } },

  lua_ls = {
    on_init = function(client)
      client.server_capabilities.documentFormattingProvider = false -- formatting is done by stylua

      if client.workspace_folders then
        local path = client.workspace_folders[1].name
        if path ~= vim.fn.stdpath 'config' and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc')) then return end
      end

      client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
        runtime = {
          version = 'LuaJIT',
          path = { 'lua/?.lua', 'lua/?/init.lua' },
        },
        workspace = {
          checkThirdParty = false,
          -- Slows startup; see https://github.com/neovim/nvim-lspconfig/issues/3189
          library = vim.tbl_extend('force', vim.api.nvim_get_runtime_file('', true), {
            '${3rd}/luv/library',
            '${3rd}/busted/library',
          }),
        },
      })
    end,
    ---@type lspconfig.settings.lua_ls
    settings = {
      Lua = { format = { enable = false } },
    },
  },
}

-- ============================================================
-- LSP keymap spec
-- ============================================================
-- Declarative table consumed by `yada.core.keymaps.apply_lsp_keymaps`.
---@type { lhs: string, rhs: function|string, desc: string, mode?: string|string[], has?: string, cond?: fun(buf: integer, client: vim.lsp.Client): boolean, opts?: table }[]
local lsp_keymaps = {
  -- Goto (override 0.12 built-ins to use Snacks pickers)
  { lhs = 'gd', rhs = function() Snacks.picker.lsp_definitions() end,     desc = 'Goto Definition',        has = 'definition' },
  { lhs = 'gD', rhs = function() Snacks.picker.lsp_declarations() end,    desc = 'Goto Declaration',       has = 'declaration' },
  { lhs = 'gI', rhs = function() Snacks.picker.lsp_implementations() end,  desc = 'Goto Implementation',    has = 'implementation' },
  { lhs = 'gr', rhs = function() Snacks.picker.lsp_references() end,      desc = 'Goto References',        has = 'references' },
  { lhs = 'gT', rhs = function() Snacks.picker.lsp_type_definitions() end, desc = 'Goto Type Definition',   has = 'typeDefinition' },

  -- Snacks variants (alternate lhs for muscle memory)
  { lhs = 'grd', rhs = function() Snacks.picker.lsp_definitions() end,     desc = 'Goto Definition (alt)',     has = 'definition' },
  { lhs = 'grr', rhs = function() Snacks.picker.lsp_references() end,      desc = 'Goto References (alt)',     has = 'references' },
  { lhs = 'gri', rhs = function() Snacks.picker.lsp_implementations() end,  desc = 'Goto Implementation (alt)', has = 'implementation' },
  { lhs = 'grt', rhs = function() Snacks.picker.lsp_type_definitions() end, desc = 'Goto Type Definition (alt)', has = 'typeDefinition' },
  { lhs = 'gO',  rhs = function() Snacks.picker.lsp_symbols() end,  desc = 'Document Symbols',          has = 'documentSymbol' },
  { lhs = 'gW',  rhs = function() Snacks.picker.lsp_workspace_symbols() end, desc = 'Workspace Symbols', has = 'workspaceSymbol' },

  -- Hover / signature / rename
  { lhs = 'K',          rhs = vim.lsp.buf.hover,          desc = 'Hover',          has = 'hoverProvider' },
  { lhs = '<leader>lh', rhs = vim.lsp.buf.signature_help, desc = 'Signature Help', has = 'signatureHelpProvider' },
  { lhs = '<leader>lr', rhs = vim.lsp.buf.rename,         desc = 'Rename Symbol',  has = 'renameProvider' },

  -- Code action
  { lhs = '<leader>la', rhs = vim.lsp.buf.code_action,    desc = 'Code Action',    mode = { 'n', 'v' }, has = 'codeActionProvider' },

  -- Format
  { lhs = '<leader>lf', rhs = function() vim.lsp.buf.format { async = true } end, desc = 'Format Buffer', has = 'documentFormattingProvider' },

  -- Symbol pickers
  { lhs = '<leader>lR', rhs = function() Snacks.picker.lsp_references() end, desc = 'References (picker)', has = 'references' },
  { lhs = '<leader>ls', rhs = function() Snacks.picker.lsp_symbols() end, desc = 'Document Symbols (picker)', has = 'documentSymbol' },
  { lhs = '<leader>lg', rhs = function() Snacks.picker.lsp_workspace_symbols() end, desc = 'Workspace Symbols (picker)', has = 'workspaceSymbol' },

  -- Inlay hint toggle (only if the server supports the protocol)
  {
    lhs = '<leader>ih',
    rhs = function()
      vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = vim.api.nvim_get_current_buf() })
    end,
    desc = 'Toggle Inlay Hints',
    has = 'inlayHint',
  },

  -- Misc
  { lhs = '<leader>li', rhs = function() vim.cmd 'LspInfo' end, desc = 'LSP Info' },
  { lhs = '<leader>ld', rhs = vim.diagnostic.open_float,       desc = 'Diagnostic Line' },
}

-- ============================================================
-- Plugin spec
-- ============================================================
return {
  'neovim/nvim-lspconfig',
  dependencies = {
    'mason-org/mason.nvim',
    'WhoIsSethDaniel/mason-tool-installer.nvim',
  },
  config = function()
    require('mason').setup {}

    local mason_names = {
      gopls = 'gopls',
      ts_ls = 'typescript-language-server',
      stylua = 'stylua',
      lua_ls = 'lua-language-server',
    }
    local ensure_installed = vim.tbl_values(mason_names)
    vim.list_extend(ensure_installed, { 'eslint_d', 'golangci-lint', 'prettier' }) -- used by nvim-lint and conform.nvim

    require('mason-tool-installer').setup { ensure_installed = ensure_installed }

    for name, server in pairs(servers) do
      if name == 'gopls' and vim.fn.executable 'go' ~= 1 then goto continue end
      if name == 'qmlls' and vim.fn.executable('/usr/lib/qt6/bin/qmlls') ~= 1 then goto continue end
      vim.lsp.config(name, server)
      vim.lsp.enable(name)
      ::continue::
    end

    -- LspAttach handler
    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('yada-lsp-attach', { clear = true }),
      callback = function(event)
        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if not client then return end

        -- Apply buffer-local LSP keymaps (capability-conditional)
        require('yada.core.keymaps').apply_lsp_keymaps(event.buf, client, lsp_keymaps)

        -- Document highlight on CursorHold; cleared on CursorMoved / LspDetach
        if client:supports_method 'textDocument/documentHighlight' then
          local group = vim.api.nvim_create_augroup('yada-lsp-highlight', { clear = false })
          vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
            buffer = event.buf,
            group = group,
            callback = vim.lsp.buf.document_highlight,
          })
          vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
            buffer = event.buf,
            group = group,
            callback = vim.lsp.buf.clear_references,
          })
          vim.api.nvim_create_autocmd('LspDetach', {
            group = vim.api.nvim_create_augroup('yada-lsp-detach', { clear = true }),
            callback = function(args)
              vim.lsp.buf.clear_references()
              vim.api.nvim_clear_autocmds { group = 'yada-lsp-highlight', buffer = args.buf }
            end,
          })
        end
      end,
    })
  end,
}
