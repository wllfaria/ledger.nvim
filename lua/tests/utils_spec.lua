local utils = require("ledger.utils")

describe("utils", function()
  it("test", function()
    local list_a = { "list original" }
    local list_b = { "list item 1", "list item 2" }
    local expected_list = { "list original", "list item 1", "list item 2" }

    local table_a = { first_key = "table_item original" }
    local table_b = { first_key = "table item 1", other_key = "table item 2" }
    local expected_table = { first_key = "table_item original", other_key = "table item 2" }

    local result_list = utils.tbl_merge("force", list_a, list_b)
    local result_table = utils.tbl_merge("keep", table_a, table_b)

    assert.are.same(result_list, expected_list)
    assert.are.same(result_table, expected_table)
  end)
end)
