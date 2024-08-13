local M = {}

--- @alias SourceMap table<string, vim.treesitter.LanguageTree>

--- @class ledger.Context
--- @field sources SourceMap

--- @class ledger.Context
local LedgerContext = {}
LedgerContext.__index = LedgerContext

function LedgerContext:__tostring() return "<LedgerContext>" end

--- Creates a new context.
--- A context is the entity responsible for holding the parsers for
--- a ledger "project"
---
--- @return ledger.Context
function M.new()
  --- @type ledger.Context
  local default = { sources = {} }
  local self = setmetatable(default, LedgerContext)
  return self
end

return M
