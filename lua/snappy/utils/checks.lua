---@type table<any, CheckFunc[]>
local M = {
  -- Python
  ["python"] = {
    function(node)
      --- Traverses up the node tree to check if in f-string
      local parent = node["node"]:parent()
      while parent do
        if parent:type() == "string" or parent:type() == "f_string" then
          return false
        end
        parent = parent:parent()
      end
      return true
    end,
  },

  -- JSX
  ["jsx"] = {
    function(node)
      if node["node"]:type():sub(1, 3) == "jsx" then
        return false
      end
      return true
    end,
  },
  ["tsx"] = {
    function(node)
      if node["node"]:type():sub(1, 3) == "jsx" then
        return false
      end
      return true
    end,
  },

  -- XML
  ["xml"] = {
    function(node)
      if node["extra"]["text"]:match("^%s*$") ~= nil then
        return false
      end
      if node["node"]:type() == '"' then
        return false
      end
      return true
    end,
  },
}

return M
