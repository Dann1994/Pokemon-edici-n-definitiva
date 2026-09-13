-- Pokémon status screen, laid out like the original's two pages
-- (engine/pokemon/status_screen.asm): page 1 = pic, No., HP bar,
-- STATUS/, the ATTACK/DEFENSE/SPEED/SPECIAL box and TYPE1/TYPE2/
-- IDNo/OT; page 2 = EXP and the moves with PP.  A flips pages, B (or
-- A on page 2) closes.

local Font = require("src.render.Font")
-- status_screen.asm PrintMonType prints the type's DISPLAY name from the
-- TypeNames table, not the constant: species types are stored as pokered
-- constants (RomExtractor:typesById) and PSYCHIC's is "PSYCHIC_TYPE" (so it
-- won't collide with the PSYCHIC move), which would overflow the TYPE field.
-- TypeChart.displayName maps it back to "PSYCHIC", like HallOfFame and the
-- battle move-type box already do (#214).
local TypeChart = require("src.battle.TypeChart")
local LevelDisplay = require("src.ui.LevelDisplay")
local Strings = require("src.core.Strings")
local Stats = require("src.pokemon.Stats")
local Status = require("src.battle.Status")

local WidePanel = require("src.ui.WidePanel")

-- UI LAYOUT = WIDE: a panel in the extra width -- moves+PP on page 1
-- (complementing that page's own stats/type), stats+type on page 2
-- (complementing ITS own moves/EXP) -- own design either way, own
-- coordinates, not a reproduction of the classic page it sits beside.
-- Together the two pages now always show all four pieces (stats, type,
-- moves, EXP) with nothing duplicated; the first version showed the same
-- move list on both pages, which just looked like an odd echo on page 2.
-- Page-flip itself (A/B, page 1 <-> page 2) is completely unchanged.
local PANEL_X = 160
-- same box/column math as PartyMenu.lua's own panel (BOX_X/BOX_W/TYPE_X,
-- see its comment): short stat abbreviations so TYPE1/TYPE2 still has
-- room for a 9-letter Spanish type name (SINIESTRO, ELÉCTRICO).
local BOX_X = PANEL_X + 8
local BOX_W = 48
local TYPE_X = BOX_X + BOX_W + 8

local SummaryMenu = {}
SummaryMenu.__index = SummaryMenu
SummaryMenu.isOpaque = true

-- SGB: SetPal_StatusScreen -- HP-bar palette overall, mon pic zone in
-- the species palette
function SummaryMenu:sgbPalettes(game)
  local P = require("src.render.PaletteFX")
  local mon = self.mon
  if not mon then return P.wholeNamed(game.data, "MEWMON") end
  local bar = P.pal(game.data, P.barPalName(mon.hp, mon.stats.hp))
  if not bar then return nil end
  local zones = { P.whole(bar), P.zone(P.monPal(game.data, mon.species), 1, 0, 7, 6) }
  -- every zone above was built in the classic 0..144 space; shift the
  -- whole list down by the same amount draw()'s translate moves the
  -- pixels (see offY's comment on PartyMenu.lua, the same reasoning)
  local offY = WidePanel.offY(game)
  if offY ~= 0 then
    for _, z in ipairs(zones) do z.y = z.y + offY end
  end
  return zones
end

-- Renderer:setUISize asks the top state for its surface before anything draws
function SummaryMenu:uiSize()
  return WidePanel.uiSize(self.game)
end

function SummaryMenu.new(game, mon)
  -- status_screen.asm:66-76: StatusScreen recalculates the stat block before
  -- it draws anything when the mon came from a box or the daycare ("mon is
  -- in a box or daycare" -> CalcStats), because box_struct carries none.
  -- Bill's PC hands us that mon table directly (src/ui/BoxMenu.lua's STATS
  -- submenu entry), and for a .sav imported through
  -- src/save_convert/GenSave.lua it really does arrive with mon.stats nil,
  -- which crashed the HP bar draw below (#233).  Redundant once
  -- SaveData.validate has run over a loaded save, but this is the site the
  -- original recomputes at, and it also covers a mon handed in by a mod.
  Stats.ensure(game.data.pokemon[mon.species], mon)
  local self = setmetatable({ game = game, mon = mon, page = 1 }, SummaryMenu)
  local Sprites = require("src.pokemon.Sprites")
  local path, trueColor = Sprites.path(game.data, mon.species, "front",
    { mon = mon, kind = "summary" })
  if path then
    local ok, img = pcall(love.graphics.newImage, path)
    self.sprite = ok and img or nil
  end
  self.spriteTrueColor = self.sprite and trueColor or false
  -- engine/pokemon/status_screen.asm:82,168-172
  self.whiteHold = tonumber(require("src.render.Transition").flashFrames(game)) or 0
  if self.whiteHold <= 0 then
    self.whiteHold = 0
    require("src.core.Sound").playCry(game.data, mon.species)
  end
  return self
end

function SummaryMenu:update(dt)
  if self.closing then return end
  if self.whiteHold and self.whiteHold > 0 then
    self.whiteHold = self.whiteHold - 1
    if self.whiteHold == 0 then
      require("src.core.Sound").playCry(self.game.data, self.mon.species)
    end
    return
  end
  local input = self.game.input
  -- both A and B advance the pages (WaitForTextScrollButtonPress)
  if input:wasPressed("a") or input:wasPressed("b") then
    if self.page == 1 then
      self.page = 2
    else
      -- engine/pokemon/status_screen.asm:431, home/pokemon.asm:186
      local Transition = require("src.render.Transition")
      self.closing = true
      self.game.stack:push(Transition.whiteFlash(self.game, nil, function()
        self.game.stack:pop()
      end))
    end
  end
end

-- DrawLineBox (status_screen.asm): a vertical edge down the right,
-- a corner, a horizontal run leftward and the half-arrow ending --
-- drawn from the same HUD tiles the original loads
local function drawLineBox(tx, ty, b, c)
  local HudTiles = require("src.render.HudTiles")
  -- Under the status screen's overlay the vertical is $78 -- DrawLineBox
  -- writes `ld [hl], $78` (status_screen.asm:222), and :90-93 is what puts
  -- hud_2's single bar tile there.  $73 is the <ID> glyph on this screen,
  -- not a line, so the whole box has to come off statusTile (#280).  The
  -- drawn shapes are unchanged: hud_2 tile 0 is the same bar the battle
  -- layout parks at $73.
  for i = 0, b - 1 do HudTiles.statusTile(0x78, tx * 8, (ty + i) * 8) end
  HudTiles.statusTile(0x77, tx * 8, (ty + b) * 8)
  for i = 1, c do HudTiles.statusTile(0x76, (tx - i) * 8, (ty + b) * 8) end
  HudTiles.statusTile(0x6F, (tx - c - 1) * 8, (ty + b) * 8)
end

-- home/pokemon.asm:335-345 PrintLevel: the "<LV>" (":L") tile at (tx,ty)
-- then the level LEFT_ALIGNed after it; at level 100 hl is decremented so
-- the third digit is written back OVER the ":L" tile.  Both status pages
-- print a level this way, and src/ui/PartyMenu.lua models the same rule for
-- its rows. #280
local function printLevel(tx, ty, level)
  local HudTiles = require("src.render.HudTiles")
  local x = tx * 8
  if level < 100 then
    HudTiles.statusTile(0x6E, x, ty * 8)
    x = x + 8
  end
  Font.draw(tostring(level), x, ty * 8)
end

function SummaryMenu:draw()
  local uiw, uih = self:uiSize()
  -- UI LAYOUT = WIDE: this screen's own surface can be TALLER than the
  -- classic 144px (WideBattle.dims grows height instead of width for a
  -- window narrower than the 304:144 baseline, 16:9 included), which
  -- otherwise left the whole classic composition stuck against the top
  -- edge with blank canvas below it -- see PartyMenu.lua's own offY
  -- comment, the same fix.
  local offY = WidePanel.offY(self.game)
  if offY ~= 0 then
    love.graphics.push()
    love.graphics.translate(0, offY)
  end
  love.graphics.setColor(1, 1, 1, 1)
  -- the classic 160x144 field, not the whole (possibly wider) canvas --
  -- the panel below paints its own background
  love.graphics.rectangle("fill", 0, 0, 160, 144)
  local mon = self.mon
  local game = self.game
  local data = game.data
  local def = data.pokemon[mon.species]

  -- shared header: pic (1,0), name (9,1), № + dex number (1,7).  The pic is
  -- MIRRORED -- status_screen.asm:170 draws it through
  -- LoadFlippedFrontSpriteByMonIndex (home/pokemon.asm sets wSpriteFlipped),
  -- the same routine the intro's NIDORINO show-off uses (OakSpeech picFlip:
  -- negative x scale anchored at the pic's right edge). #280
  if self.sprite then
    local pw, ph = self.sprite:getDimensions()
    local py = math.max(0, 56 - ph)
    love.graphics.draw(self.sprite, 8 + pw, py, 0, -1, 1)
    -- a full-color pic has to sit out the SGB monPal recolor, so mark the
    -- rect the mirrored draw covers for the unshaded pass (#430). Like the
    -- zones above, markTrueColor never travels through the translate this
    -- draw() may currently have active, so it needs offY by hand (#637's
    -- reasoning, PartyMenu.lua's drawPanel comment).
    if self.spriteTrueColor then
      require("src.render.PaletteFX").markTrueColor(8, py + offY, pw, ph)
    end
  end
  local HudTiles = require("src.render.HudTiles")
  love.graphics.setColor(0, 0, 0, 1)
  Font.draw(mon.nickname or def.name, 72, 8)
  -- status_screen.asm:109-113 backs hl up from DrawLineBox's end to write
  -- the single-tile '№' at (1,7) and '<DOT>' at (2,7); :143-146 then
  -- PrintNumbers the dex number (LEADING_ZEROES, 3 digits) at (3,7).
  -- Spelling "No." out of three letter tiles pushed every digit a column
  -- right of the original. #280
  HudTiles.statusTile(0x74, 8, 56)  -- №
  Font.drawCode(0xF2, 16, 56)       -- <DOT> (charmap.asm:182)
  Font.draw(("%03d"):format(def.dex or 0), 24, 56)

  if self.page == 1 then
    -- level is page 1 only: StatusScreen2 opens with ClearScreenArea over
    -- (9,2) 5x10 (status_screen.asm:303-305). #280
    if LevelDisplay.visible(mon, "summary", self.game) then -- RFC 0019
      printLevel(14, 2, mon.level)
    end
    drawLineBox(19, 1, 6, 10)
    -- engine/pokemon/status_screen.asm:120-125
    local PaletteFX = require("src.render.PaletteFX")
    local barZoned = PaletteFX.shader() ~= nil
                     and PaletteFX.pal(data, "GREENBAR") ~= nil
    HudTiles.drawHPBar(data, 11, 3, mon, 1, barZoned) -- wHPBarType 1
    Font.draw(("%3d/%3d"):format(mon.hp, mon.stats.hp), 96, 32)
    Font.draw(Strings("STATUS/"), 72, 48)
    Font.draw(Status.hudLabelFor(data.statuses, mon.status) or "OK", 128, 48)

    -- stats box (0,8) 10x10: names rows 9/11/13/15, values indented
    Font.drawBox(0, 8, 10, 10)
    local stats = {
      { "ATTACK", mon.stats.attack }, { "DEFENSE", mon.stats.defense },
      { "SPEED", mon.stats.speed }, { "SPECIAL", mon.stats.special },
    }
    for i, s in ipairs(stats) do
      local y = 72 + (i - 1) * 16
      Font.draw(Strings(s[1]), 8, y)
      Font.draw(("%3d"):format(s[2]), 48, y + 8)
    end

    -- TYPE1/TYPE2/IDNo/OT column (10,9) with values indented (11,10)
    drawLineBox(19, 9, 8, 6)
    Font.draw(Strings("TYPE1/"), 80, 72)
    Font.draw(def.types[1] and TypeChart.displayName(def.types[1], data) or "", 88, 80)
    if def.types[2] then
      Font.draw(Strings("TYPE2/"), 80, 88)
      Font.draw(TypeChart.displayName(def.types[2], data), 88, 96)
    end
    -- TypesIDNoOTText's third row is "<ID>№/" (status_screen.asm:205-210):
    -- two single-tile glyphs and a slash, three columns wide, not the five
    -- letter tiles "IDNo/" this used to spell out. #280
    HudTiles.statusTile(0x73, 80, 104) -- <ID>
    HudTiles.statusTile(0x74, 88, 104) -- №
    Font.draw("/", 96, 104)
    -- the trainer ID is rolled at new game (SaveData.newGame) and
    -- backfilled on load for old saves
    Font.draw(("%05d"):format(mon.otId or game.save.player.id or 0), 96, 112)
    Font.draw(Strings("OT/"), 80, 120)
    Font.draw(mon.ot or game.save.player.name or "RED", 96, 128)
  else
    -- page 2: EXP + the moves with PP (StatusScreen2)
    drawLineBox(19, 1, 6, 10)
    Font.draw(Strings("EXP POINTS"), 72, 24)
    -- PrintNumber at (12,4) with 7 columns: the exp is RIGHT-aligned into
    -- cols 12-18 (status_screen.asm:400-403), not left-aligned from col 12.
    -- #280
    Font.draw(("%7d"):format(mon.exp), 96, 32)
    -- StatusScreen2: "LEVEL UP" at (9,5); next-exp PrintNumber 7 cols at
    -- (7,6); the narrow '<to>' tile at (14,6); PrintLevel at (16,6)
    -- (status_screen.asm:393-403).  The old "%d to L%d" string at x=88
    -- overflowed the DrawLineBox edge.
    Font.draw(Strings("LEVEL UP"), 72, 40)
    local Growth = require("src.pokemon.Growth")
    local nextExp = mon.level < 100
      and (Growth.expForLevel(def.growthRate, mon.level + 1) - mon.exp) or 0
    Font.draw(("%7d"):format(math.max(0, nextExp)), 56, 48)
    if LevelDisplay.visible(mon, "summary", self.game) then -- RFC 0019
      -- the '<to>' arrow is half a sentence without the level it points at,
      -- so the pair is hidden together
      HudTiles.statusTile(0x70, 112, 48) -- '<to>' at (14,6), was missing (#280)
      printLevel(16, 6, math.min(100, mon.level + 1))
    end
    Font.drawBox(0, 8, 20, 10)
    for i = 1, 4 do
      local mv = mon.moves[i]
      local y = 72 + (i - 1) * 16
      if mv then
        local mdef = data.moves[mv.id]
        Font.draw(mdef.name, 16, y)
        Font.draw(Strings("PP"), 88, y + 8)
        local maxPP = mdef.pp + (mv.ppUps or 0) * math.floor(mdef.pp / 5)
        Font.draw(("%2d/%2d"):format(mv.pp, maxPP), 112, y + 8)
      else
        Font.draw("-", 16, y)
        Font.draw("--", 112, y + 8)
      end
    end
  end
  love.graphics.setColor(1, 1, 1, 1)
  if WidePanel.wants(game) then
    if self.page == 1 then self:drawMovesPanel() else self:drawStatsTypePanel() end
  end
  if offY ~= 0 then love.graphics.pop() end
  -- engine/pokemon/status_screen.asm:82 -- the whole (possibly taller)
  -- canvas, drawn AFTER the pop above so offY does not push part of it
  -- past the bottom edge and leave a sliver unflashed at the top
  if self.whiteHold and self.whiteHold > 0 then
    love.graphics.rectangle("fill", 0, 0, uiw, uih)
  end
end

-- UI LAYOUT = WIDE, page 1 only: the 4 moves + PP, same content and row
-- math as page 2's own move list (17 tiles, one narrower than that box's
-- 18 -- see below -- since it starts PANEL_X right rather than at the
-- screen's own left edge).
function SummaryMenu:drawMovesPanel()
  local mon = self.mon
  local game = self.game
  local data = game.data
  love.graphics.setColor(0, 0, 0, 1)
  -- classic page 2's own box is 20 tiles with the PP value ending 8px shy
  -- of its right border (112 + 40 = 152, border at 160). This box is only
  -- 17 tiles -- one narrower than a straight PANEL_W/8=18 would give, so
  -- the SAME value column (PANEL_X+88..+128) keeps that identical 8px
  -- margin against ITS OWN right border at PANEL_X+136, instead of
  -- landing flush on the canvas edge at PANEL_X+144 and reading as
  -- clipped (a screenshot caught exactly that at the original 18-tile width).
  Font.drawBox(PANEL_X / 8, 8, 17, 10)
  for i = 1, 4 do
    local mv = mon.moves[i]
    local y = 72 + (i - 1) * 16
    if mv then
      local mdef = data.moves[mv.id]
      Font.draw(mdef.name, PANEL_X + 16, y)
      Font.draw(Strings("PP"), PANEL_X + 64, y + 8)
      local maxPP = mdef.pp + (mv.ppUps or 0) * math.floor(mdef.pp / 5)
      Font.draw(("%2d/%2d"):format(mv.pp, maxPP), PANEL_X + 88, y + 8)
    else
      Font.draw("-", PANEL_X + 16, y)
      Font.draw("--", PANEL_X + 88, y + 8)
    end
  end
  love.graphics.setColor(1, 1, 1, 1)
end

-- UI LAYOUT = WIDE, page 2 only: the same stats+type page 1 shows in
-- classic position -- short abbreviations (own presentation, matching
-- PartyMenu's own panel) rather than page 1's spelled-out ATTACK/DEFENSE/
-- SPEED/SPECIAL, since this box is narrower to leave TYPE1/TYPE2 enough
-- room (see BOX_X's comment).
function SummaryMenu:drawStatsTypePanel()
  local mon = self.mon
  local game = self.game
  local data = game.data
  local def = data.pokemon[mon.species]
  local TypeChart = require("src.battle.TypeChart")

  love.graphics.setColor(0, 0, 0, 1)
  Font.drawBox(BOX_X / 8, 8, BOX_W / 8, 10)
  local statsY = 72
  local stats = {
    { "ATK", mon.stats.attack }, { "DEF", mon.stats.defense },
    { "SPD", mon.stats.speed }, { "SPA", mon.stats.special },
  }
  for i, s in ipairs(stats) do
    local y = statsY + (i - 1) * 16
    Font.draw(Strings(s[1]), BOX_X + 8, y)
    Font.draw(("%3d"):format(s[2]), BOX_X + 8, y + 8)
  end

  Font.draw(Strings("TYPE1/"), TYPE_X, statsY)
  if def.types[1] then
    Font.draw(TypeChart.displayName(def.types[1], data), TYPE_X, statsY + 8)
  end
  if def.types[2] then
    Font.draw(Strings("TYPE2/"), TYPE_X, statsY + 24)
    Font.draw(TypeChart.displayName(def.types[2], data), TYPE_X, statsY + 32)
  end
  love.graphics.setColor(1, 1, 1, 1)
end

return SummaryMenu
