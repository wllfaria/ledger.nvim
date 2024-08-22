local config = require("ledger.config").get()
local logger = require("ledger.logger").get()

local M = {}

--- @class ledger.TuiReports
--- @field layout ledger.TuiLayout
--- @field last_row integer
local LedgerReports = {}
LedgerReports.__index = LedgerReports

--- @class ledger.TuiReports
local instance

function LedgerReports:populate_reports()
  local report_names = {}
  for section_name, _ in pairs(config.tui.sections) do
    table.insert(report_names, section_name)
  end
  self.layout.set_buffer_content(self.layout.reports_buf, report_names)
end

function LedgerReports:maybe_run_command()
  local focused_buffer = vim.api.nvim_get_current_buf()
  if focused_buffer ~= self.layout.reports_buf then
    return
  end

  if not vim.api.nvim_buf_is_valid(self.layout.output_buf) then
    return
  end

  local row, _ = unpack(vim.api.nvim_win_get_cursor(vim.api.nvim_get_current_win()))
  if row == self.last_row then
    return
  end

  self.last_row = row
  local row_content = vim.api.nvim_buf_get_lines(focused_buffer, row - 1, row, false)
  if #row_content == 0 then
    return
  end

  for name, command in pairs(config.tui.sections) do
    if name == row_content[1] then
      local cwd = require("ledger.files").cwd()
      logger:info('running command "' .. command.command)

      local ok, pid = pcall(vim.system, vim.split(command.command, " "), { cwd = cwd })
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
    end
  end
end

--- @param layout ledger.TuiLayout
--- @return ledger.TuiReports
function M.setup(layout)
  if not instance then
    instance = setmetatable({
      layout = layout,
      last_row = -1,
    }, LedgerReports)
  end
  return instance
end

function M.get()
  return instance
end

return M
