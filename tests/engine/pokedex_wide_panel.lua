-- UI LAYOUT = WIDE side panel (src/ui/PokedexMenu.lua:drawPreviewPanel):
-- the CONTENTS list grows a sprite/base-stats/type panel in the extra
-- width, previewing the highlighted row. Own design (not a reproduction
-- of DexEntryMenu, the real DATA screen, still one A-press away and
-- unchanged); BASE stats rather than a specific mon's current ones, since
-- a dex row has no mon instance behind it. Blank for a row with nothing
-- seen (item.value nil), same as the list row's own dashed-name fallback.
-- Off unless UI LAYOUT = WIDE, and off again inside a wide battle -- the
-- shared gate src/ui/WidePanel.lua also backs PartyMenu's own panel.
--   luajit tests/engine/pokedex_wide_panel.lua
package.path = "./?.lua;./?/init.lua;" .. package.path
if not _G.love then _G.love = require("tests.love_stub") end

local Data = require("src.core.Data")
if not (Data.maps and Data.maps.PALLET_TOWN) then Data:load() end

local PokedexMenu = require("src.ui.PokedexMenu")
local WideBattle = require("src.battle.WideBattle")
local WidePanel = require("src.ui.WidePanel")
local T = require("tests.modkit")

local function newGame(uiLayout, seenThrough)
  local stack = { states = {} }
  function stack:push(s) table.insert(self.states, s); return s end
  function stack:pop() table.remove(self.states) end
  function stack:top() return self.states[#self.states] end
  -- own every species up to dex number `seenThrough`, so the list (and
  -- therefore the panel) has real rows to work with
  local owned, seen = {}, {}
  for species, def in pairs(Data.pokemon) do
    if def.dex and def.dex <= (seenThrough or 0) then owned[species] = true end
  end
  return {
    data = Data,
    save = { options = { uiLayout = uiLayout }, pokedex = { seen = seen, owned = owned } },
    stack = stack,
    input = { queue = {}, wasPressed = function() return false end,
              isDown = function() return false end },
  }
end

-- ------------------------------------------------------------- uiSize gate
local cgame = newGame("centered", 30)
local cdex = PokedexMenu.new(cgame)
local cw, ch = cdex:uiSize()
T.eq(cw, 160, "UI LAYOUT = CENTERED keeps the classic surface width")
T.eq(ch, 144, "...and the classic height")
T.eq(WidePanel.wants(cgame), false, "...so it never wants the panel")

local wgame = newGame("wide", 30)
local wdex = PokedexMenu.new(wgame)
local ww, wh = wdex:uiSize()
local bw, bh = WideBattle.dims()
T.eq(ww, bw, "UI LAYOUT = WIDE matches the wide battle surface's width")
T.eq(wh, bh, "...and its height")
T.check(WidePanel.wants(wgame), "and this screen wants the panel drawn")
T.check(#wdex.items > 0, "sanity: the list actually has rows to preview")

-- --------------------------------------------------- inside a wide battle
local battleStub = { isWideBattleLayout = function() return true end }
wgame.stack:push(battleStub)
T.eq(WidePanel.wants(wgame), false,
     "opened over a wide battle stays inside ITS surface")
wgame.stack:pop()
T.check(WidePanel.wants(wgame),
        "...and wants it again once the battle is gone from the stack")

-- --------------------------------------------------------------- drawing
-- love.graphics calls no-op under the headless stub; this only proves the
-- new draw path never errors, across the shapes it can meet.
local function checkDraws(dex, label)
  local ok, err = pcall(function() dex:draw() end)
  T.check(ok, label .. " draws without error" .. (ok and "" or (": " .. tostring(err))))
end

checkDraws(wdex, "a dex list with real rows")

-- MAGNEMITE: dual-typed (Electric/Steel with pokered_plus) if that mod's
-- retype ran, single-typed otherwise -- either way this must not error,
-- and it also exercises spriteRect's clamp on a taller-than-64px sprite
-- if one lands in the seen range.
local emptyGame = newGame("wide", 0) -- nothing seen: items is empty
local emptyDex = PokedexMenu.new(emptyGame)
checkDraws(emptyDex, "an empty dex list (drawPreviewPanel's species == nil early-out)")

-- ----------------------------------------------------------------- zones
-- sgbPalettes must stay a well-formed zone list (or nil) with the panel
-- active, whether or not the current row's sprite is true-color art.
local zwide = wdex:sgbPalettes(wgame)
T.check(zwide == nil or type(zwide) == "table",
        "sgbPalettes stays well-formed with the panel active")

T.finish("pokedex wide panel")
