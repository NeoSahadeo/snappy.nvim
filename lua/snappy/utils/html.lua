local M = {}

-- local html_output = {}
-- local function append_text(text)
--   table.insert(html_output, escape_html(text))
-- end
--
-- local function append_span(text, hl_group)
--   if hl_group then
--     table.insert(html_output, string.format('<span class="%s">%s</span>', hl_group, escape_html(text)))
--   else
--     table.insert(html_output, "&nbsp;")
--   end
-- end

--- @param text string
--- @return string
function M.escape_html(text)
  text = text:gsub("&", "&amp;")
  text = text:gsub("<", "&lt;")
  text = text:gsub(">", "&gt;")
  text = text:gsub('"', "&quot;") -- escapes double quotes
  text = text:gsub("'", "&#39;") -- escapes single quotes
  return text
end

---@param text any
---@return string
function M.generate_page(text)
  return string.format(
    [[
<!doctype html>
<html lang="en">
<head> <meta charset="UTF-8" /> <meta name="viewport" content="width=device-width, initial-scale=1.0" /> <meta http-equiv="X-UA-Compatible" content="ie=edge" /> </head>
<body style="background-color:%s">
<pre>
%s
</pre>
</body>
</html>
    ]],
    require("snappy.utils.colors"):get_bg(),
    text
  )
end

return M
