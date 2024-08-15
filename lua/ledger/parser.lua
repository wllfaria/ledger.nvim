local queries = require("ledger.queries")
local ts_utils = require("nvim-treesitter.ts_utils")

local M = {}

--- @class TSSource
--- @field parser vim.treesitter.LanguageTree
--- @field tree TSTree
--- @field root TSNode

--- get a parser, aswell as the parsed tree and the root node from
--- a given ledger source file content
---
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

--- possible scopes for completion to be queried, those are processed
--- as:
---
--- 1. Posting: displays both account names and commodity names, as
---    we cannot be certain if the next block of text will be a commodity
---    or a new account entry on the posting.
--- 2. Account: when first typing into a posting, we can for sure know
---    that we are now typing account names, so we only send account names
---    for completions
--- 3. Commodity: after writing a account name, we can either add a value
---    or a commodity, when first typing we will know that it is a commodity
---    and therefore will only send commodities as completions
---
--- @enum Scope
M.scopes = {
  Posting = 1,
  Account = 2,
  Commodity = 3,
}

--- gets the current scope the cursor is currently editing
---
--- @return Scope
function M.find_current_scope()
  local node_at_cursor = ts_utils.get_node_at_cursor()
  local node_type = node_at_cursor:type()

  local scope

  if node_type == "account" then
    scope = M.scopes.Account
  elseif node_type == "commodity" then
    scope = M.scopes.Commodity
  elseif node_type == "posting" then
    scope = M.scopes.Posting
  end

  return scope
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
--- @param filename string
--- @param ctx ledger.Context
function M.get_account_names_from_source(node, source, filename, ctx)
  for _, match in M.query_iter(queries.account_query, node, source) do
    local account_name = vim.treesitter.get_node_text(match, source)
    ctx.accounts[filename] = {}
    table.insert(ctx.accounts[filename], account_name)
  end
end

--- extracts every commodity in a given source file and accumulates into
--- ctx.commodities
---
--- @param node TSNode
--- @param source string
--- @param filename string
--- @param ctx ledger.Context
function M.get_commodities_from_source(node, source, filename, ctx)
  for _, match in M.query_iter(queries.commodities_query, node, source) do
    local commodity_name = vim.treesitter.get_node_text(match, source)
    ctx.accounts[filename] = {}
    table.insert(ctx.commodities[filename], commodity_name)
  end
end

return M
