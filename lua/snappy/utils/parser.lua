local html = require("snappy.utils.html")
local misc = require("snappy.utils.misc")
local colors = require("snappy.utils.colors")

local M = {
  current_buffer = nil,
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
  if node:child_count() == 0 then
    print(node:type())
    callback(node)
  end
  for child in node:iter_children() do
    traverse_nodes(child, callback)
  end
end

---@return (nil|string)
function M.parse()
  M.current_buffer = vim.api.nvim_get_current_buf()

  local lang = nil
  local lang_ok = pcall(function()
    lang = vim.treesitter.language.get_lang(vim.bo.filetype) or vim.bo.filetype
  end)
  if not lang_ok or lang == nil then
    vim.lsp.log.error("Language undetermined")
    return plain_parse()
  end

  local parser = nil
  local parser_ok = pcall(function()
    parser = vim.treesitter.get_parser(M.current_buffer, lang)
  end)
  if not parser_ok or parser == nil then
    vim.lsp.log.error("Failed to obtain parser")
    return nil
  end

  local query = vim.treesitter.query.get(lang, "highlights")
  if query == nil then
    vim.lsp.log.error("No query found")
    return nil
  end

  local range = misc.get_visual_selection_range()
  local tree = parser:parse(range)[1]
  local root = tree:root()

  local fallback_fg = require("snappy.utils.colors"):get_fg()
  local __data = {}
  local __line = {}
  local line_number = range[1]
  local prev_row = nil
  local prev_end = 0
  local check_tabs = true

  traverse_nodes(root, function(node)
    local text = vim.treesitter.get_node_text(node, M.current_buffer)
    for id, match_node in query:iter_captures(node, M.current_buffer) do
      if match_node:id() == node:id() then
        local start_row, start_col = node:start()
        local _, end_col = node:end_()
        local line = vim.api.nvim_buf_get_lines(M.current_buffer, start_row, start_row + 1, false)[1]
        local line_len = string.len(line)
        local capture_name = query.captures[id]

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
            .. string.format(
              "<span class='%s' style='color: %s'>%s</span>",
              capture_name,
              color,
              html.escape_html(text)
            )
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
        return
      end
    end
  end)
  return table.concat(__data):gsub("^%s*(.-)%s*$", "%1")
end

return M
