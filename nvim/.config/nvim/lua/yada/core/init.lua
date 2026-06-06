-- yada.core — foundation: options, keymaps, autocmds, etc.
-- `require 'yada.core'` applies options immediately.
-- Call `require('yada.core').setup()` at the end of init.lua to apply keymaps.

require('yada.core.options')

local M = {}

--- Register keymaps. Call after plugins are loaded.
function M.setup()
  require('yada.core.keymaps').setup()
end

return M
