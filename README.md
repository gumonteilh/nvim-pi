# nvim-pi

A small Neovim plugin to work with pi in a side terminal.

## Features

- Spawn Pi in a side terminal
- Auto-reload files after Pi updates them
- Inline edits from the buffer
- Ask questions from the buffer
- Explain LSP diagnostics

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
  -- require: vim.o.autoread = true
  auto_reload = true,
  inline_edit = {
    command = { "pi" },
    -- format "provider/model", compatible with pi
    model = nil,
    thinking = "off",
  },
})
```

No default keybindings, you can add them in your config:

```lua
vim.keymap.set({ "n", "t" }, "<C-n>", "<cmd>PiToggle<cr>", {
  desc = "Toggle pi",
})
```

## Commands

- `:Pi`: Open/show Pi terminal
- `:PiOpen`: Same
- `:PiToggle`: Toggle Pi terminal
- `:PiClose`: Close Pi terminal
- `:PiInlineEdit`: One-shot edit from the buffer
- `:PiAsk`: Prompt for a question, open the Pi terminal, and send the question with file path and cursor position
- `:PiExplain`: Open the Pi terminal and send LSP diagnostics of the current line

### `PiInlineEdit`

What it does:

- Prompt for an instruction
- Send the current saved file and cursor position to a hidden pi RPC process not linked to your Pi session
- After the agent changes the file, it will be reloaded automatically

You can customize the model and thinking level, usually no thinking and a fast model. By default, it uses the current Pi model and no thinking.
Save your current buffer before calling `PiInlineEdit`.
Do not make changes while the query is pending or the result will be discarded.

## Disclaimer

This plugin is mainly developed by an AI agent, nothing very valuable.
I only plan to add features that suit my workflow and nothing more.
If you want to add new features, fork the repo.
