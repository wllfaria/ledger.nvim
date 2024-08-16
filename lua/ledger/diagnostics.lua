local config = require("ledger.config").get()

local M = {}

--- @class ledger.MissingAccount
--- @field filename string
--- @field text string
--- @field range TSRange

--- @return table<string, ledger.MissingAccount[]>
function M.analysis_missing_accounts()
  local context = require("ledger.context").get()

  local missing_accounts = {}

  for filename, postings in pairs(context.postings) do
    for _, posting in pairs(postings) do
      local account_name = posting.account.text
      local has_account = false

      for _, accounts in pairs(context.accounts) do
        has_account = vim.tbl_contains(accounts, account_name)
        if has_account then
          goto continue
        end
      end

      if not missing_accounts[filename] then
        missing_accounts[filename] = {}
      end
      table.insert(missing_accounts[filename], {
        filename = filename,
        text = account_name,
        range = posting.account.range,
      })

      ::continue::
    end
  end

  return missing_accounts
end

--- @param missing_accounts table<string, ledger.MissingAccount[]>
function M.set_lsp_diagnostics(missing_accounts)
  local namespace = vim.api.nvim_create_namespace("ledger")

  for filename, accounts in pairs(missing_accounts) do
    local diagnostics = {}

    for _, missing_account in pairs(accounts) do
      local diagnostic = {
        lnum = missing_account.range.start_row,
        col = missing_account.range.start_col,
        end_lnum = missing_account.range.end_row,
        end_col = missing_account.range.end_col,
        message = string.format(
          "line %d: Unknown account '%s'",
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
        vim.diagnostic.set(namespace, bufnr, diagnostics, {})
      end
    end
  end
end

function M.get_diagnostics()
  if not config.diagnostics:is_enabled() then
    return
  end

  local missing_accounts = M.analysis_missing_accounts()

  if config.diagnostics.lsp_diagnostics then
    M.set_lsp_diagnostics(missing_accounts)
  end
end

return M
