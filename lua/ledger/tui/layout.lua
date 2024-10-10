local logger = require("ledger.logger").get()

local M = {}

--- @enum HlGroups
local HL_GROUPS = {
  LedgerTitle = "LedgerTitle",
  LedgerMuted = "LedgerMuted",
}

--- @class ledger.TuiLayout
--- @field previous_number boolean
--- @field previous_relative boolean
--- @field previous_signcolumn "no" | "yes"
--- @field output_buf integer
--- @field filters_buf integer
--- @field reports_buf integer
--- @field hint_buf integer
--- @field help_buf integer
--- @field augroup integer
local LedgerTuiLayout = {}
LedgerTuiLayout.__index = LedgerTuiLayout

--- @class ledger.TuiLayout
local instance

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

function LedgerTuiLayout.set_buffer_options()
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
--- ├───┴───────────┴───┤
--- │       HINT        │
--- └───────────────────┘
--- R: Reports pane
--- O: Outputs pane
--- F: Filters pane
function LedgerTuiLayout:setup_windows()
  vim.cmd("split")
  local hint_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(hint_buf)
  local hint_height = math.ceil(vim.o.lines * 0.1)
  vim.cmd("horizontal resize " .. hint_height)
  self.set_buffer_options()
  self:set_window_options()

  vim.cmd.wincmd("k")
  vim.cmd("vsplit")
  local output_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(output_buf)
  local output_width = math.ceil(vim.o.columns * 0.75)

  self.set_buffer_options()
  self:set_window_options()
  vim.cmd("vertical resize " .. output_width)
  vim.cmd("vsplit")

  local filters_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(filters_buf)
  self.set_buffer_options()
  self:set_window_options()
  local filter_width = math.ceil(vim.o.columns * 0.15)

  vim.cmd("vertical resize " .. filter_width)
  vim.cmd("wincmd h")
  vim.cmd("wincmd h")

  local reports_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(reports_buf)
  self.set_buffer_options()
  self:set_window_options()

  -- we defer locking the buffers to make sure their contents
  -- are completely written before doing so
  vim.defer_fn(function()
    vim.api.nvim_set_option_value("modifiable", false, { buf = output_buf })
    vim.api.nvim_set_option_value("modifiable", false, { buf = filters_buf })
    vim.api.nvim_set_option_value("modifiable", false, { buf = reports_buf })
  end, 100)

  logger:info("initialized tui pane buffers")
  self.hint_buf = hint_buf
  self.output_buf = output_buf
  self.filters_buf = filters_buf
  self.reports_buf = reports_buf
  self:setup_keymaps()
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

function LedgerTuiLayout.setup_highlight_groups()
  vim.api.nvim_set_hl(0, HL_GROUPS.LedgerTitle, {
    fg = "#F3F4F6",
    bg = "#8F2BF5",
    bold = true,
  })
  vim.api.nvim_set_hl(0, HL_GROUPS.LedgerMuted, {
    fg = "#9CA3AF",
    bg = nil,
    bold = false,
  })
end

--- @enum Buffers
LedgerTuiLayout.buffers = {
  Reports = "Reports",
  Output = "Output",
  Filters = "Filters",
  Hint = "Hint",
  Unknown = "Unknown",
}

--- @return boolean, Buffers
function LedgerTuiLayout:get_focused_buffer()
  local curr_buffer = vim.api.nvim_get_current_buf()
  if curr_buffer == self.reports_buf then
    return true, self.buffers.Reports
  elseif curr_buffer == self.output_buf then
    return true, self.buffers.Output
  elseif curr_buffer == self.filters_buf then
    return true, self.buffers.Filters
  elseif curr_buffer == self.hint_buf then
    return true, self.buffers.Hint
  end
  return false, self.buffers.Unknown
end

--- npm i leftpad
---
--- @param text string
--- @param with string
--- @param amount integer
--- @return string
local function left_pad(text, with, amount)
  return string.rep(with, amount) .. text
end

--- attempts to centralize a text on the buffer if there is enough
--- space available. When the string either is bigger than the screen,
--- or there is less than 2 columns of space, the string is returned as is
---
--- @param text string
--- @param width integer
--- @return string
local function centralize(text, width)
  local line_len = #text
  local remaining_space = width - line_len
  if remaining_space < 2 then
    return text
  end

  return left_pad(text, " ", math.ceil(remaining_space / 2))
end

function LedgerTuiLayout:update_hint()
  local ok, _ = self:get_focused_buffer()
  if not ok then
    return
  end

  local is_valid = vim.api.nvim_buf_is_valid(self.hint_buf)
  if not is_valid then
    return
  end

  local width = vim.o.columns
  local hints = {}

  local title = centralize("HINTS", width)
  local filters_hint = centralize("you can enable or disable filters on the right pane", width)
  local help_hint = centralize("press ? to see a better help screen! (and h to dismiss this)", width)
  table.insert(hints, title)
  table.insert(hints, "")
  table.insert(hints, filters_hint)
  table.insert(hints, "")
  table.insert(hints, help_hint)

  self.set_buffer_content(self.hint_buf, hints)
  vim.api.nvim_buf_add_highlight(self.hint_buf, 0, HL_GROUPS.LedgerTitle, 0, #title - #"HINTS", -1)
  vim.api.nvim_buf_add_highlight(self.hint_buf, 0, HL_GROUPS.LedgerMuted, 2, #filters_hint - 51, -1)
  vim.api.nvim_buf_add_highlight(self.hint_buf, 0, HL_GROUPS.LedgerMuted, 4, #help_hint - 60, -1)
end

function LedgerTuiLayout:setup_aucmds()
  vim.api.nvim_create_autocmd("CursorMoved", {
    buffer = self.reports_buf,
    group = self.augroup,
    callback = function()
      local reports = require("ledger.tui.reports").get()
      reports:maybe_run_command()
      reports:populate_filters()
      self:update_hint()
    end,
  })
end

local function toggle_help_popup()
  local layout = require("ledger.tui.layout").get()

  if layout.help_buf and layout.help_buf ~= -1 then
    vim.api.nvim_buf_delete(layout.help_buf, {})
    layout.help_buf = -1
    return
  end

  local height = 8
  local width = math.min(50, vim.o.columns)
  local center_y = math.floor(vim.o.lines / 2) - math.ceil(height / 2)
  local center_x = math.floor(vim.o.columns / 2) - math.ceil(width / 2)

  local buf = vim.api.nvim_create_buf(false, true)
  local close_message = centralize("press ? again to close this popup", width)
  local content = {
    " [Enter] - selects item under cursor",
    " [f]     - select filters buffer",
    " [r]     - select reports buffer",
    " [h]     - hides hint buffer",
    "",
    "",
    "",
    close_message,
  }

  layout.set_buffer_content(buf, content)
  vim.api.nvim_buf_add_highlight(buf, 0, HL_GROUPS.LedgerMuted, 7, #close_message - 33, -1)
  vim.api.nvim_open_win(buf, false, {
    relative = "editor",
    style = "minimal",
    height = height,
    width = width,
    row = center_y,
    col = center_x,
    title = "Help",
    border = "single",
  })

  layout.help_buf = buf
end

local function open_filter_input_popup()
  local layout = require("ledger.tui.layout").get()
  local config = require("ledger.config").get()

  local input_buf = vim.api.nvim_create_buf(false, true)
  local hint_buf = vim.api.nvim_create_buf(false, true)

  local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
  local selected_filter = vim.api.nvim_buf_get_lines(layout.filters_buf, row - 1, row, false)
  if #selected_filter == 0 then
    return
  end
  local filter_name = selected_filter[1]

  --- @type integer | nil
  local reports_win = nil

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == layout.reports_buf then
      reports_win = win
      break
    end
  end

  if not reports_win then
    return
  end

  local row, _ = unpack(vim.api.nvim_win_get_cursor(reports_win))
  local selected_report = vim.api.nvim_buf_get_lines(layout.reports_buf, row - 1, row, false)
  if #selected_report == 0 then
    return
  end
  local report_name = selected_report[1]
  --- @type ledger.TuiSection | nil
  local report
  for name, section in pairs(config.tui.sections) do
    if name == report_name then
      report = section
      break
    end
  end

  if not report then
    return
  end

  --- @type ledger.TuiFilter | nil
  local filter

  for name, f in pairs(report.filters) do
    if name == filter_name then
      filter = f
      break
    end
  end

  if not filter then
    return
  end

  local width = math.min(50, vim.o.columns)

  --- @param row integer
  --- @param col integer
  --- @param height integer
  --- @param title string | nil
  --- @return vim.api.keyset.win_config
  local function win_config(row, col, height, title)
    --- @type vim.api.keyset.win_config
    return {
      relative = "editor",
      style = "minimal",
      height = height,
      width = width,
      title = title,
      border = "single",
      row = row,
      col = col,
    }
  end

  local hint_content = {
    "applying filter on report: " .. report_name,
    "selected filter: " .. filter_name .. " (" .. filter.flag .. ")",
    "please enter the value for the filter",
    'use ":w" to confirm, ":q" to cancel',
  }

  layout.set_buffer_content(hint_buf, hint_content)

  local total_height = 3 + 6 + 1 -- +1 here is margin
  local center_y = math.floor(vim.o.lines / 2) - math.ceil(total_height / 2)
  local center_x = math.floor(vim.o.columns / 2) - math.ceil(width / 2)

  vim.api.nvim_open_win(hint_buf, false, win_config(center_y + 3 + 1, center_x, 4, "Summary"))
  vim.api.nvim_open_win(input_buf, true, win_config(center_y, center_x, 1))
end

local function dismiss_hint()
  local layout = require("ledger.tui.layout").get()
  local curr_buffer = vim.api.nvim_get_current_buf()
  if curr_buffer == layout.hint_buf then
    vim.api.nvim_set_current_buf(layout.reports_buf)
  end

  vim.api.nvim_buf_delete(layout.hint_buf, {})
  layout.hint_buf = -1
end

local function focus_reports()
  local layout = require("ledger.tui.layout").get()

  if not layout.reports_buf then
    return
  end

  local is_valid = vim.api.nvim_buf_is_valid(layout.reports_buf)
  if not is_valid then
    return
  end

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == layout.reports_buf then
      vim.api.nvim_set_current_win(win)
      break
    end
  end
end

local function focus_filters()
  local layout = require("ledger.tui.layout").get()

  if not layout.filters_buf then
    return
  end

  local is_valid = vim.api.nvim_buf_is_valid(layout.filters_buf)
  if not is_valid then
    return
  end

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == layout.filters_buf then
      vim.api.nvim_set_current_win(win)
      break
    end
  end
end

function LedgerTuiLayout:setup_keymaps()
  --- @param buffer integer
  local function set_buffer_maps(buffer)
    local keymaps = {
      ["?"] = { callback = toggle_help_popup, command = "ToggleHelp" },
      ["h"] = { callback = dismiss_hint, command = "DismissHint" },
      ["f"] = { callback = focus_filters, command = "FocusFilters" },
      ["r"] = { callback = focus_reports, command = "FocusReports" },
    }
    for key, action in pairs(keymaps) do
      vim.api.nvim_buf_create_user_command(buffer, action.command, action.callback, {})
      vim.api.nvim_buf_set_keymap(buffer, "n", key, ":" .. action.command .. "<CR>", {})
    end
  end

  set_buffer_maps(self.reports_buf)
  set_buffer_maps(self.output_buf)
  set_buffer_maps(self.filters_buf)
  set_buffer_maps(self.hint_buf)

  vim.api.nvim_buf_create_user_command(self.filters_buf, "OpenFilterInput", open_filter_input_popup, {})
  vim.api.nvim_buf_set_keymap(self.filters_buf, "n", "<CR>", ":OpenFilterInput<CR>", {})
end

--- @return ledger.TuiLayout
function M.setup()
  if not instance then
    instance = setmetatable({
      augroup = vim.api.nvim_create_augroup("LedgerTui", {}),
    }, LedgerTuiLayout)
    instance.setup_highlight_groups()
  end
  return instance
end

function M.get()
  return instance
end

return M
