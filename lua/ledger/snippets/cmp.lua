local template_converter = require("ledger.snippets.template_converter")

--- @class CmpSnippetCompletionSource
local M = {}

local LedgerSnippetCmpSource = {}
LedgerSnippetCmpSource.__index = LedgerSnippetCmpSource

--- @param snippets ledger.SnippetList
--- @return lsp.CompletionItem[]
function M.new(snippets)
  local formatted_snippets = {}

  for _, snippet in pairs(snippets) do
    for _, trigger in pairs(snippet.triggers) do
      local snippet_body = template_converter.template_to_builtin(snippet.template)
      local item = {
        word = trigger,
        label = trigger,
        kind = vim.lsp.protocol.CompletionItemKind.Snippet,
        insertText = snippet_body,
        insertTextFormat = vim.lsp.protocol.InsertTextFormat.Snippet,
      }

      table.insert(formatted_snippets, item)
    end
  end

  return formatted_snippets
end

return M
