set rtp+=.
set rtp+=../plenary.nvim/
set rtp+=../LuaSnip
set rtp+=../nvim-cmp
set rtp+=../nvim-treesitter

runtime! plugin/plenary.vim
runtime! plugin/LuaSnip
runtime! plugin/nvim-cmp
runtime! plugin/nvim-treesitter

lua << EOF
  require('nvim-treesitter').setup {
    ensure_installed = { "ledger" },
    highlight = {
      enable = true,
    },
  }
EOF
