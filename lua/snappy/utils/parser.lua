local M = {}

---comment
---@return (nil|string)
function M.parse()
  local html = require("snappy.utils.html")
  local misc = require("snappy.utils.misc")
  local current_buffer = vim.api.nvim_get_current_buf()
  local parser = vim.treesitter.get_parser(current_buffer)
  if parser == nil then
    print("Parser failed to start")
    return nil
  end
  local root = parser:parse()[1]:root()

  local lang = vim.treesitter.language.get_lang(vim.bo.filetype) or vim.bo.filetype
  local query = vim.treesitter.query.get(lang, "highlights")
  if query == nil then
    print("No query found")
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

  --- Checks that should be performed to generate a
  --- correct output string.
  --- If a lanuage has an issue parsing, a new check
  --- should be added here to help support it.
  --- @alias CheckFunc fun(node: TSNode): boolean
  --- @type CheckFunc[]
  M.checks = {
    -- General
    function(node)
      return not __processed_nodes[node:id()]
    end,
  }

  local function all_checks_pass(node)
    for _, check in ipairs(M.checks) do
      if not check(node) then
        return false
      end
    end
    return true
  end

  for id, node in query:iter_captures(root, current_buffer, range.start_line - 1, range.end_line) do
    local start_row, start_col = node:start()
    local _, end_col = node:end_()

    if all_checks_pass(node) then
      __processed_nodes[node:id()] = true
    else
      goto continue
    end

    local line = vim.api.nvim_buf_get_lines(current_buffer, start_row, start_row + 1, false)[1]
    local line_len = string.len(line)
    local text = vim.treesitter.get_node_text(node, current_buffer)

    local capture_name = query.captures[id]
    -- print(capture_name)

    local command = "highlight @"
    local color = require("snappy.utils.colors").default_fg
    local c = 0
    local color_raw = ""
    while true do
      local ok, err = pcall(function()
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
    -- Formatting exists in the section as it simplifies
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
      string.rep(" ", diff_col) .. string.format("<span style='color: %s'>%s</span>", color, html.escape_html(text))
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
      for x = 1, line_breaks do
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
