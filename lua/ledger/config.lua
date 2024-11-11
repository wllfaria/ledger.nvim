local M = {}

--- @class ledger.Tui
--- @field enabled boolean
--- @field sections table<string, ledger.TuiSection>
--- @field open_in_tab boolean

--- @class ledger.TuiFilter
--- @field flag string
--- @field input boolean

--- @class ledger.TuiSection
--- @field command string
--- @field filters table<string, ledger.TuiFilter[]>

--- @class ledger.SnippetKeymaps
--- @field new_account string[]
--- @field new_posting string[]
--- @field new_posting_today string[]
--- @field new_commodity string[]

--- @class ledger.ReportKeymap
--- @field name string
--- @field key string
--- @field command string

--- @class ledger.TuiKeymaps
--- @field initialize string[]
--- @field shutdown string[]

--- @class ledger.Keymaps
--- @field snippets ledger.SnippetKeymaps
--- @field reports ledger.ReportKeymap[]
--- @field tui ledger.TuiKeymaps

--- @class ledger.PartialKeymaps
--- @field snippets? ledger.SnippetKeymaps
--- @field reports? ledger.ReportKeymap[]

--- @class ledger.CompletionSource
--- @field enabled boolean

--- @class ledger.SnippetSource
--- @field enabled boolean

--- @class ledger.Completion
--- @field cmp ledger.CompletionSource

--- @class ledger.Snippet
--- @field native ledger.SnippetSource
--- @field luasnip ledger.SnippetSource
--- @field cmp ledger.SnippetSource

--- @class ledger.PartialConfig
--- @field extensions string[]?
--- @field completion ledger.Completion?
--- @field snippets ledger.Snippet?
--- @field keymaps ledger.PartialKeymaps?
--- @field diagnostics ledger.Diagnostics?

--- @class ledger.Diagnostics
--- @field lsp_diagnostics boolean
--- @field strict boolean

--- @class ledger.Config
--- @field plugin_name string
--- @field extensions string[]
--- @field default_ignored_paths string[]
--- @field completion ledger.Completion
--- @field snippets ledger.Snippet
--- @field keymaps ledger.Keymaps
--- @field diagnostics ledger.Diagnostics
--- @field tui ledger.Tui
local LedgerConfig = {}
LedgerConfig.__index = LedgerConfig

--- @type ledger.Config
local instance = nil

--- @class ledger.Snippet
local LedgerConfigSnippets = {}
LedgerConfigSnippets.__index = LedgerConfigSnippets

--- @class ledger.Completion
local LedgerConfigCompletion = {}
LedgerConfigCompletion.__index = LedgerConfigCompletion

--- @class ledger.Diagnostics
local LedgerConfigDiagnostics = {}
LedgerConfigDiagnostics.__index = LedgerConfigDiagnostics

--- @class ledger.

--- checks if any of the completion providers are enabled and return
--- true/false
---
--- @return boolean
function LedgerConfigCompletion:is_enabled()
  if self.cmp.enabled then
    return true
  end
  return false
end

--- checks if any of the existing snippet providers are available and
--- return true/false
---
--- @return boolean
function LedgerConfigSnippets:is_enabled()
  if self.native.enabled then
    return true
  elseif self.luasnip.enabled then
    return true
  elseif self.cmp.enabled then
    return true
  end
  return false
end

--- checks if any of the existing snippet providers are available and
--- return true/false
---
--- @return boolean
function LedgerConfigDiagnostics:is_enabled()
  if self.lsp_diagnostics then
    return true
  end
  return false
end

function LedgerConfig.__tostring()
  return "<LedgerConfig>"
end

--- @return ledger.Config
local function get_default_config()
  --- @type ledger.Config
  local default_config = {
    plugin_name = "ledger.nvim",
    extensions = {
      "ledger",
      "hledger",
      "journal",
    },
    completion = setmetatable({
      cmp = { enabled = true },
    }, LedgerConfigCompletion),
    default_ignored_paths = {
      ".git",
    },
    diagnostics = setmetatable({
      lsp_diagnostics = true,
      strict = false,
    }, LedgerConfigDiagnostics),
    snippets = setmetatable({
      native = { enabled = false },
      cmp = { enabled = true },
      luasnip = { enabled = false },
    }, LedgerConfigSnippets),
    keymaps = {
      snippets = {
        new_posting = { "tt" },
        new_account = { "acc" },
        new_posting_today = { "td" },
        new_commodity = { "cm" },
      },
      reports = {},
      tui = {
        initialize = { "<leader>tui" },
        shutdown = { "<leader>tud" },
      },
    },
    tui = {
      enabled = true,
      open_in_tab = true,
      sections = {
        ["Show Balance"] = {
          command = "ledger --strict -f main.ledger bal",
          filters = {
            ["Period"] = {
              flag = "-p",
              input = true,
            },
          },
        },
        ["Show Budget"] = {
          command = "ledger --strict -f main.ledger budget",
          filters = {
            ["Another"] = {
              flag = "-p",
              input = true,
            },
          },
        },
      },
    },
  }

  return default_config
end

--- set keymaps for running reports
function LedgerConfig:set_keymaps()
  local commands = require("ledger.commands").setup()
  for _, keymap in pairs(self.keymaps.reports) do
    vim.keymap.set("n", keymap.key, function()
      commands:run_report(keymap.command)
    end)
  end

  if not self.tui.enabled then
    return
  end

  local tui = require("ledger.tui").get()
  tui:set_keymaps()
end

--- Config is a singleton, allowing us to call `get` as many times as we
--- want and always getting the same instance, so we don't have to pass
--- the table around
---
--- @param overrides? ledger.PartialConfig
--- @return ledger.Config
function M.setup(overrides)
  if not instance then
    local default = get_default_config()
    local with_overrides = vim.tbl_deep_extend("force", default, overrides or {})
    instance = setmetatable(with_overrides, LedgerConfig)
  end
  return instance
end

function M.get()
  return instance
end

return M
