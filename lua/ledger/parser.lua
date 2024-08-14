local queries = require("ledger.queries")

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

--- extracts every account in a given source file and accumulates into
--- ctx.accounts
---
--- @param node TSNode
--- @param source string
--- @param ctx ledger.Context
function M.get_account_names_from_source(node, source, ctx)
  for _, match in M.query_iter(queries.account_query, node, source) do
    local account_name = vim.treesitter.get_node_text(match, source)
    table.insert(ctx.accounts, account_name)
  end
end

--- extracts every commodity in a given source file and accumulates into
--- ctx.commodities
---
--- @param node TSNode
--- @param source string
--- @param ctx ledger.Context
function M.get_commodities_from_source(node, source, ctx)
  for _, match in M.query_iter(queries.commodities_query, node, source) do
    local commodity_name = vim.treesitter.get_node_text(match, source)
    table.insert(ctx.commodities, commodity_name)
  end
end

return M
