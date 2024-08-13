local M = {}

--- @class ledger.Main
--- @field context ledger.Context
local Ledger = {}
Ledger.__index = Ledger

--- Entrypoint of the plugin and interface with plugin managers.
--- Here is where we take in the user configuration overrides and
--- merge with our own defaults.
---
--- @param overrides? ledger.PartialConfig
--- @return ledger.Main
function M.setup(overrides)
  -- our configuration is a singleton, so we don't have to hold the instance,
  -- we can simply call setup and require it later.
  require("ledger.config").setup(overrides or {})
  local utils = require("ledger.utils")
  local files = require("ledger.files")

  local self = setmetatable({}, Ledger)

  -- if there are no ledger files on the root of cwd, we won't start any
  -- parsers or any of the other required structures to avoid useless work.
  --
  -- In this case, we only initialize user commands and auto commands to
  -- ensure the plugin gets auto-initialized when a ledger buffer is loaded.
  --
  -- TODO: actually do what is above lol
  local has_ledger_file = files.has_ledger_file(files.cwd())
  if not has_ledger_file then return self end

  local context = require("ledger.context").new()

  --- @type ledger.Main
  local default = {
    context = context,
  }

  self = setmetatable(default, Ledger)
  return self
end

return M
