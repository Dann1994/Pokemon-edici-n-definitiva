-- UI LAYOUT = WIDE: the bag/shop/PC item box (ListMenu:drawItemBox) widens
-- to the playfield's tile width, its left edge glued to the same spot
-- CENTERED already draws it at (growing rightward only -- several of its
-- hosts, the shop most visibly, keep their OWN menu open behind the list,
-- so re-centering would pull the box out from under it), and BUY-mode rows
-- gain an "already own N" column (real inventory data -- this engine
-- carries no item description text to put there instead, see BACKLOG.md
-- §1.9 phase 2). Gated the same way the wide dialogue box is; off inside a
-- battle, off for BagMenu's own list (it deliberately holds its own
-- anchors -- overlaps the kept-open START menu), off under a window not
-- actually wider than classic.
--   luajit tests/engine/wide_item_box.lua

package.path = "./?.lua;./?/init.lua;" .. package.path

local T = require("tests.harness")
local check, eq = T.check, T.eq
love = love or require("tests.love_stub")

-- required BEFORE the Font stub swap below, so this cached module keeps the
-- real Font (only its own bookkeeping is exercised further down -- see "the
-- real Renderer's anchor")
local Renderer = require("src.render.Renderer")

-- ------------------------------------------------------- wideItemTiles

-- A window WIDE enough that CENTERED's own letterbox leaves a real gap
-- between the viewport's left edge and the classic canvas's (uox > vux):
-- a 16:9 window is exactly what WindowAspect.lua locks the real game into.
-- wideOverworldTiles sizes a box meant to sit flush with the VIEWPORT
-- (dx = vux); reusing that budget for THIS box -- anchored "top", glued to
-- uox instead -- ran it past the window's right edge by exactly that gap,
-- which is the clipping a screenshot caught (#wide-item-box-clip).
do
  local g = love.graphics
  local realDims, realPixelDims = g.getDimensions, g.getPixelDimensions
  g.getDimensions = function() return 1920, 1080 end
  g.getPixelDimensions = function() return 1920, 1080 end

  local overworldTiles = Renderer:wideOverworldTiles()
  local itemTiles = Renderer:wideItemTiles()
  check(overworldTiles > 20, "sanity: this window does widen the dialogue box")
  check(itemTiles < overworldTiles,
    "the item box's own budget is SMALLER -- it starts further right (uox), "
    .. "so it has less room left before the viewport's edge")

  -- the box itself never overflows past the viewport: uox (where it starts)
  -- plus its own width (itemTiles tiles, at the UI scale) must land at or
  -- before vux + vuw (where CENTERED's letterbox mirror-gap begins again)
  local r = Renderer:frameRects()
  local dw = itemTiles * 8 * r.Ux
  check(r.uox + dw <= r.vux + r.vuw + 0.01,
    "so a box anchored at uox with that width fits inside the viewport")

  g.getDimensions, g.getPixelDimensions = realDims, realPixelDims
end

local realFont = package.loaded["src.render.Font"]
local calls = {}
local FontStub
FontStub = {
  BORDER = { tl = 1, tr = 2, bl = 3, br = 4, h = 5, v = 6 },
  draw = function(text, x, y) calls[#calls + 1] = { "draw", text, x, y } end,
  drawCode = function(code, x, y) calls[#calls + 1] = { "code", code, x, y } end,
  drawBox = function(tx, ty, tw, th) calls[#calls + 1] = { "box", tx, ty, tw, th } end,
  width = function(text) return #tostring(text) * 8 end,
  split = function(text)
    local out = {}
    for i = 1, #tostring(text) do out[i] = i end
    return out
  end,
  encode = function() return {} end,
  spansFitting = function(spans) return #spans end,
  advanceOf = function() return 8 end,
}
package.loaded["src.render.Font"] = FontStub
for _, mod in ipairs({ "src.ui.ListMenu", "src.ui.Theme", "src.ui.ShopMenu" }) do
  package.loaded[mod] = nil
end
local ListMenu = require("src.ui.ShopMenu") and require("src.ui.ListMenu")
local ShopMenu = require("src.ui.ShopMenu")

local function found(kind, pred)
  for _, c in ipairs(calls) do
    if c[1] == kind and pred(c) then return c end
  end
  return nil
end

-- a controllable stand-in for src.render.Renderer: only the handful of
-- calls drawItemBox actually reaches
local anchorCalls
local function fakeRenderer(tiles)
  return {
    HEIGHT = 144,
    wideItemTiles = function() return tiles end,
    beginWideItemPass = function(self)
      return "prev-canvas", tiles * 8, 144
    end,
    endWideItemPass = function() end,
    setWideItemAnchor = function(self, x, y, w, h)
      anchorCalls = anchorCalls or {}
      anchorCalls[#anchorCalls + 1] = { x = x, y = y, w = w, h = h }
    end,
  }
end

local function fakeGame(opts)
  opts = opts or {}
  return {
    data = { text = {} },
    save = { options = { uiLayout = opts.layout or "wide" } },
    renderer = opts.renderer,
    stack = { states = opts.states or {} },
  }
end

local ITEMS = {
  { label = "POTION", price = "¥300", owned = 3 },
  { label = "ANTIDOTE", price = "¥100" }, -- owned nil: nothing to show
  { cancel = true, label = "CANCEL" },
}

local function newList(game)
  return ListMenu.new(game, nil, ITEMS, { dialogue = true, itemBox = true })
end

-- --------------------------------------------------------- classic (no-op)

do
  calls, anchorCalls = {}, nil
  local game = fakeGame{ renderer = fakeRenderer(16) } -- == ITEM_BOX.tw: no-op
  newList(game):draw()
  check(found("box", function(c)
    return c[2] == 4 and c[3] == 2 and c[4] == 16 and c[5] == 11
  end) ~= nil, "a 16-tile-wide window keeps the classic box (WIDE is a no-op)")
  eq(anchorCalls, nil, "and never asks the renderer for a wide anchor")
end

do
  calls, anchorCalls = {}, nil
  local game = fakeGame{ layout = "centered", renderer = fakeRenderer(30) }
  newList(game):draw()
  check(found("box", function(c)
    return c[2] == 4 and c[3] == 2 and c[4] == 16 and c[5] == 11
  end) ~= nil, "UI LAYOUT = CENTERED: classic box even under a wide window")
end

do
  calls, anchorCalls = {}, nil
  local game = fakeGame{
    renderer = fakeRenderer(30),
    states = { { holdsUIAnchors = true } }, -- a battle, or BagMenu's own list
  }
  newList(game):draw()
  check(found("box", function(c)
    return c[2] == 4 and c[3] == 2 and c[4] == 16 and c[5] == 11
  end) ~= nil, "a holdsUIAnchors state on the stack: classic box")
end

do
  calls, anchorCalls = {}, nil
  local game = fakeGame{ renderer = nil }
  newList(game):draw()
  check(found("box", function(c)
    return c[2] == 4 and c[3] == 2 and c[4] == 16 and c[5] == 11
  end) ~= nil, "no renderer (a headless UI harness): classic box, no crash")
end

-- ------------------------------------------------------------- wide layout

do
  calls, anchorCalls = {}, nil
  local game = fakeGame{ renderer = fakeRenderer(30) }
  newList(game):draw()
  check(found("box", function(c)
    return c[2] == 4 and c[3] == 2 and c[4] == 26 and c[5] == 11
  end) ~= nil,
    "a 30-tile window: tx stays 4 (classic), tw grows to fill the rest")
  eq(#(anchorCalls or {}), 1, "and registers exactly one wide anchor")
  local a1 = anchorCalls[1]
  eq(a1.x, 0, "anchored so the wide canvas's own pixel 0 lands on the")
  eq(a1.y, 16, "classic letterbox's own origin -- tx=4 keeps its old spot")
  eq(a1.w, 240, "spanning the full wide canvas pixel width (30 tiles)")
  eq(a1.h, 144, "the classic height -- this box never grows taller")

  -- POTION's price ("¥300") still right-aligns off the SAME relative
  -- offset from the box's new (wider) right edge as it does classically
  local price = found("draw", function(c) return c[2] == "¥300" end)
  check(price ~= nil, "the price still draws")
  if price then
    eq(price[3] + FontStub.width("¥300"), (4 + 26 - 3) * 8,
       "right-aligned 3 tiles off the widened box's own right edge")
  end

  -- the owned-count column: POTION has 3, drawn as "×" then "3"
  check(found("draw", function(c) return c[2] == "3" end) ~= nil,
    "POTION's owned count (3) draws in the wide-only column")
  local owned3 = found("draw", function(c) return c[2] == "3" end)
  if owned3 then
    check(owned3[3] < price[3], "the owned column sits left of the price column")
  end
  -- ANTIDOTE has no `owned` field: nothing extra drawn for that row (only
  -- its own name + price -- no stray "×"/count leaking from POTION's row)
  local xGlyphs = 0
  for _, c in ipairs(calls) do
    if c[1] == "draw" and c[2] == "\xc3\x97" then xGlyphs = xGlyphs + 1 end
  end
  eq(xGlyphs, 1, "only the row that actually owns something draws the × glyph")
end

do
  -- classic mode already showed CANCEL is a real row and prices right-align
  -- through the BCD field (mart_list_box_bug1887.lua); this only re-checks
  -- that the SAME box, once widened, does not somehow lose it
  calls, anchorCalls = {}, nil
  local game = fakeGame{ renderer = fakeRenderer(30) }
  newList(game):draw()
  check(found("draw", function(c) return c[2] == "CANCEL" end) ~= nil,
        "CANCEL is still a real row once the box is wide")
end

-- --------------------------------------------------- ShopMenu: owned data

package.loaded["src.ui.ListMenu"] = nil
package.loaded["src.ui.ShopMenu"] = nil
ListMenu = require("src.ui.ListMenu")
ShopMenu = require("src.ui.ShopMenu")

do
  local pressed
  local game = {
    data = {
      text = {},
      items = {
        POKE_BALL = { name = "POKe BALL", price = 200 },
        POTION = { name = "POTION", price = 300 },
      },
    },
    save = { money = 3000, inventory = { POTION = 5 }, bagOrder = {} },
    input = {
      wasPressed = function(_, b) return pressed == b end,
      isDown = function() return false end,
    },
    stack = {
      states = {},
      push = function(self, s) self.states[#self.states + 1] = s end,
      pop = function(self) table.remove(self.states) end,
      top = function(self) return self.states[#self.states] end,
    },
  }
  local menu = ShopMenu.new(game, { "POKE_BALL", "POTION" }, function() end)
  game.stack:push(menu)
  menu.index = 1 -- BUY
  pressed = "a"
  menu:update(1 / 60)
  pressed = nil
  local list = game.stack:top()
  local byId = {}
  for _, it in ipairs(list.items) do
    if it.value then byId[it.value] = it end
  end
  eq(byId.POKE_BALL.owned, nil, "nothing owned yet: no owned field to show")
  eq(byId.POTION.owned, 5, "already-owned stock rides item.owned, real inventory data")
end

-- --------------------------------------------- the real Renderer's anchor

do
  Renderer.uiAnchors = nil
  Renderer.uiAnchorHold = false
  Renderer.wideItemCanvas = {} -- stand-in; setWideItemAnchor only stores it
  Renderer:setWideItemAnchor(0, 16, 240, 144)
  eq(#(Renderer.uiAnchors or {}), 1, "the wide item box registers one anchor")
  eq(Renderer.uiAnchors[1].anchor, "top",
    "of the 'top' kind -- x pinned to the classic letterbox, not re-centred")
  eq(Renderer.uiAnchors[1].extract, false,
    "with no extract -- it was never drawn into the classic canvas")

  Renderer.uiAnchors = nil
  Renderer.uiAnchorHold = true
  Renderer:setWideItemAnchor(0, 16, 240, 144)
  eq(Renderer.uiAnchors, nil, "a held frame (a battle) takes no wide item anchor")

  Renderer.uiAnchors, Renderer.uiAnchorHold, Renderer.wideItemCanvas =
    nil, false, nil
end

package.loaded["src.render.Font"] = realFont
for _, mod in ipairs({ "src.ui.ListMenu", "src.ui.Theme", "src.ui.Menu",
                       "src.ui.ShopMenu", "src.render.TextBox" }) do
  package.loaded[mod] = nil
end
require("src.ui.Screens").invalidate()

T.finish("wide item box")
