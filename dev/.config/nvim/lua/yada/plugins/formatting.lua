return {
  'stevearc/conform.nvim',
  event = 'BufWritePre',
  opts = {
    notify_on_error = false,
    format_on_save = { go = { timeout_ms = 500 } },
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
