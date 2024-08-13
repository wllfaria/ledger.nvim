local M = {}

M.account_query = vim.treesitter.query.parse(
  "ledger",
  [[
(journal_item
  (directive
    (account_directive
      (account) @account_name)))]]
)

M.commodities_query = vim.treesitter.query.parse(
  "ledger",
  [[
(journal_item
  (directive
    (commodity_directive
      (commodity) @commodity_name)))]]
)

return M
