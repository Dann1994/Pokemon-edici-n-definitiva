-- UI LAYOUT = WIDE side panel (src/ui/SummaryMenu.lua:drawMovesPanel): the
-- STATS screen grows a moves+PP panel in the extra width a wide window
-- buys, shown on EITHER classic page so a player never has to flip to
-- page 2 just to check PP. Own design; content mirrors page 2's own move
-- list, just repositioned. Off unless UI LAYOUT = WIDE, and off again when
-- this menu was opened DURING a wide battle -- same gate as
-- PartyMenu.lua's own panel (src/ui/WidePanel.lua, shared by both).
--   luajit tests/engine/summary_wide_panel.lua
package.path = "./?.lua;./?/init.lua;" .. package.path
if not _G.love then _G.love = require("tests.love_stub") end

local Data = require("src.core.Data")
if not (Data.maps and Data.maps.PALLET_TOWN) then Data:load() end

local Pokemon = require("src.pokemon.Pokemon")
local SummaryMenu = require("src.ui.SummaryMenu")
local WideBattle = require("src.battle.WideBattle")
local T = require("tests.modkit")

local function newGame(uiLayout)
  local stack = { states = {} }
  function stack:push(s) table.insert(self.states, s); return s end
  function stack:pop() table.remove(self.states) end
  function stack:top() return self.states[#self.states] end
  return {
    data = Data,
    save = { options = { uiLayout = uiLayout }, player = { name = "RED" } },
    stack = stack,
    input = { queue = {}, wasPressed = function() return false end,
              isDown = function() return false end },
  }
end

-- ------------------------------------------------------------- uiSize gate
local cgame = newGame("centered")
local cmon = Pokemon.new(Data, "PIKACHU", 10)
local csm = SummaryMenu.new(cgame, cmon)
local cw, ch = csm:uiSize()
T.eq(cw, 160, "UI LAYOUT = CENTERED keeps the classic surface width")
T.eq(ch, 144, "...and the classic height")

local WidePanel = require("src.ui.WidePanel")
T.eq(WidePanel.wants(cgame), false, "...so it never wants the panel")

local wgame = newGame("wide")
local wmon = Pokemon.new(Data, "GYARADOS", 30)
local wsm = SummaryMenu.new(wgame, wmon)
local ww, wh = wsm:uiSize()
local bw, bh = WideBattle.dims()
T.eq(ww, bw, "UI LAYOUT = WIDE matches the wide battle surface's width")
T.eq(wh, bh, "...and its height")
T.check(WidePanel.wants(wgame), "and this screen wants the panel drawn")

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
-- new draw path never errors, on both pages, across a few move-list shapes.
local function checkDraws(mon, label)
  local sm = SummaryMenu.new(wgame, mon)
  sm.whiteHold = 0 -- skip the intro flash hold so draw reaches the panel
  for _, page in ipairs({ 1, 2 }) do
    sm.page = page
    local ok, err = pcall(function() sm:draw() end)
    T.check(ok, label .. " page " .. page .. " draws without error"
      .. (ok and "" or (": " .. tostring(err))))
  end
end

checkDraws(wmon, "GYARADOS (a full 4-move set)")

local fewMoves = Pokemon.new(Data, "PIDGEY", 5) -- likely under 4 moves this low
checkDraws(fewMoves, "a low-level mon (drawMovesPanel's `if mv` blank rows)")

-- ----------------------------------------------------------------- zones
-- sgbPalettes must stay a well-formed zone list (or nil) with the panel
-- active, and its rows shift by offY the same way draw()'s translate does.
local zwide = wsm:sgbPalettes(wgame)
T.check(zwide == nil or type(zwide) == "table",
        "sgbPalettes stays well-formed with the panel active")
if zwide then
  local offY = WidePanel.offY(wgame)
  for _, z in ipairs(zwide) do
    T.check(z.y >= offY, "every zone's y already includes the offY shift")
  end
end

T.finish("summary wide panel")
