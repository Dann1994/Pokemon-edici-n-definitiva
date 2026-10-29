-- UI LAYOUT = WIDE: Bill's PC mon lists (BoxMenu.lua's WITHDRAW / DEPOSIT /
-- RELEASE) spend the item box's extra width on a preview of the highlighted
-- row's mon -- sprite + TYPE1/TYPE2 (ListMenu:drawMonPreview, opts.monPreview).
-- The rows themselves, :L level included, stay in their classic columns so
-- the preview gets the whole strip right of column 20. Off outside WIDE,
-- off under a window too narrow for the column, blank on CANCEL, and never
-- reached by an item box that did not ask for it (the shop, the PC items).
--   luajit tests/engine/box_wide_preview.lua

package.path = "./?.lua;./?/init.lua;" .. package.path

local T = require("tests.harness")
local check, eq = T.check, T.eq
love = love or require("tests.love_stub")

local calls = {}
local FontStub = {
  BORDER = { tl = 1, tr = 2, bl = 3, br = 4, h = 5, v = 6 },
  draw = function(text, x, y) calls[#calls + 1] = { "draw", text, x, y } end,
  drawCode = function(code, x, y) calls[#calls + 1] = { "code", code, x, y } end,
  drawBox = function(tx, ty, tw, th) calls[#calls + 1] = { "box", tx, ty, tw, th } end,
  width = function(text) return #tostring(text) * 8 end,
  split = function(text)
    local out = {}
    for i = 1, #tostring(text) do out[i] = { from = i, to = i } end
    return out
  end,
  encode = function() return {} end,
  spansFitting = function(spans, pixels) return math.min(#spans, math.floor(pixels / 8)) end,
  advanceOf = function() return 8 end,
}
package.loaded["src.render.Font"] = FontStub

-- a 56x56 front sprite for any species: only its size and where it lands
-- matter here, not its pixels
local spriteAsks = {}
package.loaded["src.ui.WidePanel"] = {
  spriteImage = function(_, species, opts)
    spriteAsks[#spriteAsks + 1] = { species = species, mon = opts and opts.mon }
    return { getDimensions = function() return 56, 56 end }, false
  end,
}
for _, mod in ipairs({ "src.ui.ListMenu", "src.ui.Theme" }) do
  package.loaded[mod] = nil
end
local ListMenu = require("src.ui.ListMenu")

local images = {}
local realDraw = love.graphics.draw
love.graphics.draw = function(img, x, y, r, sx, sy)
  if type(img) == "table" and img.getDimensions and not img.quad then
    images[#images + 1] = { x = x, y = y, sx = sx }
  end
end

local function found(kind, pred)
  for _, c in ipairs(calls) do
    if c[1] == kind and pred(c) then return c end
  end
  return nil
end

local function fakeRenderer(tiles)
  return {
    HEIGHT = 144,
    wideItemTiles = function() return tiles end,
    beginWideItemPass = function() return "prev-canvas", tiles * 8, 144 end,
    endWideItemPass = function() end,
    setWideItemAnchor = function() end,
  }
end

local DATA = {
  text = {},
  pokemon = {
    PIKACHU = { name = "PIKACHU", types = { "ELECTRIC", "ELECTRIC" } },
    CHARIZARD = { name = "CHARIZARD", types = { "FIRE", "FLYING" } },
  },
  type_chart = { types = {
    ELECTRIC = { name = "ELECTRIC" }, FIRE = { name = "FIRE" },
    FLYING = { name = "FLYING" },
  } },
}

local PIKA = { species = "PIKACHU", level = 12 }
local ZARD = { species = "CHARIZARD", level = 40, nickname = "BLAZE" }

local function newList(opts)
  opts = opts or {}
  local game = {
    data = DATA,
    save = { options = { uiLayout = opts.layout or "wide" } },
    renderer = fakeRenderer(opts.tiles or 30),
    stack = { states = {} },
  }
  local items = {
    { label = "PIKACHU", sub = ":L12", value = 1, mon = PIKA },
    { label = "BLAZE", sub = ":L40", value = 2, mon = ZARD },
    { cancel = true, label = "CANCEL" },
  }
  local list = ListMenu.new(game, nil, items, {
    itemBox = true, monPreview = opts.monPreview ~= false,
  })
  list.index = opts.index or 1
  return list
end

local function reset() calls, images, spriteAsks = {}, {}, {} end

-- ------------------------------------------------------------- wide, mon row

do
  reset()
  newList{ tiles = 30 }:draw()
  check(found("box", function(c)
    return c[2] == 4 and c[3] == 2 and c[4] == 26 and c[5] == 11
  end) ~= nil, "the box itself still widens exactly like phase 2's")
  local lvl = found("draw", function(c) return c[2] == ":L12" end)
  check(lvl ~= nil, "the highlighted row's level still draws")
  if lvl then
    eq(lvl[3], (4 + 16 - 6) * 8,
       "the :L level stays in its classic column, not pushed to the far edge")
  end
  eq(#spriteAsks, 1, "one sprite looked up, for the highlighted row only")
  eq(spriteAsks[1] and spriteAsks[1].species, "PIKACHU", "the highlighted mon's species")
  eq(spriteAsks[1] and spriteAsks[1].mon, PIKA, "with the mon instance (shiny etc.)")
  eq(#images, 1, "and drawn once")
  local img = images[1]
  if img then
    check(img.x >= 160, "the sprite sits right of the classic box (column 20+)")
    check(img.x + 56 * img.sx <= (4 + 26 - 1) * 8,
          "and inside the widened box's own inner border")
    eq(img.y + 56 * img.sx, 64, "bottom-anchored above the type rows")
    check(img.sx <= 1, "never scaled up")
  end
  check(found("draw", function(c) return c[2] == "ELECTRIC" and c[3] >= 160 end) ~= nil,
        "TYPE1 draws in the preview column")
  local electric = 0
  for _, c in ipairs(calls) do
    if c[1] == "draw" and c[2] == "ELECTRIC" then electric = electric + 1 end
  end
  eq(electric, 1, "a single-type mon (types[2] == types[1]) shows its type once")
end

do
  reset()
  newList{ tiles = 30, index = 2 }:draw()
  eq(spriteAsks[1] and spriteAsks[1].species, "CHARIZARD", "moving the cursor follows it")
  check(found("draw", function(c) return c[2] == "FIRE" end) ~= nil, "TYPE1 = FIRE")
  check(found("draw", function(c) return c[2] == "FLYING" end) ~= nil, "TYPE2 = FLYING")
end

-- ------------------------------------------------------------- blank cases

do
  reset()
  newList{ tiles = 30, index = 3 }:draw()
  eq(#spriteAsks, 0, "CANCEL highlighted: no preview")
end

do
  reset()
  newList{ tiles = 27 }:draw() -- 7 tiles past column 20: below the minimum
  eq(#spriteAsks, 0, "a window too narrow for the column: no preview")
  local lvl = found("draw", function(c) return c[2] == ":L12" end)
  if lvl then
    eq(lvl[3], (4 + 23 - 6) * 8, "and the rows keep phase 2's wide geometry")
  end
end

do
  reset()
  newList{ layout = "centered" }:draw()
  eq(#spriteAsks, 0, "UI LAYOUT = CENTERED: no preview")
end

do
  reset()
  newList{ monPreview = false }:draw()
  eq(#spriteAsks, 0, "an item box that never asked for monPreview: untouched")
end

love.graphics.draw = realDraw
T.finish("box wide preview")
