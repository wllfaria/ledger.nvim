local queries = require("ledger.queries")
local ts_utils = require("nvim-treesitter.ts_utils")

--- @class ledger.parser
--- @field get_parser fun(source: string): TSSource
--- @field find_current_scope fun(): Scope
--- @field query_iter fun(query: vim.treesitter.Query, node: TSNode, source: string): fun(end_line: integer|nil):integer, TSNode, vim.treesitter.query.TSMetadata, TSQueryMatch
--- @field get_account_names_from_source fun(node: TSNode, source: string, filename: string, ctx: ledger.Context)
--- @field get_commodities_from_source fun(node: TSNode, source: string, filename: string, ctx: ledger.Context)
local M = {}

--- @class TSSource
--- @field parser vim.treesitter.LanguageTree
--- @field tree TSTree
--- @field root TSNode

--- get a parser, aswell as the parsed tree and the root node from
--- a given ledger source file content
---
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
--- @return fun(end_line: integer|nil):integer, TSNode, vim.treesitter.query.TSMetadata, TSQueryMatch
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
  ctx.accounts[filename] = {}
  for _, match in M.query_iter(queries.account_query, node, source) do
    local account_name = vim.treesitter.get_node_text(match, source)
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
  ctx.commodities[filename] = {}
  for _, match in M.query_iter(queries.commodities_query, node, source) do
    local commodity_name = vim.treesitter.get_node_text(match, source)
    table.insert(ctx.commodities[filename], commodity_name)
  end
end

--- @class TSRange
--- @field start_row integer
--- @field start_col integer
--- @field end_row integer
--- @field end_col integer

--- instead of returning 4 integers we return a table with the ranges
---
--- @param node TSNode
--- @return TSRange
function M.get_node_range(node)
  local start_row, start_col, end_row, end_col = node:range()
  return {
    start_row = start_row,
    start_col = start_col,
    end_row = end_row,
    end_col = end_col,
  }
end

--- extracts every posting from the source files and store information
--- about accounts and commodities to display diagnostics
---
--- @param node TSNode
--- @param source string
--- @param filename string
--- @param ctx ledger.Context
function M.get_postings_from_source(node, source, filename, ctx)
  ctx.postings[filename] = {}

  for _, match in M.query_iter(queries.posting_query, node, source) do
    local posting = {}
    local child_count = match:named_child_count()

    if child_count > 0 then
      --- @type TSNode
      local account, amount = unpack(match:named_children())
      local account_text = vim.treesitter.get_node_text(account, source)
      posting.account = { text = account_text, range = M.get_node_range(account) }

      if amount then
        --- @type TSNode, TSNode
        local commodity, quantity = unpack(amount:named_children())
        local commodity_text = vim.treesitter.get_node_text(commodity, source)
        posting.commodity = { text = commodity_text, range = M.get_node_range(commodity) }

        if quantity then
          local quantity_text = vim.treesitter.get_node_text(quantity, source)
          posting.quantity = { text = quantity_text, range = M.get_node_range(quantity) }
        end
      end

      table.insert(ctx.postings[filename], posting)
    end
  end
end

return M
