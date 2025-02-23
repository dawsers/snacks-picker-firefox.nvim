local has_snacks_picker, snacks_picker = pcall(require, "snacks.picker")
if not has_snacks_picker then
  error("This plugin requires folke/snacks.nvim")
end

local ok, sqlite = pcall(require, "sqlite.db")
if not ok then
  error "Firefox depends on sqlite.lua (https://github.com/kkharji/sqlite.lua)"
end

-- Set default values for highlighting groups
vim.cmd("highlight default link PickerFirefoxDate Number")
vim.cmd("highlight default link PickerFirefoxFolder Keyword")
vim.cmd("highlight default link PickerFirefoxTitle Function")
vim.cmd("highlight default link PickerFirefoxUrl Comment")

local M = {}

local defaults = {
  url_open_command = "xdg-open",
  firefox_profile_dir = "~/.mozilla/firefox",
  firefox_profile_glob = "*.default*"
}

-- Local database related variables
local dbfile, dbcopy
local history_sql_query = "SELECT b.title AS Title, b.url AS URL, DATETIME(a.visit_date/1000000,'unixepoch') AS DateAdded FROM moz_historyvisits AS a JOIN moz_places AS b ON b.id = a.place_id ORDER BY DateAdded DESC"
local bookmarks_sql_query = "SELECT c.title AS Parent, a.title AS Title, b.url AS URL, DATETIME(a.dateAdded/1000000,'unixepoch') AS DateAdded FROM moz_bookmarks AS a JOIN moz_places AS b ON a.fk = b.id, moz_bookmarks AS c WHERE a.parent = c.id"
local search_sql_query = "SELECT title AS Title, description AS Description, url AS URL, DATETIME(last_visit_date/1000000,'unixepoch') AS LastDate FROM moz_places ORDER BY LastDate DESC"

local function str_prepare(str, len)
  local s
  if #str > len then
    s = string.sub(str, 1, len)
  else
    s = str
  end
  local format = "%-" .. tostring(len) .. "s"
  return string.format(format, s)
end

local function file_copy(src, dst)
  local fsrc, serr = io.open(src, 'rb')
  if serr or not fsrc then
    error(serr)
  end
  local data = fsrc:read('*a')
  fsrc:close()
  local fdst, derr = io.open(dst, 'w')
  if derr or not fdst then
    error(derr)
  end
  fdst:write(data)
  fdst:close()
end

local function get_results(sql_query)
  local db = sqlite.new(dbcopy):open()
  local rows = db:eval(sql_query)
  return rows
end

local function copy_database()
  vim.schedule(function()
    dbfile = vim.fn.globpath(M.opts.firefox_profile_dir, M.opts.firefox_profile_glob .. '/places.sqlite')
    if not dbfile then
      error "Cannot find Firefox database"
    end

    -- Make a temporary copy of the database in case Firefox is running and has
    -- locked the database
    dbcopy = vim.fn.tempname()
    file_copy(dbfile, dbcopy)
  end)
end

local function url_open(url)
  snacks_picker.util.cmd({ M.opts.url_open_command, url }, function() end, {})
end


local function make_search_line(v)
  return (v.LastDate or "") .. " " .. (v.Title or "") .. " " .. (v.Description or "") .. " " .. (v.URL or "")
end

local function make_bookmarks_line(v)
  return (v.DateAdded or "") .. " " .. (v.Parent or "") .. " " .. (v.Title or "") .. " " .. (v.URL or "")
end

local function make_history_line(v)
  return (v.DateAdded or "") .. " " .. (v.Title or "") .. " " .. (v.URL or "")
end

local function create_search_items()
  local results = get_results(search_sql_query)
  for _, result in pairs(results) do
    result.text = make_search_line(result)
  end
  return results
end

local function create_bookmarks_items()
  local results = get_results(bookmarks_sql_query)
  for _, result in pairs(results) do
    result.text = make_bookmarks_line(result)
  end
  return results
end

local function create_history_items()
  local results = get_results(history_sql_query)
  for _, result in pairs(results) do
    result.text = make_history_line(result)
  end
  return results
end

local function firefox_picker()
  return {
    win = {
      input = {
        keys = {
          ["<C-y>"] = { "yank_url", desc = "Yank URLs to clipboard", mode = { "n", "i" } },
        }
      }
    },
    layout = {
      preview = "main",
    },
    preview = function() end,
    confirm = function(picker, _)
      local items = picker:selected({ fallback = true })
      for _, item in pairs(items) do
        url_open(item.URL)
      end
      picker:close()
    end,
    actions = {
      yank_url = function(picker, _)
        local items = picker:selected({ fallback = true })
        local data = ""
        for _, item in pairs(items) do
          data = data .. item.URL .. '\n'
        end
        -- Remove the last '\n'
        vim.fn.setreg(vim.v.register, string.sub(data, 1, -2))
      end,
    }
  }
end

local function firefox_search_picker()
  local firefox = firefox_picker()
  firefox.win.title = "Search"
  firefox.finder = create_search_items
  firefox.format = function(item)
    local ret = {}
    ret[#ret + 1] = { str_prepare(item.LastDate or "", 11), "PickerFirefoxDate" }
    ret[#ret + 1] = { " " }
    ret[#ret + 1] = { str_prepare((item.Title or "") .. " " .. (item.Description or ""), 99), "PickerFirefoxTitle" }
    ret[#ret + 1] = { " " }
    ret[#ret + 1] = { item.URL or "", "PickerFirefoxUrl" }
    return ret
  end
  return firefox
end

local function firefox_bookmarks_picker()
  local firefox = firefox_picker()
  firefox.win.title = "Bookmark"
  firefox.finder = create_bookmarks_items
  firefox.format = function(item)
    local ret = {}
    ret[#ret + 1] = { str_prepare(item.DateAdded or "", 11), "PickerFirefoxDate" }
    ret[#ret + 1] = { " " }
    ret[#ret + 1] = { str_prepare(item.Parent or "", 16), "PickerFirefoxFolder" }
    ret[#ret + 1] = { " " }
    ret[#ret + 1] = { string.format("%-70s", item.Title or ""), "PickerFirefoxTitle" }
    ret[#ret + 1] = { " " }
    ret[#ret + 1] = { item.URL or "", "PickerFirefoxUrl" }
    return ret
  end
  return firefox
end

local function firefox_history_picker()
  local firefox = firefox_picker()
  firefox.win.title = "History"
  firefox.finder = create_history_items
  firefox.format = function(item)
    local ret = {}
    ret[#ret + 1] = { string.format("%-20s", item.DateAdded or ""), "PickerFirefoxDate" }
    ret[#ret + 1] = { " " }
    ret[#ret + 1] = { string.format("%-70s", item.Title or ""), "PickerFirefoxTitle" }
    ret[#ret + 1] = { " " }
    ret[#ret + 1] = { item.URL or "", "PickerFirefoxUrl" }
    return ret
  end
  return firefox
end

function M.setup(opts)
  M.opts = vim.tbl_deep_extend("force", defaults, opts or {})

  copy_database()

  snacks_picker.sources.firefox_search = firefox_search_picker()
  snacks_picker.sources.firefox_bookmarks = firefox_bookmarks_picker()
  snacks_picker.sources.firefox_history = firefox_history_picker()
end

return M
