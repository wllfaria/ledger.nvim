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

--- @class ledger.Context
local instance

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

      parser.get_account_names_from_source(result.root, source, default)
      parser.get_commodities_from_source(result.root, source, default)
    end
  end

  instance = setmetatable(default, LedgerContext)
  return instance
end

function M.get()
  return instance
end

return M
