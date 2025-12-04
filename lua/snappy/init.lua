local M = {}

---@param opts SnappyConfig
function M.setup(opts)
  local static = require("snappy.static")
  static.config = vim.tbl_deep_extend("force", static.config, opts or {})
end

return M
