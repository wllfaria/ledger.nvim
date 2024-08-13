local parser = require("ledger.parser")
local queries = require("ledger.queries")

local M = {}

--- @class SourcePair
--- @field path string
--- @field parser vim.treesitter.LanguageTree
--- @field tree TSTree
--- @field root TSNode

--- @alias SourceMap table<string, SourcePair>

--- @class ledger.Context
--- @field sources SourceMap
--- @field accounts string[]
--- @field commodities string[]
local LedgerContext = {}
LedgerContext.__index = LedgerContext

--- extracts every account in a given source file and accumulates into
--- ctx.accounts
---
--- @param node TSNode
--- @param source string
--- @param ctx ledger.Context
local function get_account_names(node, source, ctx)
  for _, match in parser.query_iter(queries.account_query, node, source) do
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
local function get_commodities(node, source, ctx)
  for _, match in parser.query_iter(queries.commodities_query, node, source) do
    local commodity_name = vim.treesitter.get_node_text(match, source)
    table.insert(ctx.commodities, commodity_name)
  end
end

--- Creates a new context.
--- A context is the entity responsible for holding the parsers for
--- a ledger "project"
---
--- @param path string
--- @return ledger.Context
function M.new(path)
  --- @type ledger.Context
  local default = { sources = {}, accounts = {}, commodities = {} }

  local files = require("ledger.files")
  local sources = files.read_dir_rec(path)
  for filename, filepath in pairs(sources) do
    local ok, contents = files.read_file(filepath)
    local source = table.concat(contents, "\n")
    local result = parser.get_parser(source)
    if ok then
      default.sources[filename] = {
        path = filepath,
        parser = result.parser,
        tree = result.tree,
        root = result.root,
        source = source,
      }

      get_account_names(result.root, source, default)
      get_commodities(result.root, source, default)
    end
  end

  print(vim.inspect(default))

  local self = setmetatable(default, LedgerContext)
  return self
end

M.new("/home/wiru/code/accounting")

return M
