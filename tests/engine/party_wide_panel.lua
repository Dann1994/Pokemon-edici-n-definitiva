-- UI LAYOUT = WIDE side panel (src/ui/PartyMenu.lua:drawPanel): the party
-- list grows a condensed stat/type panel in the extra width a wide window
-- buys, own design (not a reproduction of SummaryMenu or any Gen 1+ status
-- screen). Off unless UI LAYOUT = WIDE, and off again when this menu was
-- opened DURING a wide battle -- it stays inside that battle's own 304px
-- surface, centred at classic coordinates, where PANEL_X=160 would not
-- land on the menu's actual content.
--   luajit tests/engine/party_wide_panel.lua
package.path = "./?.lua;./?/init.lua;" .. package.path
if not _G.love then _G.love = require("tests.love_stub") end

local Data = require("src.core.Data")
if not (Data.maps and Data.maps.PALLET_TOWN) then Data:load() end

local Pokemon = require("src.pokemon.Pokemon")
local PartyMenu = require("src.ui.PartyMenu")
local WideBattle = require("src.battle.WideBattle")
local T = require("tests.modkit")

local function newGame(uiLayout)
  local stack = { states = {} }
  function stack:push(s) table.insert(self.states, s); return s end
  function stack:pop() table.remove(self.states) end
  function stack:top() return self.states[#self.states] end
  return {
    data = Data,
    save = { party = {}, options = { uiLayout = uiLayout },
             player = { name = "RED" }, inventory = {}, flags = {} },
    stack = stack,
    input = { queue = {}, wasPressed = function() return false end,
              isDown = function() return false end },
  }
end

-- ------------------------------------------------------------- uiSize gate
local cgame = newGame("centered")
cgame.save.party = { Pokemon.new(Data, "PIKACHU", 10) }
local cpm = PartyMenu.new(cgame, {})
local cw, ch = cpm:uiSize()
T.eq(cw, 160, "UI LAYOUT = CENTERED keeps the classic surface width")
T.eq(ch, 144, "...and the classic height")
T.eq(cpm:wantsPanel(), false, "...so it never wants the panel")

-- GYARADOS: its front sprite is well over 64px tall, exercising drawPanel's
-- scale-down path (see panelSpriteRect's ph > 64 clamp).
local wgame = newGame("wide")
wgame.save.party = { Pokemon.new(Data, "GYARADOS", 30) }
local wpm = PartyMenu.new(wgame, {})
local ww, wh = wpm:uiSize()
local bw, bh = WideBattle.dims()
T.eq(ww, bw, "UI LAYOUT = WIDE matches the wide battle surface's width")
T.eq(wh, bh, "...and its height")
T.check(ww >= 304, "...which is at least the classic wide baseline (304px)")
T.check(wpm:wantsPanel(), "and this menu wants the panel drawn")

-- --------------------------------------------------- inside a wide battle
local battleStub = { isWideBattleLayout = function() return true end }
wgame.stack:push(battleStub)
wgame.stack:push(wpm)
T.eq(wpm:wantsPanel(), false,
     "a party menu opened over a wide battle stays inside ITS surface")
wgame.stack:pop()
wgame.stack:pop()
T.check(wpm:wantsPanel(),
        "...and wants it again once the battle is gone from the stack")

-- --------------------------------------------------------------- drawing
-- love.graphics calls no-op under the headless stub; this only proves the
-- new draw path never errors, across the shapes it can meet.
local function checkDraws(g, label)
  local p = PartyMenu.new(g, {})
  local ok, err = pcall(function() p:draw() end)
  T.check(ok, label .. " draws without error"
    .. (ok and "" or (": " .. tostring(err))))
end

checkDraws(wgame, "GYARADOS party panel (oversized sprite)")

local emptyGame = newGame("wide")
checkDraws(emptyGame, "an empty party (drawPanel's mon == nil early-out)")

local dualGame = newGame("wide")
dualGame.save.party = { Pokemon.new(Data, "CHARIZARD", 36) } -- two types
checkDraws(dualGame, "a dual-typed mon (TYPE1 + TYPE2 column)")

-- ----------------------------------------------------------------- zones
-- sgbPalettes must stay a well-formed zone list (or nil) with the panel
-- active, whether or not the current mon's sprite is true-color art.
local zwide = wpm:sgbPalettes(wgame)
T.check(zwide == nil or type(zwide) == "table",
        "sgbPalettes stays well-formed with the panel active")

T.finish("party wide panel")
