<div align="center">

# Snappy

A nvim code export tool that produces an HTML representation of selected code.

https://github.com/user-attachments/assets/da27c0d5-13de-4d32-9091-07727693b189

</div>

## Install Requirements

Currently the only tested version of nvim is `v0.11.4`. As treesitter is
experimental, this plugin may break or not work correctly on newer/older
versions.

### LazyVim

```lua
return {
	'NeoSahadeo/lsp-toggle.nvim',
}
```

## Usage

Provide a selection range and add `Snap` to the end of it. After running `Snap`
it *should* open a browser window in the systems' default browser.

__Example__

```
:'<,'>Snap
```

To switch colour schemes just switch the current colour scheme that your nvim instance is using.

## Configuration

```lua
---@class Extra
---@field capture_name string The name of the capture associated with the node
---@field text string The data text of the node
---@class ExtendedNode
---@field node TSNode The Tree-sitter node object
---@field extra Extra Additional metadata including capture_name
---@alias CheckFunc fun(extnode: ExtendedNode): any
---@type table<any, CheckFunc[]>
config = {
  fallback_fg = "white",
  fallback_bg = "black",
  checks = {},
}

```

### Writing Your Own Checks

The parser expects a list of functions with the language name. Here is an example
to check for f-strings and strings in Python.

```lua
["python"] = {
  function(node)
    --- Traverses up the node tree to check if in f-string
    local parent = node:parent() -- gets the parent node
    while parent do -- while the parent exists start checking
    -- If the type is a string or a f-string we want to skip it
    -- so we return false
      if parent:type() == "string" or parent:type() == "f_string" then
        return false
      end
      parent = parent:parent()
    end

    -- If its not a string or f-string we want to parse it. So we return
    -- true
    return true
  end,
}
```


## Known Issues

Due to how `tree-sitter` handles parsing expressions, there will be formatting
issues namely code duplication. In order to help fix this, please see the
`lua/snappy/utils/checks.lua` and `lua/snappy/utils/parser.lua` file.

It is caused by a sub-expressions nested inside a parse-block. In order to fix
the duplication, add in a parser check that will check for the named
sub-expression and discard it.

This can be added into your configuration or you can submit a pull-request with
the changes. Please see the contributions markdown to see how to submit a pr.

__Example__

```lua
M.checks = {
  ["python"] = function(node)
    if node:type() == "string" then
      return false
    end
    return true
  end
}
```

## RoadMap

- Add a self contained executable applet to produce an image file based on the HTML file

## Contributors

  - @[NeoSahadeo](https://github.com/NeoSahadeo) **Maintainer *(Current owner)***
