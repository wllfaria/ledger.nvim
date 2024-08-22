local layout = require("ledger.tui.layout")
local logger = require("ledger.logger").get()
local reports = require("ledger.tui.reports")

local M = {}

--- @class ledger.Tui
--- @field layout ledger.TuiLayout
--- @field reports ledger.TuiReports
--- @field running boolean
local LedgerTui = {}
LedgerTui.__index = LedgerTui

--- @class ledger.Tui
local instance

function LedgerTui:setup()
  if self.running then
    print("ledger.nvim already has the tui open")
    return
  end

  logger:info("initializing tui view")
  self.running = true
  self.layout:setup_windows()
  self.layout:setup_aucmds()
  self.reports:populate_reports()
end

function LedgerTui:shutdown()
  self.layout:restore_window_options()
  print("shutting down")
end

function LedgerTui:set_keymaps()
  local config = require("ledger.config").get()
  local tui_keymaps = config.keymaps.tui

  --- @param commands string[]
  --- @param callback function
  local set_keymap = function(commands, callback)
    for _, trigger in pairs(commands) do
      vim.keymap.set("n", trigger, function()
        callback(self)
      end)
    end
  end

  set_keymap(tui_keymaps.initialize, self.setup)
  set_keymap(tui_keymaps.shutdown, self.shutdown)
end

function M.setup()
  if not instance then
    local layout_instance = layout.setup()
    instance = setmetatable({
      layout = layout_instance,
      reports = reports.setup(layout_instance),
    }, LedgerTui)
  end
  return instance
end

function M.get()
  return instance
end

return M
