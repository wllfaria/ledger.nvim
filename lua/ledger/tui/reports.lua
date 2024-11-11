local config = require("ledger.config").get()
local logger = require("ledger.logger").get()

local M = {}

--- @class ledger.TuiReportEntryFilter
--- @field flag string
--- @field value string

--- @class ledger.TuiReportEntry
--- @field active table<string, ledger.TuiReportEntryFilter>

--- @class ledger.TuiReports
--- @field layout ledger.TuiLayout
--- @field filters table<string, ledger.TuiReportEntry>
local LedgerReports = {}
LedgerReports.__index = LedgerReports

--- @class ledger.TuiReports
local instance

--- @param report string | nil
function LedgerReports:populate_filters(report)
  --- @type string
  local current_report

  if report ~= nil then
    current_report = report
  end

  if report == nil then
    local ok, active_report = self:maybe_get_current_report()
    if not ok then
      return
    end
    current_report = active_report
  end

  for name, command in pairs(config.tui.sections) do
    if name == current_report then
      local content = {}

      for name, _ in pairs(command.filters) do
        local formatted = name
        if self.filters[current_report] ~= nil and self.filters[current_report].active[name] ~= nil then
          formatted = " " .. formatted
        end
        table.insert(content, formatted)
      end

      table.sort(content, function(a, b)
        return a < b and true or false
      end)

      self.layout.set_buffer_content(self.layout.filters_buf, content)
      return
    end
  end
end

function LedgerReports:populate_reports()
  local report_names = {}
  for section_name, _ in pairs(config.tui.sections) do
    table.insert(report_names, section_name)
  end
  table.sort(report_names, function(a, b)
    return a < b and true or false
  end)
  self.layout.set_buffer_content(self.layout.reports_buf, report_names)
end

--- @return boolean, string
function LedgerReports:maybe_get_current_report()
  local focused_buffer = vim.api.nvim_get_current_buf()
  if focused_buffer ~= self.layout.reports_buf then
    return false, ""
  end

  if not vim.api.nvim_buf_is_valid(self.layout.output_buf) then
    return false, ""
  end

  local row, _ = unpack(vim.api.nvim_win_get_cursor(vim.api.nvim_get_current_win()))
  local row_content = vim.api.nvim_buf_get_lines(focused_buffer, row - 1, row, false)
  if #row_content == 0 then
    return false, ""
  end

  return true, row_content[1]
end

--- @param name string
--- @param command ledger.TuiSection
--- @return string
function LedgerReports:apply_filters(name, command)
  local command_string = command.command

  if self.filters[name] then
    for _, filter in pairs(self.filters[name].active) do
      command_string = command_string .. " " .. filter.flag .. " " .. filter.value
    end
  end

  return command_string
end

function LedgerReports:maybe_run_command()
  local ok, current_report = self:maybe_get_current_report()
  if not ok then
    return
  end

  for name, command in pairs(config.tui.sections) do
    if name == current_report then
      local cwd = require("ledger.files").cwd()

      local command = self:apply_filters(name, command)
      logger:info('running command "' .. command)

      local ok, pid = pcall(vim.system, vim.split(command, " "), { cwd = cwd })
      if not ok then
        logger:error("failed to run command")
        error("failed to run command")
        return
      end

      local output = pid:wait().stdout
      if not output or #output == 0 then
        logger:warn("command output was empty")
        return
      end

      local output_splitted = vim.split(output, "\n")
      self.layout.set_buffer_content(self.layout.output_buf, output_splitted)
      return
    end
  end
end

--- @param layout ledger.TuiLayout
--- @return ledger.TuiReports
function M.setup(layout)
  if not instance then
    instance = setmetatable({
      layout = layout,
      filters = {},
    }, LedgerReports)
  end
  return instance
end

function M.get()
  return instance
end

return M
