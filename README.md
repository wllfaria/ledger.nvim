# Ledger nvim

Neovim integration for ledger files, powered by tree-sitter

## Motivation

I'm adept to plain-text accounting, and I use ledger to keep track of my
finances, but I've been wanting some better neovim integration for ledger
files for a while.

This project intends to leverage tree-sitter to get completions, snippets
and other cool features I've missed.

This is a personal side project, so updates might be a little slow.

## Installation

### Lazy.nvim

Add the following snippet to your lazy configuration!

```lua
{
  'wllfaria/ledger.nvim',
  -- tree sitter needs to be loaded before ledger.nvim loads
  dependencies = { 'nvim-treesitter/nvim-treesitter' },
  config = function()
    require('ledger').setup()
  end,
}
```

## Configuration

Below are the default configurations for ledger.nvim, you can set anything
to your liking.

```lua
{
  extensions = {
    "ledger",
    "hledger",
    "journal",
  },
  completion = {
    cmp = { enabled = true },
  },
  snippets = {
    cmp = { enabled = true },
    luasnip = { enabled = false },
    native = { enabled = false },
  },
  keymaps = {
    snippets = {
      new_posting = { "tt" },
      new_account = { "acc" },
      new_posting_today = { "td" },
      new_commodity = { "cm" },
    },
  },
  diagnostics = {
    lsp_diagnostics = true,
    strict = false,
  }
}
```

<details>
<summary>Expand to see each option in detail</summary>

| option | description |
| ------ | ----------- |
| extensions | which extensions should be considered ledger files |
| completion | which completion engine to display account and commodity completions |

</details>

## Features

- Smarter completion for account names and commodities
-

## Related projects

- [vim-ledger](https://github.com/ledger/vim-ledger)
