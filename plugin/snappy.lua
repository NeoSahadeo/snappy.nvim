local function generate()
  local parser = require("snappy.utils.parser")
  return parser.parse()
end

vim.api.nvim_create_user_command("Snap", function()
  local value = generate()
  if value ~= nil then
    value = require("snappy.utils.html").generate_page(value)
    local tmpfile = vim.fn.tempname() .. ".html"
    vim.fn.writefile(vim.split(value, "\n"), tmpfile)

    if vim.fn.has("mac") == 1 then
      pcall(vim.cmd("!open " .. vim.fn.shellescape(tmpfile)))
    elseif vim.fn.has("win32") == 1 then
      pcall(vim.cmd("!start " .. vim.fn.shellescape(tmpfile)))
    elseif vim.fn.has("unix") == 1 then
      pcall(vim.cmd("!xdg-open " .. vim.fn.shellescape(tmpfile)))
    end
  end
  generate()
end, { desc = "Print visual selection range", range = true })

vim.api.nvim_create_user_command("SnapI", function(opts)
  local current_dir = vim.fn.expand("%:p:h")
  local parent_dir = vim.fn.fnamemodify(current_dir, ":h")
  local jar_path = parent_dir .. "/lua/snappy/java/html2image-2.0-SNAPSHOT.jar"
  local value = generate()

  vim.fn.system(string.format("java -jar %s", jar_path), value)
end, { desc = "Generate and save a png image of selection range", nargs = "*", range = true })
