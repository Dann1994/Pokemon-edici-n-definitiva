-- UI LAYOUT = WIDE: shared "this full-screen menu owns its own surface and
-- draws a side panel in the extra width" plumbing, factored out of
-- PartyMenu.lua's own uiSize/wantsPanel/offY (the party menu keeps its own
-- copy rather than being rewritten to call this -- it shipped and is
-- tested; this module is for screens added after it: SummaryMenu's STATS
-- page and PokedexMenu's list, both of which need the exact same three
-- pieces). Every user reads the same 304px baseline WideBattle already
-- establishes, so the extra room looks like the same "extra room" no
-- matter which screen buys it.

local WideBattle = require("src.battle.WideBattle")

local WidePanel = {}

-- Renderer:setUISize asks the top state for its surface before anything
-- draws (see BattleState:uiSize, the same idiom). Off (classic 160x144)
-- unless UI LAYOUT = WIDE is on.
function WidePanel.uiSize(game)
  local Game = require("src.core.Game")
  if not Game.wideUI(game.save) then return 160, 144 end
  return WideBattle.dims()
end

-- The panel only draws when the caller actually owns the wide surface: a
-- screen opened DURING a wide battle stays inside that battle's own 304px
-- surface, centred at classic coordinates (Game:draw's classicOffset
-- branch) instead of consulting uiSize() at all -- a panel positioned off
-- WideBattle.WIDTH would not land where the caller's own content is.
function WidePanel.wants(game)
  local Game = require("src.core.Game")
  if not Game.wideUI(game.save) then return false end
  if Game.wideBattleInStack(game.stack) then return false end
  return true
end

-- Vertical centering offset for the whole classic 144px composition inside
-- the caller's own -- possibly taller -- wide surface: WideBattle.dims
-- grows HEIGHT rather than width for any window narrower than the 304:144
-- baseline (16:9 included), which otherwise leaves everything stuck
-- against the top edge with blank canvas below it. Callers wrap their
-- draw() in a love.graphics.translate(0, offY) and must ALSO hand this
-- same amount to anything that records raw canvas coordinates without
-- travelling through that transform -- a sprite's markTrueColor rect, an
-- SGB zone's tile row -- exactly as PartyMenu's own offY comment explains.
function WidePanel.offY(game)
  if not WidePanel.wants(game) then return 0 end
  local _, h = WidePanel.uiSize(game)
  return math.floor((h - 144) / 2)
end

local spriteImages = {}

-- A species' front sprite, for a panel that previews one. PartyMenu.lua
-- keeps its own near-identical copy rather than being rewritten to call
-- this -- it shipped and is tested first; this is for screens added after
-- it. opts.mon (optional) is the same per-instance context
-- Sprites.path takes everywhere else (a shiny variant, say); a screen
-- with no real mon instance -- the Pokédex list, previewing a species it
-- may not even own -- just omits it.
function WidePanel.spriteImage(game, species, opts)
  opts = opts or {}
  local Sprites = require("src.pokemon.Sprites")
  local path, trueColor = Sprites.path(game.data, species, "front",
    { mon = opts.mon, kind = opts.kind or "summary" })
  if not path then return nil end
  local img = spriteImages[path]
  if img == nil then
    local ok, loaded = pcall(love.graphics.newImage, path)
    img = ok and loaded or false
    spriteImages[path] = img
  end
  if not img then return nil end
  return img, trueColor
end

-- Right-aligned inside a [panelX, panelX+panelW) column, scaled down
-- (never up) so an oversized species (Onix, Gyarados...) cannot run past
-- maxH tall; bottom-anchored at bottomY, clamped to not rise above topY.
function WidePanel.spriteRect(img, panelX, panelW, opts)
  opts = opts or {}
  local maxH = opts.maxH or 64
  local topY = opts.topY or 8
  local bottomY = opts.bottomY or 64
  local iw, ih = img:getDimensions()
  local scale = ih > maxH and maxH / ih or 1
  local pw, ph = iw * scale, ih * scale
  local px = panelX + panelW - pw - 8
  local py = math.max(topY, bottomY - ph)
  return px, py, pw, ph, scale
end

return WidePanel
