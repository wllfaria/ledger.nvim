local M = {}

--- @class TSSource
--- @field parser vim.treesitter.LanguageTree
--- @field tree TSTree
--- @field root TSNode

--- @param source string
--- @return TSSource
function M.get_parser(source)
  local parser = vim.treesitter.get_string_parser(source, "ledger")
  local tree = parser:parse()[1]
  local root = tree:root()

  --- @type TSSource
  local result = { root = root, tree = tree, parser = parser }
  return result
end

--- creates an iterator with a given query, starting at a given node
---
--- @param query vim.treesitter.Query
--- @param node TSNode
--- @param source string
--- @return function
function M.query_iter(query, node, source)
  return query:iter_captures(node, source, 0, -1)
end

return M
