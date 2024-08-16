local config = require("ledger.config").get()
local utils = require("ledger.utils")

local M = {
  namespace = vim.api.nvim_create_namespace("ledger"),
}

--- @class ledger.Missing
--- @field filename string
--- @field text string
--- @field range TSRange

--- look on every posting recorded to check if any account is missing
--- a declaration
---
--- @return table<string, ledger.Missing[]>
function M.get_missing_accounts()
  local context = require("ledger.context").get()

  local missing_accounts = {}

  for filename, postings in pairs(context.postings) do
    for _, posting in pairs(postings) do
      local account_name = posting.account.text
      local has_account = false

      for _, accounts in pairs(context.accounts) do
        if vim.tbl_contains(accounts, account_name) then
          has_account = true
        end
      end

      if not has_account then
        if not missing_accounts[filename] then
          missing_accounts[filename] = {}
        end
        table.insert(missing_accounts[filename], {
          filename = filename,
          text = account_name,
          range = posting.account.range,
        })
      end
    end
  end

  return missing_accounts
end

--- look on every posting registered to find if any commodity is missing
--- a declaration.
---
--- @return table<string, ledger.Missing[]>
function M.get_missing_commodities()
  local context = require("ledger.context").get()

  local missing_accounts = {}

  for filename, postings in pairs(context.postings) do
    for _, posting in pairs(postings) do
      local commodity_name = posting.commodity.text
      local has_commodity = false

      for _, accounts in pairs(context.commodities) do
        if vim.tbl_contains(accounts, commodity_name) then
          has_commodity = true
        end
      end

      if not has_commodity then
        if not missing_accounts[filename] then
          missing_accounts[filename] = {}
        end
        table.insert(missing_accounts[filename], {
          filename = filename,
          text = commodity_name,
          range = posting.account.range,
        })
      end
    end
  end

  return missing_accounts
end

--- set missing accounts diagnostics
---
--- @param missing_accounts table<string, ledger.Missing[]>
function M.set_missing_account_diagnostics(missing_accounts)
  for filename, accounts in pairs(missing_accounts) do
    local diagnostics = {}

    for _, missing_account in pairs(accounts) do
      local diagnostic = {
        lnum = missing_account.range.start_row,
        col = missing_account.range.start_col,
        end_lnum = missing_account.range.end_row,
        end_col = missing_account.range.end_col,
        message = string.format(
          [[line %d: Unknown account '%s'
  this account was not previously declared, you may want to declare it
          ]],
          missing_account.range.start_row + 1,
          missing_account.text
        ),
        severity = config.diagnostics.strict and vim.diagnostic.severity.ERROR or vim.diagnostic.severity.WARN,
      }
      table.insert(diagnostics, diagnostic)
    end

    if #diagnostics then
      local bufnr = vim.fn.bufnr(filename, true)
      if bufnr ~= -1 then
        local existing_diagnostics = vim.diagnostic.get(bufnr)
        local new_diagnostics = utils.tbl_merge("force", existing_diagnostics, diagnostics)
        vim.diagnostic.set(M.namespace, bufnr, new_diagnostics, {})
      end
    end
  end
end

--- set missing commodities diagnostics
---
--- @param missing_diagnostics table<string, ledger.Missing[]>
function M.set_missing_commodities_diagnostics(missing_diagnostics)
  for filename, accounts in pairs(missing_diagnostics) do
    local diagnostics = {}

    for _, missing_commodity in pairs(accounts) do
      local diagnostic = {
        lnum = missing_commodity.range.start_row,
        col = missing_commodity.range.start_col,
        end_lnum = missing_commodity.range.end_row,
        end_col = missing_commodity.range.end_col,
        message = string.format(
          [[line %d: Unknown commodity '%s'
  this commodity was not previously declared, you may want to declare it
        ]],
          missing_commodity.range.start_row + 1,
          missing_commodity.text
        ),
        severity = config.diagnostics.strict and vim.diagnostic.severity.ERROR or vim.diagnostic.severity.WARN,
      }
      table.insert(diagnostics, diagnostic)
    end

    if #diagnostics then
      local bufnr = vim.fn.bufnr(filename, true)
      if bufnr ~= -1 then
        local existing_diagnostics = vim.diagnostic.get(bufnr)
        local new_diagnostics = utils.tbl_merge("force", existing_diagnostics, diagnostics)
        vim.diagnostic.set(M.namespace, bufnr, new_diagnostics, {})
      end
    end
  end
end

--- sets diagnostics for commodities and accounts that miss declarations
--- on other ledger files
---
--- @param missing_accounts table<string, ledger.Missing[]>
--- @param missing_commodities table<string, ledger.Missing[]>
function M.set_lsp_diagnostics(missing_accounts, missing_commodities)
  vim.diagnostic.reset(M.namespace)
  M.set_missing_account_diagnostics(missing_accounts)
  M.set_missing_commodities_diagnostics(missing_commodities)
end

function M.get_diagnostics()
  if not config.diagnostics:is_enabled() then
    return
  end

  local missing_accounts = M.get_missing_accounts()
  local missing_commodities = M.get_missing_commodities()

  if config.diagnostics.lsp_diagnostics then
    M.set_lsp_diagnostics(missing_accounts, missing_commodities)
  end
end

return M
