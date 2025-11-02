local M = {}

function M:get_bg()
  local bg = vim.fn.synIDattr(vim.fn.hlID("Normal"), "bg#")
  if string.len(bg) == 0 then
    bg = require("snappy.static").config.fallback_bg
  end
  return bg
end

function M:get_fg()
  local fg = vim.fn.synIDattr(vim.fn.hlID("Normal"), "fg#")
  if string.len(fg) == 0 then
    fg = require("snappy.static").config.fallback_fg
  end
  return fg
end

return M
