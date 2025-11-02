---@class SnappyConfig
---@field fallback_fg string
---@field fallback_bg string
---@field checks table<any, CheckFunc[]>
---
local M = {}

---@type SnappyConfig
M.config = {
  fallback_fg = "white",
  fallback_bg = "black",
  checks = {},
}

return M
