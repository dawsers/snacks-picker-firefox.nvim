# snacks-picker-firefox.nvim

## Introduction

[snacks-picker-firefox](https://github.com/dawsers/snacks-picker-firefox.nvim)
is a picker source for Neovim's [snacks.nvim](https://github.com/folke/snacks.nvim)
to search and open Firefox bookmarks and history.

## Requirements

You will need [snacks.nvim](https://github.com/folke/snacks.nvim) and
[sqlite.lua](https://github.com/kkharji/sqlite.lua) to be able to access the
database containing bookmarks and history.

## Installation and Configuration

There are no default keymaps, but there are default settings for the
highlighting groups in case you don't want to add them to your theme.

If you use [lazy.nvim](https://github.com/folke/lazy.nvim), configuring the
plugin could look like this:


``` lua
{
  'dawsers/snacks-picker-firefox.nvim',
  dependencies = {
    'folke/snacks.nvim',
    'kkharji/sqlite.lua',
  },
  config = function()
    local firefox = require('firefox')
    -- You need to call setup
    firefox.setup({
      -- These are the default values, usually correct for Linux.
      --
      -- For MacOS or Windows, adapt the configuration, search
      -- where your Firefox profile is. It is usually in these
      -- directories:
      --
      --    MacOS: "Library/Application Support/Firefox"
      --    Windows: "Appdata/Roaming/Mozilla/Firefox"
      --
      -- The url open command is also different depending on the OS,
      -- 'open' (MacOS), 'start firefox' or 'explorer' (Windows)
      --
      url_open_command = 'xdg-open',
      firefox_profile_dir = '~/.mozilla/firefox',
      firefox_profile_glob = '*.default*',
    })
    vim.keymap.set({ 'n' }, '<leader>Ff', function() Snacks.picker.firefox_search() end, { silent = true, desc = "Firefox search" })
    vim.keymap.set({ 'n' }, '<leader>Fb', function() Snacks.picker.firefox_bookmarks() end, { silent = true, desc = "Firefox bookmarks" })
    vim.keymap.set({ 'n' }, '<leader>Fh', function() Snacks.picker.firefox_history() end, { silent = true, desc = "Firefox history" })
  end
}
```


## Pickers

| **Picker**                    | **Description**              |
|-------------------------------|------------------------------|
| `firefox_search`              | Show every visited place     |
| `firefox_bookmarks`           | Show bookmarks               |
| `firefox_history`             | Show history                 |

There are no default mappings for any of the commands.

The pickers support multiple selections.

The key bindings are these:

| **Key**               | **Description**                           |
|-----------------------|-------------------------------------------|
| `<CR>`                | Open selected url(s) in default browser   |
| `<C-y>`               | Yank selected url(s)                      |


There are no default key bindings to call the pickers, these are an example
you may want to use:

``` lua
-- There are no default keyboard bindings, these are an example
vim.keymap.set({ 'n' }, '<leader>Ff', function() Snacks.picker.firefox_search() end, { silent = true, desc = "Firefox search" })
vim.keymap.set({ 'n' }, '<leader>Fb', function() Snacks.picker.firefox_bookmarks() end, { silent = true, desc = "Firefox bookmarks" })
vim.keymap.set({ 'n' }, '<leader>Fh', function() Snacks.picker.firefox_history() end, { silent = true, desc = "Firefox history" })
```


## Highlighting

There are four highlighting groups you can use to customize the look of the
results: `PickerFirefoxDate`, `PickerFirefoxFolder`, `PickerFirefoxTitle` and
`PickerFirefoxUrl`. You can assign colors to them customizing your *colorscheme*,
or in your Neovim configuration.


``` lua
-- These are the default values for the highlighting groups if you don't
-- modify them
vim.cmd("highlight default link PickerFirefoxDate Number")
vim.cmd("highlight default link PickerFirefoxFolder Keyword")
vim.cmd("highlight default link PickerFirefoxTitle Function")
vim.cmd("highlight default link PickerFirefoxUrl Comment")

-- You can override them using nvim_set_hl
vim.api.nvim_set_hl(0, "PickerFirefoxDate", { link = "Number" })
...
```
