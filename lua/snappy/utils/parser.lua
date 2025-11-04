local html = require("snappy.utils.html")
local misc = require("snappy.utils.misc")
local colors = require("snappy.utils.colors")

local M = {}

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

---@return (nil|string)
function M.parse()
  local current_buffer = vim.api.nvim_get_current_buf()

  local parser = nil
  local parser_ok = pcall(function()
    parser = vim.treesitter.get_parser(current_buffer)
  end)
  if not parser_ok or parser == nil then
    vim.lsp.log.error("Failed to obtain parser")
    -- Plain parse text with no parser
    return plain_parse()
  end
  local root = parser:parse()[1]:root()

  local lang = nil
  local lang_ok = pcall(function()
    lang = vim.treesitter.language.get_lang(vim.bo.filetype) or vim.bo.filetype
  end)
  if not lang_ok or lang == nil then
    vim.lsp.log.error("Language undetermined")
    return nil
  end

  local query = vim.treesitter.query.get(lang, "highlights")
  if query == nil then
    vim.lsp.log.error("No query found")
    return nil
  end

  local __processed_nodes = {}
  local __data = {}
  local __line = {}
  local range = misc.get_visual_selection_range()
  local line_number = range.start_line
  local prev_row = nil
  local prev_end = 0
  local check_tabs = true
  local fallback_fg = require("snappy.utils.colors"):get_fg()

  local checks = require("snappy.utils.checks")

  local function all_checks_pass(node)
    for _, func in ipairs(checks["all"]) do
      if not func(node) then
        return false
      end
    end
    if checks[lang] ~= nil then
      for _, func in ipairs(checks[lang]) do
        if not func(node) then
          return false
        end
      end
    end
    return true
  end

  for id, node in query:iter_captures(root, current_buffer, range.start_line - 1, range.end_line) do
    local start_row, start_col = node:start()
    local _, end_col = node:end_()

    local capture_name = query.captures[id]
    local text = vim.treesitter.get_node_text(node, current_buffer)

    ---@type ExtendedNode
    local extended_node = {
      ["node"] = node,
      ["extra"] = {
        ["capture_name"] = capture_name,
        ["text"] = text,
        ["__processed_nodes"] = __processed_nodes,
      },
    }
    if all_checks_pass(extended_node) then
      __processed_nodes[node:id()] = true
    else
      goto continue
    end

    local line = vim.api.nvim_buf_get_lines(current_buffer, start_row, start_row + 1, false)[1]
    local line_len = string.len(line)

    local command = "highlight @"
    local color = fallback_fg
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

    -- Calculates horizontal space
    -- Formatting exists in this section as it simplifies
    -- the design.
    local diff_col = start_col - prev_end
    prev_end = end_col
    if diff_col < 0 then
      diff_col = 0
    end

    if prev_row == nil then
      prev_row = start_row - 1
    end

    if check_tabs then
      check_tabs = false
      diff_col = start_col
    end
    table.insert(
      __line,
      string.rep(" ", diff_col)
      .. string.format("<span class='%s' style='color: %s'>%s</span>", capture_name, color, html.escape_html(text))
    )
    ------

    if line_len == end_col then
      -- Calculates vertical space
      local line_breaks = start_row - prev_row - 1
      prev_row = start_row - 1

      if line_breaks <= 0 then
        line_breaks = 1
      end

      local l = table.concat(__line)
      for _ = 1, line_breaks do
        l = "\n" .. l
      end
      ------

      check_tabs = true
      line_number = line_number + 1
      table.insert(__data, l)
      __line = {}
    end
    ::continue::
  end
  return table.concat(__data):gsub("^%s*(.-)%s*$", "%1")
end

return M
