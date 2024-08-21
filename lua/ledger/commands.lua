local files = require("ledger.files")

local M = {}

--- @class LedgerCommands
--- @field augroup integer
--- @field tui_augroup integer
--- @field output_augroup integer
local LedgerCommands = {}
LedgerCommands.__index = LedgerCommands

--- @class LedgerCommands
local instance

function LedgerCommands:create_augroups()
  self.augroup = vim.api.nvim_create_augroup("Ledger", {})
  self.tui_augroup = vim.api.nvim_create_augroup("LedgerTui", {})
  self.output_augroup = vim.api.nvim_create_augroup("LedgerOutput", {})
end

--- @param buf integer
function LedgerCommands:set_up_output_buffer(buf)
  vim.api.nvim_buf_create_user_command(buf, "LedgerOutputClose", function()
    vim.api.nvim_buf_delete(buf, { force = true, unload = true })
  end, {})

  vim.api.nvim_buf_set_keymap(buf, "n", "q", ":LedgerOutputClose<CR>", {})

  vim.api.nvim_create_autocmd("BufLeave", {
    group = self.output_augroup,
    buffer = buf,
    callback = function()
      vim.cmd("LedgerOutputClose")
    end,
  })
end

--- @param command string
function LedgerCommands:run_report(command)
  local cwd = files.cwd()
  local command_args = vim.split(command, " ")

  vim.cmd("split")
  vim.cmd("enew")

  local buf = vim.api.nvim_get_current_buf()

  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].swapfile = false
  vim.bo[buf].bufhidden = "wipe"
  self:set_up_output_buffer(buf)

  local ok, result = pcall(vim.system, command_args, { cwd = cwd })

  if not ok then
    local message = {
      "Something went wrong. Failed to run report command:",
      command,
      "",
      "With stdout message:",
      result,
    }
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, message)
    return
  end

  local result_output = result:wait().stdout
  if not result_output then
    error("ledger command should always return output")
    return
  end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(result_output, "\n"))

  vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
end

function LedgerCommands:setup_autocommands()
  local config = require("ledger.config").get()
  local pattern = {}
  for _, extension in pairs(config.extensions) do
    table.insert(pattern, "*." .. extension)
  end

  vim.api.nvim_create_autocmd("BufEnter", {
    pattern = pattern,
    group = self.augroup,
    callback = function()
      local filename = vim.fn.expand("%:t")
      local full_path = vim.fn.expand("%")
      local context = require("ledger.context").get()
      local has_file = context:has_file(full_path)
      if not has_file then
        context:add_file(filename, full_path)
      end
      context:purge_orphan_files()
    end,
  })

  vim.api.nvim_create_autocmd("BufWritePost", {
    pattern = pattern,
    group = self.augroup,
    callback = function()
      local filename = vim.fn.expand("%:t")
      local full_path = vim.fn.expand("%")
      local context = require("ledger.context").get()
      context:add_file(filename, full_path)

      if config.diagnostics:is_enabled() then
        local diagnostics = require("ledger.diagnostics")
        diagnostics.get_diagnostics()
      end
    end,
  })
end

function LedgerCommands:setup_tui_autocommands()
  self.tui_augroup = tui
end

function M.setup()
  if not instance then
    instance = setmetatable({}, LedgerCommands)
  end
  return instance
end

return M
