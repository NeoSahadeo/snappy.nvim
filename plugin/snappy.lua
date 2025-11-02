vim.api.nvim_create_user_command("Snap", function()
  local parser = require("snappy.utils.parser")
  local value = parser.parse()
  if value ~= nil then
    value = require("snappy.utils.html").generate_page(value)
    local tmpfile = vim.fn.tempname() .. ".html"
    vim.fn.writefile(vim.split(value, "\n"), tmpfile)

    -- goto exited
    if vim.fn.has("mac") == 1 then
      pcall(vim.cmd("!open " .. vim.fn.shellescape(tmpfile)))
    elseif vim.fn.has("win32") == 1 then
      pcall(vim.cmd("!start " .. vim.fn.shellescape(tmpfile)))
    elseif vim.fn.has("unix") == 1 then
      pcall(vim.cmd("!xdg-open " .. vim.fn.shellescape(tmpfile)))
    end
  end
  ::exited::
end, { desc = "Print visual selection range", range = true })
