local common = require("ledger.completion")

---@class Cmp
---@field register_source fun(name: string, src: CmpCompletionSource)

---@class cmp.Entry

---@class cmp.SourceCompletionApiParams
---@field offset number
---@field context table

--- @class CmpCompletionSource
--- @field registered_source boolean?
local M = {}

--- @class CmpCompletionSource
--- @field snippets lsp.CompletionItem[]
local LedgerCmp = {}
LedgerCmp.__index = LedgerCmp

local instance

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
  --- this function injects snippets into the completion list
  --- when cmp is enabled as a snippet source
  ---
  --- @param completion_items lsp.CompletionItem[]
  local insert_snippets = function(completion_items)
    for _, snippet in pairs(self.snippets) do
      table.insert(completion_items, snippet)
    end
  end

  common.complete(callback, insert_snippets)
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

  instance = M.new()
  cmp.register_source("ledger", instance)
  M.registered_source = true
end

--- @param snippets ledger.SnippetList
function M.enable_snippets(snippets)
  local cmp_snippets = require("ledger.snippets.cmp").new(snippets)
  instance.snippets = cmp_snippets
end

return M
