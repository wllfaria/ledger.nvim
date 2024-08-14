local common = require("ledger.completion.common")

---@class Cmp
---@field register_source fun(name: string, src: CmpCompletionSource)

---@class cmp.Entry

---@class cmp.SourceCompletionApiParams
---@field offset number
---@field context table

--- @class CmpCompletionSource
--- @field registered_source boolean?
local M = {}

local LedgerCmp = {}
LedgerCmp.__index = LedgerCmp

function M.new()
  return setmetatable({}, LedgerCmp)
end

function LedgerCmp:is_available()
  return common.is_available()
end

--- optional function for debugging purposed that nvim-cmp allows us to
--- specify
---
---@return string
function LedgerCmp:get_debug_name()
  return "ledger.nvim"
end

--- required function that actually display completions for the user,
--- nvim-cmp gives us a callback that we can call passing the completion
--- items
---
--- we call our common completion interface to get completions and properly
--- shape them so we are not tied to nvim-cmp
---
---@param _ cmp.SourceCompletionApiParams
---@param callback function
function LedgerCmp:complete(_, callback)
  common.complete(callback)
end

function M.setup()
  if M.registered_source then
    return
  end

  --- @type Cmp
  local cmp = require("cmp")
  if not cmp then
    return
  end

  cmp.register_source("ledger", M.new())
  M.registered_source = true
end

return M
