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
  local logger = require("ledger.logger").setup()
  -- our configuration is a singleton, so we don't have to hold the instance,
  -- we can simply call setup and require it later.
  local config = require("ledger.config").setup(overrides or {})
  local files = require("ledger.files")

  local self = setmetatable({}, Ledger)

  -- if there are no ledger files on the root of cwd, we won't start any
  -- parsers or any of the other required structures to avoid useless work.
  --
  -- In this case, we only initialize user commands and auto commands to
  -- ensure the plugin gets auto-initialized when a ledger buffer is loaded.
  --
  -- TODO: actually do what is stated above lol
  local has_ledger_file = files.has_ledger_file(files.cwd())
  if not has_ledger_file then
    return self
  end

  local commands = require("ledger.commands").setup()
  commands:create_augroup()
  commands:setup_autocommands()

  local context = require("ledger.context").new(files.cwd())
  if config.completion:is_enabled() then
    require("ledger.completion").setup()
  end

  if config.snippets:is_enabled() then
    require("ledger.snippets").setup()
  end

  if config.snippets.cmp.enabled and not config.completion:is_enabled() then
    print("cmp is registered as a snippet source but cmp is not enabled as a completion engine")
    return {}
  end

  if config.diagnostics:is_enabled() then
    require("ledger.diagnostics").get_diagnostics()
  end

  --- @type ledger.Main
  local default = {
    context = context,
  }

  logger:info("Ledger.nvim initialized")

  self = setmetatable(default, Ledger)
  return self
end

return M
