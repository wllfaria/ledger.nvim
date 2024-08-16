local config = require("ledger.config").get()
local utils = require("ledger.utils")

local M = {}

local LedgerSnippets = {}
LedgerSnippets.__index = LedgerSnippets

--- @class ledger.SnippetTemplate
--- @field pre string
--- @field text string
--- @field insert boolean
--- @field post string

--- @class ledger.SnippetDefinition
--- @field triggers string[]
--- @field template ledger.SnippetTemplate[]

--- @alias ledger.SnippetList table<string, ledger.SnippetDefinition>

--- we have a "meta template" for defining snippets in a way that can be
--- translated to different snippet engines. This is what allows us to
--- have a single source of snippets and allow the user to decide on which
--- snippet engine he wants to use
---
--- @type ledger.SnippetList
M.default_snippets = {
  new_posting = {
    triggers = config.keymaps.snippets.new_posting,
    template = {
      { pre = "", text = "YYYY-MM-DD", insert = true, post = " " },
      { pre = "", text = "*", insert = true, post = " " },
      { pre = "", text = "Payee", insert = true, post = "\n" },
      { pre = "\t", text = "From:Account", insert = true, post = "\n" },
      { pre = "\t", text = "To:Account", insert = true, post = "" },
    },
  },
  new_posting_today = {
    triggers = config.keymaps.snippets.new_posting_today,
    template = {
      { pre = "", text = utils.today_str(), insert = false, post = " " },
      { pre = "", text = "*", insert = true, post = " " },
      { pre = "", text = "Payee", insert = true, post = "\n" },
      { pre = "\t", text = "From:Account", insert = true, post = "\n" },
      { pre = "\t", text = "To:Account", insert = true, post = "" },
    },
  },
  new_account = {
    triggers = config.keymaps.snippets.new_account,
    template = {
      { pre = "", text = "account", insert = false, post = " " },
      { pre = "", text = "Account:Name", insert = true, post = "" },
    },
  },
  new_commodity = {
    triggers = config.keymaps.snippets.new_commodity,
    template = {
      { pre = "", text = "commodity", insert = false, post = " " },
      { pre = "", text = "CODE", insert = true, post = "" },
    },
  },
}

function M.setup()
  local self = setmetatable({}, LedgerSnippets)

  if config.snippets.native.enabled then
    require("ledger.snippets.native").setup(M.default_snippets)
  elseif config.snippets.luasnip.enabled then
    require("ledger.snippets.luasnip").setup(M.default_snippets)
  elseif config.snippets.cmp.enabled then
    require("ledger.completion.cmp").enable_snippets(M.default_snippets)
  end

  return self
end

return M
