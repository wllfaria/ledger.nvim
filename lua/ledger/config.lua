local M = {}

--- @class ledger.SnippetKeymaps
--- @field new_account string[]
--- @field new_posting string[]
--- @field new_posting_today string[]
--- @field new_commodity string[]

--- @class ledger.Keymaps
--- @field snippets ledger.SnippetKeymaps

--- @class ledger.CompletionSource
--- @field enabled boolean

--- @class ledger.SnippetSource
--- @field enabled boolean

--- @class ledger.Completion
--- @field cmp ledger.CompletionSource

--- @class ledger.Snippet
--- @field native ledger.SnippetSource
--- @field luasnip ledger.SnippetSource
--- @field cmp ledger.SnippetSource

--- @class ledger.PartialConfig
--- @field extensions string[]?
--- @field completion ledger.Completion?
--- @field snippets ledger.Snippet?

--- @class ledger.Config
--- @field extensions string[]
--- @field default_ignored_paths string[]
--- @field completion ledger.Completion
--- @field snippets ledger.Snippet
--- @field keymaps ledger.Keymaps
local LedgerConfig = {}
LedgerConfig.__index = LedgerConfig

--- @class ledger.Snippet
local LedgerConfigSnippets = {}
LedgerConfigSnippets.__index = LedgerConfigSnippets

--- @class ledger.Completion
local LedgerConfigCompletion = {}
LedgerConfigCompletion.__index = LedgerConfigCompletion

--- checks if any of the completion providers are enabled and return
--- true/false
---
--- @return boolean
function LedgerConfigCompletion:is_enabled()
  if self.cmp.enabled then
    return true
  end
  return false
end

--- checks if any of the existing snippet providers are available and
--- return true/false
---
--- @return boolean
function LedgerConfigSnippets:is_enabled()
  if self.native.enabled then
    return true
  elseif self.luasnip.enabled then
    return true
  elseif self.cmp.enabled then
    return true
  end
  return false
end

function LedgerConfig.__tostring()
  return "<LedgerConfig>"
end

--- @return ledger.Config
local function get_default_config()
  --- @type ledger.Config
  local default_config = {
    extensions = {
      "ledger",
      "hledger",
      "journal",
    },
    completion = setmetatable({
      cmp = { enabled = true },
    }, LedgerConfigCompletion),
    default_ignored_paths = {
      ".git",
    },
    snippets = setmetatable({
      native = { enabled = false },
      cmp = { enabled = true },
      luasnip = { enabled = false },
    }, LedgerConfigSnippets),
    keymaps = {
      snippets = {
        new_posting = { "tt" },
        new_account = { "acc" },
        new_posting_today = { "td" },
        new_commodity = { "cm" },
      },
    },
  }
  return default_config
end

--- @type ledger.Config
local instance = nil

--- Config is a singleton, allowing us to call `get` as many times as we
--- want and always getting the same instance, so we don't have to pass
--- the table around
---
--- @param overrides? ledger.PartialConfig
--- @return ledger.Config
function M.setup(overrides)
  if not instance then
    local default = get_default_config()
    local with_overrides = vim.tbl_deep_extend("force", default, overrides or {})
    instance = setmetatable(with_overrides, LedgerConfig)
  end
  return instance
end

function M.get()
  return instance
end

return M
