local context = require("ledger.context").get()
local files = require("ledger.files")

local M = {}

--- @class CompletionList
--- @field isIncomplete boolean
--- @field items CompletionItem[]

--- @class CompletionItem
--- @field label string
--- @field detail string?
--- @field kind integer? -- CompletionItemKind?
--- @field deprecated boolean?
--- @field sortText string?
--- @field insertText string?
--- @field cmp CmpCompletionExtension?

--- @class CmpCompletionExtension
--- @field kind_text string
--- @field kind_hl_group string

--- @class ledger.CompletionCommon
local LedgerCompletion = {}
LedgerCompletion.__index = LedgerCompletion

local completion_item_kind = {
  VALUE = 12,
}

--- @enum CompletionContext
local completion_context = {
  Account = 1,
  Commodity = 2,
}

--- returns a new completion common
function M.new()
  return setmetatable({}, LedgerCompletion)
end

function M.is_available()
  return files.has_ledger_file(files.cwd())
end

---@param callback function
function M.complete(callback)
  local accounts = context.accounts
  local completion_items = {}

  for _, account in ipairs(accounts) do
    --- @type CompletionItem
    local completion = {
      label = account,
      kind = completion_item_kind.VALUE,
      sortText = account,
      insertText = account,
    }
    table.insert(completion_items, completion)
  end

  return callback(completion_items)
end

return M
