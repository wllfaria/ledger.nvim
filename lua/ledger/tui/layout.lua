local logger = require("ledger.logger").get()

local M = {}

--- @enum HlGroups
local HL_GROUPS = {
  LedgerReport = "LedgerReport",
}

--- @class ledger.TuiLayout
--- @field previous_number boolean
--- @field previous_relative boolean
--- @field previous_signcolumn "no" | "yes"
--- @field output_buf integer
--- @field filters_buf integer
--- @field reports_buf integer
--- @field augroup integer
local LedgerTuiLayout = {}
LedgerTuiLayout.__index = LedgerTuiLayout

function LedgerTuiLayout:set_window_options()
  if not self.previous_number then
    --- @type boolean
    self.previous_number = vim.api.nvim_get_option_value("number", {})
    --- @type boolean
    self.previous_relative = vim.api.nvim_get_option_value("relativenumber", {})
    --- @type "no" | "yes"
    self.previous_signcolumn = vim.api.nvim_get_option_value("signcolumn", {})
  end
  vim.api.nvim_set_option_value("number", false, {})
  vim.api.nvim_set_option_value("relativenumber", false, {})
  vim.api.nvim_set_option_value("signcolumn", "no", {})
end

function LedgerTuiLayout:restore_window_options()
  vim.api.nvim_set_option_value("number", self.previous_number, {})
  vim.api.nvim_set_option_value("relativenumber", self.previous_relative, {})
  vim.api.nvim_set_option_value("signcolumn", self.previous_signcolumn, {})
end

local function set_buffer_options()
  vim.bo.buftype = "nofile"
  vim.bo.bufhidden = "wipe"
  vim.bo.swapfile = false
end

--- sets up all the windows for the tui layout, which consists
--- of three buffers, one for the reports, one for the output
--- and one for working with filters, which is supposed to look
--- something like this:
---
--- ┌───┬───────────┬───┐
--- │   │           │   │
--- │ R │     O     │ F │
--- │   │           │   │
--- └───┴───────────┴───┘
--- R: Reports pane
--- O: Outputs pane
--- F: Filters pane
function LedgerTuiLayout:setup_windows()
  vim.cmd("vsplit")
  local output_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(output_buf)
  local output_width = math.ceil(vim.o.columns * 0.75)

  set_buffer_options()
  self:set_window_options()
  vim.cmd("vertical resize " .. output_width)
  vim.cmd("vsplit")

  local filters_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(filters_buf)
  set_buffer_options()
  self:set_window_options()
  local filter_width = math.ceil(vim.o.columns * 0.15)

  vim.cmd("vertical resize " .. filter_width)
  vim.cmd("wincmd h")
  vim.cmd("wincmd h")

  local reports_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(reports_buf)
  set_buffer_options()
  self:set_window_options()

  -- we defer locking the buffers to make sure their contents
  -- are completely written before doing so
  vim.defer_fn(function()
    vim.api.nvim_set_option_value("modifiable", false, { buf = output_buf })
    vim.api.nvim_set_option_value("modifiable", false, { buf = filters_buf })
    vim.api.nvim_set_option_value("modifiable", false, { buf = reports_buf })
  end, 100)

  logger:info("initialized tui pane buffers")
  self.output_buf = output_buf
  self.filters_buf = filters_buf
  self.reports_buf = reports_buf
end

--- overrides the entire content of a given buffer with the provided
--- content
---
--- @param buffer integer
--- @param content string[]
function LedgerTuiLayout.set_buffer_content(buffer, content)
  vim.api.nvim_set_option_value("modifiable", true, { buf = buffer })
  vim.api.nvim_buf_set_lines(buffer, 0, -1, false, content)
  vim.api.nvim_set_option_value("modifiable", false, { buf = buffer })
end

local function setup_highlight_groups()
  vim.api.nvim_set_hl(0, HL_GROUPS.LedgerReport, {
    fg = "#F3F4F6",
    bg = "#8F2BF5",
    bold = true,
  })
end

function LedgerTuiLayout:setup_aucmds()
  vim.api.nvim_create_autocmd("CursorMoved", {
    buffer = self.reports_buf,
    group = self.augroup,
    callback = function()
      local reports = require("ledger.tui.reports").get()
      reports:maybe_run_command()
    end,
  })
end

--- @return ledger.TuiLayout
function M.setup()
  local self = setmetatable({
    augroup = vim.api.nvim_create_augroup("LedgerTui", {}),
  }, LedgerTuiLayout)
  setup_highlight_groups()
  return self
end

return M
