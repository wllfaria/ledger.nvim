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
  dependencies = { 'nvim-treesitter/nvim-treesitter' },
  config = function()
    require('ledger').setup()
  end,
}
```

## Configuration

<details>
<summary>Click here to see all the options available</summary>

```lua
{
  -- extensions that will be considered ledger files.
  extensions = {
    "ledger",
    "hledger",
    "journal",
  },
  -- which completion engine to use, if any
  completion = {
    cmp = { enabled = false },
    coq = { enabled = false },
  },
}
```

</details>

## Features

- Smarter completion for account names and commodities
- a bunch of other things but I still have to code them

## Related projects

- [vim-ledger](https://github.com/ledger/vim-ledger)
