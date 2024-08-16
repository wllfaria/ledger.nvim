local M = {}

function M.setup()
  local config = require("ledger.config").get()
  if config.completion.cmp.enabled then
    require("ledger.completion.cmp").setup()
  end
end

local context = require("ledger.context").get()
local files = require("ledger.files")
local logger = require("ledger.logger").get()

--- @class CompletionList
--- @field isIncomplete boolean
--- @field items lsp.CompletionItem[]

--- @class CmpCompletionExtension
--- @field kind_text string
--- @field kind_hl_group string

--- @class ledger.CompletionCommon
local LedgerCompletion = {}
LedgerCompletion.__index = LedgerCompletion

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
---@param middleware fun(completion_items: table)?
function M.complete(callback, middleware)
  local completions = context:current_scope_completions()

  logger:info("fetched " .. #completions .. " completions")

  local completion_items = {}

  for _, item in ipairs(completions) do
    print(item)
    --- @type lsp.CompletionItem
    local completion = {
      label = item,
      kind = vim.lsp.protocol.CompletionItemKind.Value,
      sortText = item,
      insertText = item,
    }
    table.insert(completion_items, completion)
  end

  if middleware ~= nil then
    middleware(completion_items)
  end

  return callback(completion_items)
end

return M
