local M = {}

--- @class LedgerTui
local LedgerTui = {}
LedgerTui.__index = LedgerTui

--- @class LedgerTui
local instance

function LedgerTui:set_autocmds() end

--- @param buffer integer
function LedgerTui:set_buffer_options(buffer)
  vim.bo.buftype = "nofile"
  vim.bo.bufhidden = "wipe"
  vim.bo.swapfile = false
  vim.api.nvim_set_option_value("number", false, {})
  vim.api.nvim_set_option_value("relativenumber", false, {})
  vim.api.nvim_set_option_value("signcolumn", "no", {})
end

function LedgerTui:setup()
  print("initializing")
  -- Create a vertical split (left: information buffer, right: output buffer)
  vim.cmd("vsplit")

  -- Create an empty buffer for the output in the right window
  local output_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(output_buf)

  -- Set buffer options for output buffer
  self:set_buffer_options(output_buf)
  local output_width = math.ceil(vim.o.columns * 0.75)
  vim.cmd("vertical resize " .. output_width)

  -- Create a horizontal split below the output buffer (filters buffer)
  vim.cmd("split")

  -- Create an empty buffer for the filters in the bottom window
  local filters_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(filters_buf)

  -- Set buffer options for filters buffer
  self:set_buffer_options(filters_buf)
  local filter_height = math.ceil(vim.o.lines * 0.15)
  vim.cmd("horizontal resize " .. filter_height)

  -- Move back to the original left split (information buffer)
  vim.cmd("wincmd h")

  -- Create an empty buffer for the information in the left window
  local info_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(info_buf)

  -- Set buffer options for information buffer
  self:set_buffer_options(info_buf)

  -- Optionally set keymaps to close each buffer/window
  vim.api.nvim_buf_set_keymap(output_buf, "n", "q", ":q<CR>", { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(filters_buf, "n", "q", ":q<CR>", { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(info_buf, "n", "q", ":q<CR>", { noremap = true, silent = true })
end

function LedgerTui:shutdown()
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
    instance = setmetatable({}, LedgerTui)
  end
  return instance
end

function M.get()
  return instance
end

return M
