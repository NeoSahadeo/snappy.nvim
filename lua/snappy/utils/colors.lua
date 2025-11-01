local M = {
  default_fg = "white",
  default_bg = "black",
}

function M:get_bg()
  local bg = vim.fn.synIDattr(vim.fn.hlID("Normal"), "bg#")
  if string.len(bg) == 0 then
    bg = self.default_bg
  end
  return bg
end

return M
