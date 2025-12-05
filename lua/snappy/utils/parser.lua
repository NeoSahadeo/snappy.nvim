local html = require("snappy.utils.html")
local misc = require("snappy.utils.misc")
local colors = require("snappy.utils.colors")

local M = {
  lang = nil,
  current_buffer = nil,
  parser = nil,
  fallback_fg = require("snappy.utils.colors"):get_fg(),
}

---@return string
local function plain_parse()
  local range = misc.get_visual_selection_range()
  local lines = vim.api.nvim_buf_get_lines(0, range.start_line - 1, range.end_line, false)
  local __data = {}
  for index, value in ipairs(lines) do
    table.insert(__data, string.format("<span style='color:%s'>%s</span>\n", colors:get_fg(), value))
  end
  return table.concat(__data)
end

local function traverse_nodes(node, callback)
  callback(node)
  -- if node:child_count() == 0 then
  --   print(node:type())
  -- end
  for child in node:iter_children() do
    traverse_nodes(child, callback)
  end
end

local function get_hl_group(bufnr, node)
  if M.lang == nil then
    return
  end
  local hl = vim.treesitter.highlighter.new(M.parser)
  -- local ns = vim.api.nvim_get_namespaces()["nvim.treesitter.highlighter"]
  local ns = vim.api.nvim_create_namespace("nvim.treesitter.highlighter")
  local row1, col1, row2, col2 = node:range()

  -- print(ns)
  print(vim.inspect(vim.api.nvim_get_namespaces())) -- Find "nvim.treesitter.highlighter"
  local links = vim.api.nvim_buf_get_extmarks(M.current_buffer, ns, { row1, col1 }, { row2, col2 }, {
    type = "highlight",
  })
  print(links[1])
  -- for index, value in ipairs(links) do
  --   print(index)
  -- end
  -- if links[1] then
  --   local hl_id = links[1][4].hl_group
  --   if hl_id then
  --     return vim.fn.synIDattr(vim.fn.hlID(hl_id), "name")
  --   end
  -- end
end

local function find_color(capture_name)
  local command = "highlight @"
  local color = M.fallback_fg
  local color_raw = ""
  while true do
    local ok = pcall(function()
      color_raw = vim.api.nvim_exec2(command .. capture_name, { output = true }).output:match("([^%s]+)$")
    end)
    if color_raw == nil then
      break
    end
    if not ok then
      break
    end

    if string.find(color_raw, "#") == nil then
      -- print(color_raw)
      command = "highlight "
      capture_name = color_raw
    else
      color = color_raw:match("#%x+")
      break
    end
  end
  return color
end

---@return (nil|string)
function M.parse()
  M.current_buffer = vim.api.nvim_get_current_buf()

  M.lang = nil
  local lang_ok = pcall(function()
    M.lang = vim.treesitter.language.get_lang(vim.bo.filetype) or vim.bo.filetype
  end)
  if not lang_ok or M.lang == nil then
    vim.lsp.log.error("Language undetermined")
    return plain_parse()
  end

  M.parser = nil
  local parser_ok = pcall(function()
    M.parser = vim.treesitter.get_parser(M.current_buffer, M.lang)
  end)
  if not parser_ok or M.parser == nil then
    vim.lsp.log.error("Failed to obtain parser")
    return nil
  end

  local query = vim.treesitter.query.get(M.lang, "highlights")
  if query == nil then
    vim.lsp.log.error("No query found")
    return nil
  end

  local range = misc.get_visual_selection_range()
  local tree = M.parser:parse(range)[1]
  local root = tree:root()

  local fallback_fg = require("snappy.utils.colors"):get_fg()
  local __data = {}
  local __line = {}
  local line_number = range[1]
  local prev_row = nil
  local prev_end = 0
  local check_tabs = true

  local marks = {}

  -- local ns = vim.api.nvim_get_namespaces()["nvim.treesitter.highlighter"]
  local ns = vim.api.nvim_get_namespaces()["NvimTreeHighlights"]

  -- print(ns)
  -- print(vim.inspect(vim.api.nvim_get_namespaces()))

  -- ---@param node TSNode
  traverse_nodes(root, function(node)
    local row1, col1, row2, col2 = node:range()
    -- local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    local links = vim.api.nvim_buf_get_extmarks(M.current_buffer, ns, { row1, col1 }, { row2, col2 }, {
      overlap = true,
    })
    print(#links)
  end)
  -- print(links[1])

  -- print(get_hl_group(M.current_buffer, node))
  -- local text = vim.treesitter.get_node_text(node, M.current_buffer)
  -- local start_row, start_col = node:start()
  -- local end_row, end_col = node:end_()
  -- marks[start_col] = { start_col, end_col, text, node, nil }
  -- end)

  -- for id, node in query:iter_captures(root, M.current_buffer, range[1] - 1, range[3]) do
  --   local start_row, start_col = node:start()
  --   local _, end_col = node:end_()
  --   if marks[start_col] ~= nil then
  --     print(marks[start_col][3])
  --   end
  -- end

  -- for key, value in pairs(marks) do
  --   for id, match_node in query:iter_captures(root, M.current_buffer) do
  --     if match_node:id() == value[4]:id() then
  --       marks[key][5] = query.captures[id]
  --     end
  --   end
  -- end
  --
  -- for key, value in pairs(marks) do
  --   print(key, value[2], value[3], value[4]:type(), value[4]:named(), find_color(value[5]))
  -- end

  -- return table.concat(__data):gsub("^%s*(.-)%s*$", "%1")
end

return M
