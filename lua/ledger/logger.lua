local files = require("ledger.files")

local M = {}

--- @class LedgerLogger
--- @field path string
local LedgerLogger = {}
LedgerLogger.__index = LedgerLogger

--- @type LedgerLogger
local instance

function LedgerLogger:setup_file()
  --- @type string
  local path
  local data_path = vim.fn.stdpath("data")
  if type(data_path) == "table" then
    path = data_path[1]
  else
    path = data_path
  end
  local plugin_path = vim.fs.joinpath(path, "ledger.nvim")
  local logfile_path = vim.fs.joinpath(plugin_path, "ledger.log")
  files.mkdir(plugin_path)
  files.rmfile(logfile_path)
  files.mkfile(logfile_path)
  self.path = logfile_path
end

--- appends the log to the logfile
---
--- @param message string
function LedgerLogger:log(message)
  local fd = io.open(self.path, "a")
  if not fd then
    return
  end
  fd:write(message)
  fd:close()
end

--- returns a prefix with [timestamp] [level] format
---
--- @param level string
--- @return string
function LedgerLogger.get_prefix(level)
  local timestamp = os.date("%Y-%m-%d %H:%M:%S")
  return "[" .. timestamp .. "] " .. level .. " "
end

--- @param message string
function LedgerLogger:info(message)
  local prefix = self.get_prefix("[INFO]")
  self:log(prefix .. message .. "\n")
end

--- @param message string
function LedgerLogger:error(message)
  local prefix = self.get_prefix("[ERROR]")
  self:log(prefix .. message .. "\n")
end

--- @param message string
function LedgerLogger:warn(message)
  local prefix = self.get_prefix("[WARN]")
  self:log(prefix .. message .. "\n")
end

--- set up the logger to start writing to a given file
---
--- @return LedgerLogger
function M.setup()
  if instance ~= nil then
    return instance
  end

  instance = setmetatable({}, LedgerLogger)
  instance:setup_file()

  return instance
end

--- @return LedgerLogger
function M.get()
  return instance
end

return M
