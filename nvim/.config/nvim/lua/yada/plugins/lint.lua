return {
  'mfussenegger/nvim-lint',
  event = { 'BufReadPost', 'BufWritePost', 'InsertLeave' },
  config = function()
    local lint = require 'lint'

    lint.linters.eslint_d.parser = function(output, bufnr)
      if output:find('Error:') or output:find('TypeError:') or output:find('ReferenceError:') then
        return {}
      end
      if not output:match '^%s*%[' then
        return {}
      end
      local result = require('lint.linters.eslint').parser(output, bufnr)
      for _, d in ipairs(result) do
        d.source = 'eslint_d'
      end
      return result
    end

    local linters = {
      go = { 'golangcilint' },
      javascript = { 'eslint_d' },
      javascriptreact = { 'eslint_d' },
      typescript = { 'eslint_d' },
      typescriptreact = { 'eslint_d' },
    }

    lint.linters_by_ft = {}
    for ft, names in pairs(linters) do
      local valid = {}
      for _, name in ipairs(names) do
        if vim.fn.executable(name) == 1 then
          table.insert(valid, name)
        end
      end
      if #valid > 0 then
        lint.linters_by_ft[ft] = valid
      end
    end

    vim.api.nvim_create_autocmd({ 'BufWritePost', 'InsertLeave', 'BufReadPost' }, {
      group = vim.api.nvim_create_augroup('yada-lint', { clear = true }),
      callback = function() lint.try_lint() end,
    })
  end,
}
