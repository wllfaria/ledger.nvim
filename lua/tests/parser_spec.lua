describe("parser", function()
  local parser = require("ledger.parser")

  before_each(function()
    require("nvim-treesitter.install").ensure_installed("ledger")
    vim.cmd.enew()
    vim.bo.filetype = "ledger"
  end)

  it("should correctly get the scope of the cursor position", function()
    local file_content = [[
2024-01-01 * Any Description
    Account:Name:One              USD 1337
    Account:Name:Two              USD -1337
    ]]

    vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(file_content, "\n"))

    vim.api.nvim_win_set_cursor(0, { 2, 6 })
    local account_scope = parser.find_current_scope()

    vim.api.nvim_win_set_cursor(0, { 2, 36 })
    local commodity_scope = parser.find_current_scope()

    assert.are.equal(account_scope, parser.scopes.Account)
    assert.are.equal(commodity_scope, parser.scopes.Commodity)
  end)

  it("should get correct account names from file", function()
    local file_content = [[
account Account:Name:One
account Account:Name:Two
    ]]
    local expected = {
      ["test.ledger"] = {
        "Account:Name:One",
        "Account:Name:Two",
      },
    }

    local source = parser.get_parser(file_content)
    local ctx = { accounts = {} }
    parser.get_account_names_from_source(source.root, file_content, "test.ledger", ctx)

    assert.are.same(ctx.accounts, expected)
  end)

  it("should get correct commodity names from file", function()
    local file_content = [[
commodity BRL
commodity USD
commodity ETH
    ]]
    local expected = {
      ["test.ledger"] = {
        "BRL",
        "USD",
        "ETH",
      },
    }

    local source = parser.get_parser(file_content)
    local ctx = { commodities = {} }
    parser.get_commodities_from_source(source.root, file_content, "test.ledger", ctx)

    assert.are.same(ctx.commodities, expected)
  end)

  it("should correctly get postings of file", function()
    local file_content = [[
2024-01-01 * Any Description
    Account:Name:One              USD 1337
    Account:Name:Two              USD -1337

2024-01-01 * Any Description
    Account:Name:Three            USD
    Account:Name:Four
    ]]

    local expected = {
      ["test.ledger"] = {
        {
          account = {
            range = { end_col = 20, end_row = 1, start_col = 4, start_row = 1 },
            text = "Account:Name:One",
          },
          commodity = {
            range = { end_col = 37, end_row = 1, start_col = 34, start_row = 1 },
            text = "USD",
          },
          quantity = {
            range = { end_col = 42, end_row = 1, start_col = 38, start_row = 1 },
            text = "1337",
          },
        },
        {
          account = {
            range = { end_col = 20, end_row = 2, start_col = 4, start_row = 2 },
            text = "Account:Name:Two",
          },
          commodity = {
            range = { end_col = 37, end_row = 2, start_col = 34, start_row = 2 },
            text = "USD",
          },
          quantity = {
            range = { end_col = 43, end_row = 2, start_col = 38, start_row = 2 },
            text = "-1337",
          },
        },
        {
          account = {
            range = { end_col = 22, end_row = 5, start_col = 4, start_row = 5 },
            text = "Account:Name:Three",
          },
          commodity = {
            range = { end_col = 37, end_row = 5, start_col = 34, start_row = 5 },
            text = "USD",
          },
          quantity = {
            range = { end_col = 37, end_row = 5, start_col = 37, start_row = 5 },
            text = "",
          },
        },
        {
          account = {
            range = { end_col = 21, end_row = 6, start_col = 4, start_row = 6 },
            text = "Account:Name:Four",
          },
        },
      },
    }

    local source = parser.get_parser(file_content)
    local ctx = { postings = {} }
    parser.get_postings_from_source(source.root, file_content, "test.ledger", ctx)

    assert.are.same(ctx.postings, expected)
  end)
end)
