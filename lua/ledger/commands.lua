local M = {}

--- @class LedgerCommands
--- @field augroup integer
local LedgerCommands = {}
LedgerCommands.__index = LedgerCommands

--- @type LedgerCommands
local instance

function LedgerCommands:create_augroup()
  self.augroup = vim.api.nvim_create_augroup("Ledger", {})
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

function M.setup()
  instance = setmetatable({}, LedgerCommands)
  return instance
end

return M
