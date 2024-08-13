local M = {}

local function get_parser(source)
  local parser = vim.treesitter.get_string_parser(source, "ledger")

  print("a")
end

return M
