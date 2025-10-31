local main = {}
local function get_visual_selection_range()
  -- Temporarily leave visual mode to update '< and '> marks
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")

  -- Swap if selection was backwards
  if start_pos[2] > end_pos[2] or (start_pos[2] == end_pos[2] and start_pos[3] > end_pos[3]) then
    start_pos, end_pos = end_pos, start_pos
  end

  return {
    start_line = start_pos[2],
    start_col = start_pos[3],
    end_line = end_pos[2],
    end_col = end_pos[3],
  }
end

local function escape_html(text)
  -- Escape HTML special characters to display code safely
  text = text:gsub("&", "&amp;")
  text = text:gsub("<", "&lt;")
  text = text:gsub(">", "&gt;")
  return text
end

function main.setup(config)
  vim.api.nvim_create_user_command("Snap", function(opts)
    local html_output = {}
    local function append_text(text)
      table.insert(html_output, escape_html(text))
    end

    local function append_span(text, hl_group)
      if hl_group then
        table.insert(html_output, string.format('<span class="%s">%s</span>', hl_group, escape_html(text)))
      else
        table.insert(html_output, "&nbsp;")
      end
    end

    local range = get_visual_selection_range()
    local bufnr = vim.api.nvim_get_current_buf()
    local parser = vim.treesitter.get_parser(bufnr)
    local tree = parser:parse()[1]
    local root = tree:root()
    local query = vim.treesitter.query.get(vim.bo.filetype, "highlights")

    local last_byte = 0
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local full_text = table.concat(lines, "\n")

    for id, node, metadata in query:iter_captures(root, bufnr, range.start_line, range.end_line + 1) do
      local sr, sc, er, ec = node:range()
      -- Check if capture intersects visual selection range
      if
        (er > range.start_line or (er == range.start_line and ec >= range.start_col))
        and (sr < range.end_line or (sr == range.end_line and sc <= range.end_col))
      then
        local capture_name = query.captures[id]
        local text = vim.treesitter.get_node_text(node, bufnr)
        local s_byte = node:start()
        local e_byte = node:end_()
        -- print(capture_name)
        -- if s_byte > last_byte then
        --   append_span(full_text:sub(last_byte + 1, s_byte), nil)
        -- end
        --
        -- local text_span = full_text:sub(s_byte + 1, e_byte)
        -- append_span(text_span, capture_name)
        -- last_byte = e_byte
        --
        -- local color = string.sub(vim.api.nvim_exec("highlight @" .. capture_name, true), -7)
        -- if string.sub(color, 1, 1) ~= "#" then
        -- 	print(color)
        -- end
        -- table.insert(html_output, string.format("<span style='color:%s'>%s</span>", color, escape_html(text)))
      end
    end

    local html_result = table.concat(html_output, "")

    local html_page = string.format(
      [[
<!doctype html>
<html lang="en">
<head>
<meta charset="UTF-8" />
<meta name="viewport" content="width=device-width, initial-scale=1.0" />
<meta http-equiv="X-UA-Compatible" content="ie=edge" />
</head>
<body style="">
<pre>
%s
</pre>
</body>
</html>
    ]],
      html_result
    )
    vim.fn.setreg("+", html_page)
  end, { desc = "Print visual selection range", range = true })
end

return main
