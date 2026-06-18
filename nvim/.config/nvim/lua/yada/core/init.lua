-- yada.core — foundation: keymaps, etc.
-- Options are loaded directly by init.lua.
-- Call `require('yada.core').setup()` at the end of init.lua to apply keymaps.

local M = {}

--- Register keymaps. Call after plugins are loaded.
function M.setup()
  require('yada.core.keymaps').setup()
end

return M
