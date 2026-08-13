return {
  'stevearc/conform.nvim',
  event = 'BufWritePre',
  opts = {
    notify_on_error = false,
    format_on_save = function(bufnr)
      if vim.bo[bufnr].filetype == 'go' then
        return { timeout_ms = 500, lsp_format = 'fallback' }
      end
      return { timeout_ms = 2000, lsp_format = 'fallback' }
    end,
    default_format_opts = { lsp_format = 'fallback' },
    formatters = {
      sqlfluff = {
        require_cwd = false,
        args = { 'fix', '--dialect', 'postgres', '-' },
      },
    },
    formatters_by_ft = {
      go = { 'goimports', 'gofumpt' },
      javascript = { 'prettier' },
      javascriptreact = { 'prettier' },
      typescript = { 'prettier' },
      typescriptreact = { 'prettier' },
      html = { 'prettier' },
      sql = { 'sqlfluff' },
    },
  },
}
