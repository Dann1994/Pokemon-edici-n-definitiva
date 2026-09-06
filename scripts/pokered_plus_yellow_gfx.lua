-- pokered-plus: overlay Pokemon Yellow's battle sprites onto the Red cache.
--
-- The engine reads battle pics as PNGs from the per-version cache under the
-- LOVE save directory.  This copies Yellow's front/back Pokemon pics over
-- Red's and fixes the handful of species whose pic changed size between the
-- two games (`frontSize` in the cached pokemon.lua).
--
-- Run after every Red (re)import:
--   luajit scripts/pokered_plus_yellow_gfx.lua
--   luajit scripts/pokered_plus_yellow_gfx.lua --revert   (restore Red pics)
--
-- Colours are separate -- see BACKLOG.md 1.2.

package.path = "./?.lua;./?/init.lua;" .. package.path
local LuaWriter = require("src.import.LuaWriter")

local SEP = package.config:sub(1, 1)
local function join(...) return table.concat({ ... }, SEP) end

local function saveRoot()
  local appdata = os.getenv("APPDATA")                 -- Windows
    or (os.getenv("HOME") and join(os.getenv("HOME"), ".local", "share"))
  assert(appdata, "cannot locate the LOVE save directory")
  return join(appdata, "LOVE", "pokemon-love2d")
end

local function exists(path)
  local f = io.open(path, "rb")
  if f then f:close() return true end
  return false
end

local function copy(src, dst)
  local i = assert(io.open(src, "rb"))
  local data = i:read("*a"); i:close()
  local o = assert(io.open(dst, "wb"))
  o:write(data); o:close()
end

local function listPng(dir)
  -- luajit has no readdir; shell out (works on Windows and POSIX)
  local names, cmd = {}, nil
  if SEP == "\\" then
    cmd = 'dir /b "' .. dir .. '\\*.png"'
  else
    cmd = 'ls -1 "' .. dir .. '"'
  end
  local p = io.popen(cmd)
  if not p then return names end
  for line in p:lines() do
    line = line:gsub("%s+$", "")
    if line:match("%.png$") then names[#names + 1] = line end
  end
  p:close()
  return names
end

local root = saveRoot()
local redA = join(root, "red", "assets", "generated", "battle")
local redBak = join(root, "red", "assets", "generated", "battle_red_backup")
local yelA = join(root, "yellow", "assets", "generated", "battle")
local revert = (arg[1] == "--revert")

assert(exists(join(root, "red", "rom-cache.complete")),
  "Red is not imported yet")
if not revert then
  assert(exists(join(root, "yellow", "rom-cache.complete")),
    "Yellow is not imported yet -- import it in the launcher first")
end

local subdirs = { "front", "back" }
local copied, restored = 0, 0

for _, sub in ipairs(subdirs) do
  local redDir = join(redA, sub)
  local bakDir = join(redBak, sub)
  os.execute((SEP == "\\" and 'mkdir "' .. bakDir .. '" 2>nul')
    or 'mkdir -p "' .. bakDir .. '"')
  for _, name in ipairs(listPng(revert and bakDir or join(yelA, sub))) do
    local redPng = join(redDir, name)
    if revert then
      if exists(join(bakDir, name)) then
        copy(join(bakDir, name), redPng); restored = restored + 1
      end
    else
      -- keep a one-time pristine copy of Red's pic
      if not exists(join(bakDir, name)) and exists(redPng) then
        copy(redPng, join(bakDir, name))
      end
      local src = join(yelA, sub, name)
      if exists(src) then copy(src, redPng); copied = copied + 1 end
    end
  end
end

-- frontSize: bring Red's cached pokemon.lua in step with the pic sizes.
local redMonPath = join(root, "red", "data", "generated", "pokemon.lua")
local yelMonPath = join(root, "yellow", "data", "generated", "pokemon.lua")
local function loadTable(path)
  local chunk = assert(loadfile(path))
  return chunk()
end
if exists(redMonPath) and (revert or exists(yelMonPath)) then
  local red = loadTable(redMonPath)
  local ref = revert and loadTable(join(redBak, "..", "pokemon_red_backup.lua"))
  if revert and not ref then
    -- no backup table: leave frontSize alone on revert
  else
    local yellow = revert and ref or loadTable(yelMonPath)
    if not revert then
      -- stash Red's original table once
      local bakTable = join(redBak, "..", "pokemon_red_backup.lua")
      if not exists(bakTable) then
        local o = assert(io.open(bakTable, "wb"))
        o:write(LuaWriter.encode(red)); o:close()
      end
    end
    local changed = 0
    for id, mon in pairs(red) do
      local other = yellow[id]
      if other and other.frontSize and other.frontSize ~= mon.frontSize then
        mon.frontSize = other.frontSize
        changed = changed + 1
      end
    end
    local o = assert(io.open(redMonPath, "wb"))
    o:write(LuaWriter.encode(red)); o:close()
    print(("frontSize: %d species updated"):format(changed))
  end
end

if revert then
  print(("reverted: %d Red pics restored"):format(restored))
else
  print(("done: %d Yellow pics copied over the Red cache"):format(copied))
  print("relaunch the game to see them.")
end
