#!/usr/bin/env lua
-- List keyboard shortcuts configured in the Neovim Lua config.
-- Usage: nvim-shortcuts.lua [-v] [config-dir]

local prog = arg and arg[0] and arg[0]:match("[^/]+$") or "nvim-shortcuts.lua"

local function usage()
  io.write("Usage: " .. prog .. " [-v] [-s] [--sort=FIELDS] [config-dir]\n"
    .. "List keyboard shortcuts in the Neovim Lua config.\n"
    .. "\n"
    .. "Arguments:\n"
    .. "  config-dir   config root (default: $NVIM_CONFIG_DIR or ~/.config/nvim)\n"
    .. "\n"
    .. "Options:\n"
    .. "  -v, --verbose  show WHAT and file location columns\n"
    .. "  -s, --sort [FIELDS]  sort by mode, then key, or by FIELDS\n"
    .. "  -s=FIELDS, --sort=FIELDS  same, attached form (fields: mode, key, desc)\n"
    .. "  -h, --help     show this help\n")
end

local function read_file(path)
  local f, err = io.open(path, "r")
  if not f then
    return nil, err
  end
  local s = f:read("*a")
  f:close()
  return s
end

local function list_lua_files(root)
  root = root:gsub("/+$", "") .. "/"
  local cmd = "find '" .. root:gsub("'", "'\\''") .. "' -name '*.lua' | sort"
  local h = io.popen(cmd, "r")
  if not h then
    return {}
  end
  local files = {}
  for line in h:lines() do
    files[#files + 1] = line
  end
  h:close()
  return files
end

local function line_of(content, pos)
  local n = 1
  for _ in content:sub(1, pos):gmatch("\n") do
    n = n + 1
  end
  return n
end

-- Parse "(modes, lhs, rhs, opts)" inner text, without outer parens.
local function parse_call(inner)
  local pos = 1
  local modes = {}
  local _, e, tbl = inner:find("^%s*(%b{})", pos)
  if tbl then
    for m in tbl:gmatch("['\"]([^'\"]+)['\"]") do
      modes[#modes + 1] = m
    end
    if #modes == 0 then
      return nil
    end
    pos = e + 1
  else
    local _, me, m = inner:find("^%s*['\"]([^'\"]+)['\"]", pos)
    if not m then
      return nil
    end
    modes = { m }
    pos = me + 1
  end
  local comma = inner:find(",", pos, true)
  if not comma then
    return nil
  end
  pos = comma + 1
  local _, le, lhs = inner:find("%s*['\"]([^'\"]*)['\"]", pos)
  if not lhs then
    return nil
  end
  pos = le + 1
  local rhs = ""
  local comma2 = inner:find(",", pos, true)
  if comma2 then
    local rest = inner:sub(comma2 + 1):match("^%s*(.-)%s*$")
    local q = rest:sub(1, 1)
    if q == "'" or q == '"' then
      rhs = rest:match("^" .. q .. "(.-)" .. q) or ""
    elseif rest:match("^function") then
      rhs = "<function>"
    else
      rhs = rest:match("^([%w_%.:]+)") or ""
    end
  end
  local desc = inner:match("desc%s*=%s*['\"](.-)['\"]") or ""
  return modes, lhs, rhs, desc
end

local field_names = { mode = "mode", key = "lhs", desc = "desc" }

local function split_fields(spec)
  local fields = {}
  for name in spec:gmatch("[^,]+") do
    local f = field_names[name]
    if not f then
      io.stderr:write(prog .. ": unknown sort field: " .. name .. "\n")
      os.exit(2)
    end
    fields[#fields + 1] = f
  end
  if #fields == 0 then
    io.stderr:write(prog .. ": empty --sort fields\n")
    os.exit(2)
  end
  return fields
end

local function valid_fields(spec)
  if spec == "" then
    return false
  end
  for name in spec:gmatch("[^,]+") do
    if not field_names[name] then
      return false
    end
  end
  return true
end

local function main()
  local verbose = false
  local sort_fields = { "desc" }
  local root = nil
  local i = 1
  while i <= #arg do
    local a = arg[i]
    if a == "-h" or a == "--help" then
      usage()
      return
    elseif a == "-v" or a == "--verbose" then
      verbose = true
    elseif a == "-s" or a == "--sort" then
      local next_a = arg[i + 1]
      if next_a and valid_fields(next_a) then
        sort_fields = split_fields(next_a)
        i = i + 1
      else
        sort_fields = { "mode", "lhs" }
      end
    elseif a:match("^%-s=") or a:match("^%-%-sort=") then
      sort_fields = split_fields(a:match("=(.-)$"))
    elseif a:sub(1, 1) == "-" then
      io.stderr:write(prog .. ": unknown option: " .. a .. "\n")
      usage()
      os.exit(2)
    elseif not root then
      root = a
    else
      io.stderr:write(prog .. ": unexpected argument: " .. a .. "\n")
      usage()
      os.exit(2)
    end
    i = i + 1
  end
  root = root or os.getenv("NVIM_CONFIG_DIR")
    or (os.getenv("HOME") .. "/.config/nvim")
  local rows = {}
  for _, file in ipairs(list_lua_files(root)) do
    local content = read_file(file)
    if content then
      local calls = {}
      local function add(s, parens)
        calls[#calls + 1] = { pos = s, parens = parens }
      end
      for s, parens in content:gmatch("()vim%.keymap%.set%s*(%b())") do
        add(s, parens)
      end
      for s, parens in content:gmatch("()vim%.api%.nvim_%w*set_keymap%s*(%b())") do
        add(s, parens)
      end
      local nvim_calls = #calls
      for s in content:gmatch("()map%s*(%b())") do
        local prev = content:sub(math.max(1, s - 1), s - 1)
        local before = content:sub(math.max(1, s - 10), s - 1)
        if not prev:match("[%w_%.:]") and not before:match("function%s*$") then
          local parens = content:match("%b()", s + 3)
          if parens then
            local dup = false
            for i = 1, nvim_calls do
              local c = calls[i]
              if s >= c.pos and s < c.pos + #c.parens + 20 then
                dup = true
                break
              end
            end
            if not dup then
              add(s, parens)
            end
          end
        end
      end
      table.sort(calls, function(a, b) return a.pos < b.pos end)
      for _, c in ipairs(calls) do
        local inner = c.parens:sub(2, -2)
        local modes, lhs, rhs, desc = parse_call(inner)
        if modes and lhs then
          local short = file
          if short:sub(1, #root) == root then
            short = short:sub(#root + 2)
          end
          rows[#rows + 1] = {
            mode = table.concat(modes, ","),
            lhs = lhs,
            desc = desc,
            rhs = rhs,
            loc = short .. ":" .. line_of(content, c.pos),
          }
        end
      end
    end
  end
  if #rows == 0 then
    io.stderr:write("no shortcuts found in " .. root .. "\n")
    os.exit(1)
  end
  table.sort(rows, function(a, b)
    for _, f in ipairs(sort_fields) do
      if a[f] ~= b[f] then
        return a[f] < b[f]
      end
    end
    return a.loc < b.loc
  end)
  local wmode, wlhs = 4, 3
  for _, r in ipairs(rows) do
    wmode = math.max(wmode, #r.mode)
    wlhs = math.max(wlhs, #r.lhs)
  end
  local red, none = "\27[0;31m", "\27[0m"
  local function show_key(key, plain)
    local pad = string.rep(" ", wlhs - #key)
    if plain then
      return key .. pad
    end
    return red .. key .. none .. pad
  end
  if not verbose then
    local fmt = "%-" .. wmode .. "s  %s  %s\n"
    io.write(string.format(fmt, "MODE", show_key("KEY", true), "DESC"))
    for _, r in ipairs(rows) do
      io.write(string.format(fmt, r.mode, show_key(r.lhs), r.desc))
    end
    return
  end
  local fmt = "%-" .. wmode .. "s  %s  %-38s  %s\n"
  io.write(string.format(fmt, "MODE", show_key("KEY", true), "DESC", "WHAT  [WHERE]"))
  for _, r in ipairs(rows) do
    local what = r.rhs or ""
    io.write(string.format(fmt, r.mode, show_key(r.lhs), r.desc, what .. "  [" .. r.loc .. "]"))
  end
end

main()
