--- @class ledger.Files
--- @field is_ledger fun(path: string): boolean
--- @field is_directory fun(path: string): boolean
--- @field read_dir_rec fun(base_path: string): table<string, string>
--- @field read_file fun(path: string): boolean, string[]
--- @field has_ledger_file fun(path: string): boolean
--- @field cwd fun(): string
local M = {}

--- given a file path, returns true when the file matches any of
--- the extensions set in the config, return false otherwise
---
--- @param path string
--- @return boolean
function M.is_ledger(path)
  local config = require("ledger.config").get()
  local has_match = false
  for _, extension in pairs(config.extensions) do
    if has_match then
      goto continue
    end
    has_match = path:match(extension) ~= nil and true or false
  end
  ::continue::
  return has_match
end

--- given a path, return true if its a directory or false if its not
--- or if its an invalid path
---
--- @param path string
--- @return boolean
function M.is_directory(path)
  local ok, result = pcall(vim.uv.fs_stat, path)
  if not ok then
    return false
  end
  return result ~= nil and result.type == "directory" or false
end

--- whether a path should be ignored or not on file operations, like reading
--- recursively.
---
--- @param path string
--- @return boolean
function M.should_ignore(path)
  local config = require("ledger.config").get()

  for _, entry in pairs(config.default_ignored_paths) do
    if path:match(entry) then
      return true
    end
  end

  return false
end

--- Reads a directory recursively, adding every file defined in the config
--- `extensions` entry into a map of file names to file path. returning the
--- map of files at the end, eg:
---
--- ```lua
--- { ["filename.ledger"] = "/path/to/filename.ledger" }
--- ```
---
--- @param base_path string
--- @return table<string, string>
function M.read_dir_rec(base_path)
  local map = {}

  local function recurse(path, acc)
    local ok, entries = pcall(vim.fn.readdir, path)
    if not ok then
      return
    end
    for _, entry in pairs(entries) do
      local full_path = vim.fs.joinpath(path, entry)
      if M.should_ignore(full_path) then
        goto continue
      end
      if M.is_directory(full_path) then
        recurse(full_path, acc)
      end
      if M.is_ledger(entry) and not M.is_directory(full_path) then
        acc[entry] = full_path
      end
      ::continue::
    end
  end

  recurse(base_path, map)

  return map
end

--- reads every line from a path `filename` and returns
--- a tuple of `ok` and `lines`, where ok is true if the
--- file exists and could be read
---
--- @param filename string
--- @return boolean, string[]?
function M.read_file(filename)
  local ok, lines = pcall(vim.fn.readfile, filename)
  if not ok then
    return false, nil
  end
  return true, lines
end

--- reads every entry on the given path and returns true when
--- a valid ledger extension was found or false otherwise. This
--- will also return false if the path is invalid.
---
--- @param path string
--- @return boolean
function M.has_ledger_file(path)
  local ok, entries = pcall(vim.fn.readdir, path)
  if not ok then
    return false
  end

  for _, entry in ipairs(entries) do
    if M.is_ledger(entry) then
      return true
    end
  end

  return false
end

--- creates a directory in the given path if possible
---
--- @param path string
function M.mkdir(path)
  vim.fn.mkdir(path, "p")
end

--- creates a file in the given path if possible
---
--- @param path string
--- @return boolean
function M.mkfile(path)
  local ok, exist = pcall(vim.uv.fs_stat, path)
  if not ok then
    error("failed to stat data path")
  end
  if not exist then
    local fd = io.open(path, "w+")
    if not fd then
      return false
    end
    fd:write("")
    fd:close()
  end
  return true
end

--- checks if a path exists, returns true if it exists, or false if it
--- doens't exist or if fs_stat fails for any reason.
---
--- @param path string
function M.file_exist(path)
  local ok, exist = pcall(vim.uv.fs_stat, path)
  if not ok then
    return false
  end
  if not exist then
    return false
  end
  return true
end

--- removes a file if it exists, do nothing otherwise
---
--- @param path string
function M.rmfile(path)
  local file_exist = M.file_exist(path)
  if file_exist then
    vim.uv.fs_unlink(path)
  end
end

--- returns the current working directory
---
--- @return string
function M.cwd()
  return vim.fn.getcwd()
end

return M
