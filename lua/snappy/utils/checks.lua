--- Checks that should be performed to generate a
--- correct output string.
--- If a lanuage has an issue parsing, a new check
--- should be added here to help support it.
---@class Extra
---@field capture_name string The name of the capture associated with the node
---@field text string The data text of the node
---@class ExtendedNode
---@field node TSNode The Tree-sitter node object
---@field extra Extra Additional metadata including capture_name
---@field __processed_nodes table<TSNode> metadata including capture_name
---@alias CheckFunc fun(extnode: ExtendedNode): any
---@type table<any, CheckFunc[]>
return {
  -- General
  ["all"] = {
    function(node)
      return not node["extra"]["__processed_nodes"][node["node"]:id()]
    end,
  },
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
