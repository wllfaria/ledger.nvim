local files = require("ledger.files")
local logger = require("ledger.logger").get()
local parser = require("ledger.parser")
local utils = require("ledger.utils")

local M = {}

--- @class SourcePair
--- @field path string
--- @field filename string
--- @field parser vim.treesitter.LanguageTree
--- @field tree TSTree
--- @field root TSNode

--- @alias SourceMap table<string, SourcePair>

--- @class ledger.Context
--- @field sources SourceMap
--- @field accounts table<string, string[]>
--- @field commodities table<string, string[]>
local LedgerContext = {}
LedgerContext.__index = LedgerContext

--- @class ledger.Context
local instance

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
      filename = filename,
      parser = result.parser,
      tree = result.tree,
      root = result.root,
      source = source,
    }

    parser.get_account_names_from_source(result.root, source, filename, self)
    parser.get_commodities_from_source(result.root, source, filename, self)
    logger:info("new source added successfully")
  end
end

--- purges deleted files from the context, also removing its commodities and
--- accounts if there were any
function LedgerContext:purge_orphan_files()
  for _, source in pairs(self.sources) do
    local exist = files.file_exist(source.path)
    if not exist then
      logger:log("purging source " .. source.filename)
      self.accounts[source.filename] = nil
      self.commodities[source.filename] = nil
    end
  end
end

--- updates a file on the context by re-parsing its content and extracting
--- the accounts, commodities and whatever is needed to override existing
--- ones
---
--- @param filename string
--- @param path string
function LedgerContext:update_file(filename, path)
  logger:info("updating source " .. filename)

  local ok, contents = files.read_file(path)
  local source = table.concat(contents, "\n")
  local result = parser.get_parser(source)

  if ok then
    self.sources[filename] = {
      path = path,
      filename = filename,
      parser = result.parser,
      tree = result.tree,
      root = result.root,
      source = source,
    }

    parser.get_account_names_from_source(result.root, source, filename, self)
    parser.get_commodities_from_source(result.root, source, filename, self)

    logger:info("source updated successfully")
  end
end

--- gets completion items based on the current scope of editing and accumulates
--- them into a table that can be used by completion engines
---
--- @return string[]
function LedgerContext:current_scope_completions()
  local current_scope = parser.find_current_scope()
  local completion_items = {}
  local accounts = {}
  local commodities = {}
  for _, file_accounts in pairs(self.accounts) do
    accounts = utils.tbl_merge("force", accounts, file_accounts)
  end
  for _, file_commodities in pairs(self.commodities) do
    commodities = utils.tbl_merge("force", accounts, file_commodities)
  end

  if current_scope == parser.scopes.Account then
    completion_items = utils.tbl_merge("keep", completion_items, accounts)
  elseif current_scope == parser.scopes.Commodity then
    completion_items = utils.tbl_merge("keep", completion_items, commodities)
  elseif current_scope == parser.scopes.Posting then
    completion_items = utils.tbl_merge("keep", completion_items, accounts)
    completion_items = utils.tbl_merge("keep", completion_items, commodities)
  end

  return completion_items
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

  local sources = files.read_dir_rec(path)
  for filename, filepath in pairs(sources) do
    local ok, contents = files.read_file(filepath)
    local source = table.concat(contents, "\n")
    local result = parser.get_parser(source)

    if ok then
      default.sources[filename] = {
        path = filepath,
        filename = filename,
        parser = result.parser,
        tree = result.tree,
        root = result.root,
        source = source,
      }

      parser.get_account_names_from_source(result.root, source, filename, default)
      parser.get_commodities_from_source(result.root, source, filename, default)
    end
  end

  instance = setmetatable(default, LedgerContext)
  return instance
end

function M.get()
  return instance
end

return M
