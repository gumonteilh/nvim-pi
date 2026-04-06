# nvim-pi
 
A small Neovim plugin to keep pi in a side terminal.

## Features

- opens pi in a right-side terminal split
- toggles that split on and off
- runs `:checktime` on common editor events so files edited by pi are reloaded
- provides `:PiInlineEdit` for quick file-local edits through hidden pi RPC

## Requirements

- Neovim 0.12+
- `pi` available in your `$PATH`

## Installation

With lazy.nvim:

```lua
{
  "gumonteilh/nvim-pi",
  config = function()
    require("nvim-pi").setup()
  end,
}
```

## Default setup

```lua
require("nvim-pi").setup({
  command = { "pi" },
  width = 80,
  auto_reload = true,
  inline_edit = {
    command = { "pi" },
    model = nil,
    thinking = "off",
  },
})
```

## Commands

- `:Pi`
- `:PiToggle`
- `:PiOpen`
- `:PiClose`
- `:PiInlineEdit`

`PiInlineEdit` prompts for an instruction, sends the current saved file and cursor position to a hidden pi RPC process, then reloads the file if pi changed it.

## Configuration

### `command`

Command used to start pi. It is passed to `jobstart()`.

```lua
require("nvim-pi").setup({
  command = { "pi", "/path/to/project" },
})
```

### `width`

Width of the side split.

```lua
require("nvim-pi").setup({
  width = 60,
})
```

### `auto_reload`

Enables the autocmds that call `:checktime`.

```lua
require("nvim-pi").setup({
  auto_reload = false,
})
```

### `inline_edit`

Configuration for `:PiInlineEdit`.

```lua
require("nvim-pi").setup({
  inline_edit = {
    command = { "pi" },
    model = "fast",
    thinking = "off",
  },
})
```

`command` starts the hidden RPC process. `model` is passed as `--model`. `thinking` is sent through RPC with `set_thinking_level`.
