local files = require("ledger.files")
local logger = require("ledger.logger").get()
local parser = require("ledger.parser")
local utils = require("ledger.utils")

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

--- @param path string
function LedgerContext:has_file(path)
  for _, source in pairs(self.sources) do
    if source.path == path then
      return true
    end
  end
  return false
end

--- adds a new file to the sources, parsing its content and querying every
--- needed resource
---
--- @param filename string
--- @param path string
function LedgerContext:add_file(filename, path)
  logger:info("adding new source " .. filename)
  local ok, contents = files.read_file(path)
  local source = table.concat(contents, "\n")
  local result = parser.get_parser(source)

  if ok then
    self.sources[filename] = {
      path = path,
      parser = result.parser,
      tree = result.tree,
      root = result.root,
      source = source,
    }

    parser.get_account_names_from_source(result.root, source, self)
    parser.get_commodities_from_source(result.root, source, self)
    logger:info("new source added successfully")
  end
end

--- gets completion items based on the current scope of editing and accumulates
--- them into a table that can be used by completion engines
---
--- @return string[]
function LedgerContext:current_scope_completions()
  local current_scope = parser.find_current_scope()
  local completion_items = {}

  if current_scope == parser.scopes.Account then
    completion_items = utils.tbl_merge("keep", completion_items, self.accounts)
  elseif current_scope == parser.scopes.Commodity then
    completion_items = utils.tbl_merge("keep", completion_items, self.commodities)
  elseif current_scope == parser.scopes.Posting then
    completion_items = utils.tbl_merge("keep", completion_items, self.accounts)
    completion_items = utils.tbl_merge("keep", completion_items, self.commodities)
  end

  return completion_items
end

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
