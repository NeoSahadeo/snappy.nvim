<div align="center">

# Snappy

A nvim code export tool that produces an HTML representation of selected code.

https://github.com/user-attachments/assets/da27c0d5-13de-4d32-9091-07727693b189

</div>

## Install Requirements

Currently the only tested version of nvim is `v0.11.4`.
As treesitter is experimental, this plugin may break or not work correctly on newer/older versions.

### LazyVim

```lua
return {
	'NeoSahadeo/lsp-toggle.nvim',
}
```

## Usage

Provide a selection range and add `Snap` to the end of it. After running `Snap` it *should* open a browser
window in the systems' default browser.

__Example__

```
:'<,'>Snap
```

To switch colour schemes just switch the current colour scheme that your nvim instance is using.

## Configuration

TODO

## Known Issues

Due to how `tree-sitter` handles parsing expressions, there will be formatting issues namely code
duplication. In order to help fix this, please see the `lua/snappy/utils/parser.lua` file.

It is caused by a sub-expressions nested inside a parse-block. In order to fix the duplication,
add in a parser check that will check for the named sub-expression and discard it.

This can be added into your configuration or you can submit a pull-request with the changes. Please
see the contributions markdown to see how to submit a pr.

```lua
--- Checks that should be performed to generate a
--- correct output string.
--- If a lanuage has an issue parsing, a new check
--- should be added here to help support it.
--- @alias CheckFunc fun(node: TSNode): boolean
--- @type CheckFunc[]
M.checks = {
  function(node)
  end
}
```

## RoadMap

- Add a self contained executable applet to produce an image file based on the HTML file

## Contributors

  - @[NeoSahadeo](https://github.com/NeoSahadeo) **Maintainer *(Current owner)***
