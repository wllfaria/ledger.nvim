local M = {}

--- @class ledger.PartialConfig
--- @field extensions string[]?

--- @class ledger.Config
--- @field extensions string[]

local LedgerConfig = {}
LedgerConfig.__index = LedgerConfig

function LedgerConfig.__tostring() return "<LedgerConfig>" end

--- @return ledger.Config
local function get_default_config()
  --- @type ledger.Config
  local default_config = {
    extensions = {
      "ledger",
      "hledger",
      "journal",
    },
  }
  return default_config
end

--- @type ledger.Config
local instance = nil

--- Config is a singleton, allowing us to call `get` as many times as we
--- want and always getting the same instance, so we don't have to pass
--- the table around
---
--- @param overrides? ledger.PartialConfig
--- @return ledger.Config
function M.setup(overrides)
  if not instance then
    local default = get_default_config()
    local with_overrides = vim.tbl_deep_extend("force", default, overrides or {})
    instance = setmetatable(with_overrides, LedgerConfig)
  end
  return instance
end

return M
