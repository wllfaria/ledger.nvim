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

--- we always complete as Values, this seemingly random arbitrary value
--- comes from the LSP specification
local completion_item_kind = {
  VALUE = 12,
}

--- returns a new completion common
function M.new()
  return setmetatable({}, LedgerCompletion)
end

--- returns whether or not this completion engine is available, this will
--- be true as long as the current workspace has any ledger files attached
--- to it
---
--- TODO: maybe we want to only be available when editing a ledger file
--- but for now this is fine
function M.is_available()
  return files.is_ledger(vim.fn.expand("%"))
end

--- queries completion items from the context and calls the completion
--- engine callback to display them to the users based on the current
--- scope of editing
---
---@param callback function
function M.complete(callback)
  local completions = context:current_scope_completions()

  local completion_items = {}

  for _, item in ipairs(completions) do
    print(item)
    --- @type CompletionItem
    local completion = {
      label = item,
      kind = completion_item_kind.VALUE,
      sortText = item,
      insertText = item,
    }
    table.insert(completion_items, completion)
  end

  return callback(completion_items)
end

return M
