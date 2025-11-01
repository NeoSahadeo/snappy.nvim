local main = {}

function main.setup(config)
  vim.api.nvim_create_user_command("Snap", function(opts)
    local misc = require("snappy.utils.misc")
    local current_buffer = vim.api.nvim_get_current_buf()
    local parser = vim.treesitter.get_parser(current_buffer)
    if parser == nil then
      print("Parser failed to start")
      goto exited
    end
    local root = parser:parse()[1]:root()

    local lang = vim.treesitter.language.get_lang(vim.bo.filetype) or vim.bo.filetype
    local query = vim.treesitter.query.get(lang, "highlights")
    if query == nil then
      print("No query found")
      goto exited
    end

    local __processed_nodes = {}
    local __data = {}
    local __line = {}
    local range = misc.get_visual_selection_range()
    local line_number = range.start_line
    local prev_row = nil
    local prev_end = 0
    local check_tabs = true
    for id, node in query:iter_captures(root, current_buffer, range.start_line - 1, range.end_line) do
      local start_row, start_col = node:start()
      local _, end_col = node:end_()

      local node_id = node:id()
      if not __processed_nodes[node_id] then
        __processed_nodes[node_id] = true
      else
        goto continue
      end

      local line = vim.api.nvim_buf_get_lines(current_buffer, start_row, start_row + 1, false)[1]
      local line_len = string.len(line)
      local text = vim.treesitter.get_node_text(node, current_buffer)

      local capture_name = query.captures[id]

      -- TODO: Write custom handler function
      local hl_id = vim.api.nvim_get_hl_id_by_name("@" .. capture_name .. "." .. lang)
      local hl = vim.api.nvim_get_hl(0, { id = hl_id, link = false })

      local hex_color = require("snappy.utils.colors").default_fg
      if hl.fg then
        hex_color = string.format("#%06x", hl.fg)
      end

      -- Calculates horizontal space
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
        string.rep(" ", diff_col) .. string.format("<span style='color: %s'>%s</span>", hex_color, text)
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
    local export = table.concat(__data):gsub("^%s*(.-)%s*$", "%1")

    export = require("snappy.utils.html").generate_page(export)
    local tmpfile = vim.fn.tempname() .. ".html"
    vim.fn.writefile(vim.split(export, "\n"), tmpfile)

    if vim.fn.has("mac") == 1 then
      vim.cmd("!open " .. vim.fn.shellescape(tmpfile))
    elseif vim.fn.has("win32") == 1 then
      vim.cmd("!start " .. vim.fn.shellescape(tmpfile))
    elseif vim.fn.has("unix") == 1 then
      vim.cmd("!xdg-open " .. vim.fn.shellescape(tmpfile))
    end

    goto exited
    ::exited::
  end, { desc = "Print visual selection range", range = true })
end

return main
