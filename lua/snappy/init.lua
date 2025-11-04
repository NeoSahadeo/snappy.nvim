local M = {}

---@param opts SnappyConfig
function M.setup(opts)
  local static = require("snappy.static")
  static.config = vim.tbl_deep_extend("force", static.config, opts or {})
  local checks = require("snappy.utils.checks")
  for key, value in pairs(static.config.checks) do
    for _, f in ipairs(value) do
      table.insert(checks[key], f)
      print(f)
    end
  end
end

return M
