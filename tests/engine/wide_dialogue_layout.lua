-- UI LAYOUT = WIDE: the overworld dialogue box (and the YES/NO that pops over
-- it) is genuinely wider -- its tile width comes from the playfield and it
-- paginates against that -- and endFrame stretches its own scratch layer
-- flush along the window bottom.  Everything else stays where CENTERED puts
-- it.  Off inside a battle (holdsUIAnchors) and off when the window is not
-- wider than the classic 10:9.
--   luajit tests/engine/wide_dialogue_layout.lua

package.path = "./?.lua;./?/init.lua;" .. package.path

local T = require("tests.modkit")
local Renderer = require("src.render.Renderer")
local TextBox = require("src.render.TextBox")

local g = love.graphics
local realDims, realPixelDims = g.getDimensions, g.getPixelDimensions
local function window(w, h)
  g.getDimensions = function() return w, h end
  g.getPixelDimensions = function() return w, h end
end

-- ------------------------------------------------------ wideOverworldTiles

window(640, 576) -- exactly the classic 10:9 at 4x
T.eq(Renderer:wideOverworldTiles(), 20,
  "a 10:9 window keeps the classic 20-tile box (WIDE is a no-op)")

window(1920, 720) -- 2.66:1
T.check(Renderer:wideOverworldTiles() > 20,
  "a wide window widens the box past 20 tiles")
T.check(Renderer:wideOverworldTiles() * 8 <= Renderer.MAX_UI_WIDTH,
  "and never past the canvas cap")

window(5120, 720) -- absurdly wide: clamps at the cap
T.eq(Renderer:wideOverworldTiles() * 8, Renderer.MAX_UI_WIDTH,
  "an ultrawide window clamps at MAX_UI_WIDTH")

window(1920, 720)

-- --------------------------------------------------------- the wantsWide gate

local function fakeGame(opts)
  opts = opts or {}
  local top = opts.top or { isOverworld = true }
  return {
    save = { options = { uiLayout = opts.layout or "wide" } },
    renderer = Renderer,
    stack = {
      states = opts.states or { top },
      top = function() return top end,
    },
  }
end

T.eq(TextBox.wantsWide(fakeGame{}), true,
  "WIDE + a box over the overworld + a wide window: on")
T.eq(TextBox.wantsWide(fakeGame{ layout = "centered" }), false,
  "CENTERED: off")
T.eq(TextBox.wantsWide(fakeGame{ layout = "dynamic" }), false,
  "DYNAMIC: off")
T.eq(TextBox.wantsWide(fakeGame{ top = { isMenu = true } }), false,
  "a box over a plain menu (not the map): off")
T.eq(TextBox.wantsWide(fakeGame{
  states = { { holdsUIAnchors = true }, { isOverworld = true } },
  top = { isOverworld = true },
}), false, "inside a battle (a holdsUIAnchors state on the stack): off")

window(640, 576)
T.eq(TextBox.wantsWide(fakeGame{}), false,
  "a 10:9 window: off even with WIDE selected")
window(1920, 720)

-- ------------------------------------------------------------- the anchor

Renderer.uiAnchors = nil
Renderer.uiAnchorHold = false
Renderer.wideDialogueCanvas = {} -- stand-in; setWideDialogueAnchor only stores it
Renderer:setWideDialogueAnchor(0, 96, 48 * 8, 48)
T.eq(#(Renderer.uiAnchors or {}), 1, "the wide box registers one anchor")
T.eq(Renderer.uiAnchors[1].anchor, "bottomwide", "of the bottomwide kind")
T.eq(Renderer.uiAnchors[1].extract, false,
  "with no extract -- it was never drawn into the 160 canvas")

Renderer.uiAnchors = nil
Renderer.uiAnchorHold = true
Renderer:setWideDialogueAnchor(0, 96, 48 * 8, 48)
T.eq(Renderer.uiAnchors, nil,
  "a held frame (a battle) takes no wide dialogue anchor")

Renderer.uiAnchors, Renderer.uiAnchorHold, Renderer.wideDialogueCanvas =
  nil, false, nil
g.getDimensions, g.getPixelDimensions = realDims, realPixelDims

T.finish("wide dialogue layout")
