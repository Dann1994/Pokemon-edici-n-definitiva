-- Widescreen battle layout (OPTION -> BATTLE LAYOUT -> WIDE).
--
-- The battle simulation, timing, animations and rules stay BattleState's;
-- this module only replaces the composition and asks the renderer for a
-- 304x144 native-pixel UI surface while it is up.  Pictures, font pages,
-- border glyphs, species palettes and HP tiles all resolve through the
-- engine, so a COLORS mode or an asset mod still owns the look.
--
-- The extra 144 pixels of width buy a Gen 3-style arrangement: foe status
-- upper left with its picture upper right, the player's picture lower left
-- with their status lower right, a full-width message window, a split
-- prompt/command window, and a 2x2 move menu with an attached PP/type panel.

local Font = require("src.render.Font")
local HudTiles = require("src.render.HudTiles")
local PaletteFX = require("src.render.PaletteFX")
local Runtime = require("src.mods.Runtime")
local Strings = require("src.core.Strings")
local TypeChart = require("src.battle.TypeChart")

local WideBattle = {
  -- minimums / the classic wide surface; the live surface is sized to the
  -- window's aspect by WideBattle.dims so BATTLE SIZE = FILL leaves no bars
  -- and the message strip lands flush on the window bottom.
  WIDTH = 304,
  HEIGHT = 144,
  MIN_WIDTH = 304,   -- the 2x2 move grid + PP/type panel need this many tiles
  MSG_H = 40,        -- the message / command / move strip along the bottom
  MAX_WIDTH = 640,
  -- everything above this line is battlefield; the 40 rows below it are
  -- the message / command / move windows
  FIELD_BOTTOM = 104,
}

-- The live surface size.  Matches the window's aspect: at 16:9 that is a
-- 304-wide surface made taller (more sky) so nothing overflows; a wider
-- window grows the width instead.  Returns width, height, field-bottom (all
-- multiples of 8 where the layout needs it), cached per frame on the battle.
function WideBattle.dims(battle)
  local aspect
  local Playfield = require("src.render.Playfield")
  aspect = Playfield.forceAspect
  if not (type(aspect) == "number" and aspect > 0) then
    if love and love.graphics and love.graphics.getDimensions then
      local w, h = love.graphics.getDimensions()
      if type(w) == "number" and type(h) == "number" and h > 0 then
        aspect = w / h
      end
    end
  end
  if not (type(aspect) == "number" and aspect > 0) then
    aspect = WideBattle.MIN_WIDTH / WideBattle.HEIGHT
  end
  local W, H = WideBattle.MIN_WIDTH, WideBattle.HEIGHT
  local wantW = math.floor(H * aspect / 8 + 0.5) * 8
  if wantW > W then
    -- wide window: grow the width, keep the classic 144 height
    W = math.min(wantW, WideBattle.MAX_WIDTH)
  else
    -- narrower than the classic 304:144 (e.g. 16:9): keep 304 and make the
    -- surface taller so its aspect still matches the window and FILL leaves
    -- no bars.  Rounded to whole tiles and capped so a near-square / portrait
    -- window cannot balloon it.
    H = math.floor(W / aspect / 8 + 0.5) * 8
    H = math.max(WideBattle.HEIGHT, math.min(H, 264))
  end
  return W, H, H - WideBattle.MSG_H
end

-- per-frame cache set by WideBattle.draw; helpers read it so they need only
-- the battle in hand
local function D(battle)
  return battle.wideW or WideBattle.WIDTH,
         battle.wideH or WideBattle.HEIGHT,
         battle.wideFB or WideBattle.FIELD_BOTTOM
end

local function monoMode()
  local m = PaletteFX.mode
  return m == "og" or m == "og_inv" or m == "classic"
      or PaletteFX.forcesRawGrays()
end

local function shownHP(battler)
  return math.max(0, math.floor(battler.shownHP or battler.mon.hp or 0))
end

-- a name truncated to `pixels` with a trailing '.', measured through the
-- font's own advances so a variable-width page still fits
local function fitName(text, pixels)
  local spans = Font.split(text or "")
  local n = Font.spansFitting(spans, pixels)
  if n >= #spans then return text or "" end
  local out = {}
  for i = 1, math.max(0, n - 1) do
    out[#out + 1] = (text or ""):sub(spans[i].from, spans[i].to)
  end
  return table.concat(out) .. "."
end

local function saveScissor()
  if not love.graphics.getScissor then return nil end
  local x, y, w, h = love.graphics.getScissor()
  if x == nil then return false end
  return { x, y, w, h }
end

local function restoreScissor(saved)
  if not love.graphics.setScissor then return end
  if saved and saved ~= false then
    love.graphics.setScissor(saved[1], saved[2], saved[3], saved[4])
  else
    love.graphics.setScissor()
  end
end

-- Draw fn's content translated by (dx, dy) and clipped to a surface rect.
-- The scissor is in canvas space, so it bounds the region itself while the
-- translate moves the classic 160x144 coordinates into it.
local function inRegion(x, y, w, h, dx, dy, fn)
  local g = love.graphics
  local saved = saveScissor()
  g.setScissor(x, y, w, h)
  g.push()
  g.translate(dx, dy)
  fn()
  g.pop()
  restoreScissor(saved)
end

local function levelAt(battle, battler, x, y)
  if battler.shownStatus then
    Font.draw(battle:statusLabel({ status = battler.shownStatus }), x, y)
  else
    HudTiles.tile(0x6E, x, y) -- '<LV>'
    Font.draw(tostring(battler.mon.level), x + 8, y)
  end
end

local function battleIsTopState(battle)
  local stack = battle.game and battle.game.stack
  return not (stack and stack.top) or stack:top() == battle
end

-- engine/menus/party_menu.asm:4
local function coveredByOpaqueState(battle)
  local stack = battle.game and battle.game.stack
  local states = stack and stack.states
  if not states then return false end
  local above = false
  for i = 1, #states do
    if above and states[i] and states[i].isOpaque then return true end
    if states[i] == battle then above = true end
  end
  return false
end

local function anchorHUD(battle, x, y, w, h, anchor)
  if not battle:extendedHUD() or not battleIsTopState(battle) then return end
  local renderer = battle.game and battle.game.renderer
  if not (renderer and renderer.setBattleUIAnchor) then return end
  x = x + (battle.extendedHUDOffsetX or 0)
  y = y + (battle.extendedHUDOffsetY or 0)
  local sw, sh = D(battle)
  local x2 = math.min(sw, x + w)
  local y2 = math.min(sh, y + h)
  x, y = math.max(0, x), math.max(0, y)
  w, h = x2 - x, y2 - y
  if w > 0 and h > 0 then
    renderer:setBattleUIAnchor(x, y, w, h, anchor)
  end
end

-- One side's status box: name and level on the first line, a long HP bar
-- under it, and the numeric HP on the player's box only (the foe's exact
-- HP is never shown, like the original).
local function drawStatusPanel(battle, battler, x, y, player)
  local tx, ty = math.floor(x / 8), math.floor(y / 8)
  local tw, th = player and 15 or 16, player and 5 or 4
  Font.drawBox(tx, ty, tw, th)
  love.graphics.setColor(0, 0, 0, 1)

  local nameWidth = player and 64 or 80
  Font.draw(fitName(battler.name, nameWidth), x + 8, y + 8)
  levelAt(battle, battler, x + tw * 8 - 40, y + 8)

  HudTiles.drawHPBar(battle.data, tx + 1, ty + 2, {
    hp = shownHP(battler),
    stats = battler.mon.stats,
  }, nil, monoMode(), tw - 5, battler.shownPx)

  if player then
    Font.draw(("%3d/%3d"):format(shownHP(battler), battler.mon.stats.hp),
      x + tw * 8 - 64, y + 24)
  end
  anchorHUD(battle, x, y, tw * 8, th * 8, player and "bottom" or "top")
end

-- the party ball rows DrawAllPokeballs puts up with the intro text, moved
-- out to the wide screen's own corners
local function drawIntroBalls(battle)
  if not battle.introBalls then return end
  local w, _, fb = D(battle)
  if battle.enemyParty and
      (battle.kind == "trainer" or battle.kind == "link") then
    battle:drawBallRow(battle.enemyParty, 88, 40, -8)
  end
  battle:drawBallRow(battle.playerParty or battle.game.save.party,
    w - 88, fb - 8, 8)
end

local function drawHUDs(battle, slide)
  -- engine/menus/pokedex.asm:581-582
  if battle.fieldCleared then return end
  local showStatus = battle:statusHUDVisible()
  if showStatus and battle.enemy and not battle.showEnemyTrainer
      and not battle.enemySendingOut and not battle:growInScale(battle.enemy)
      and slide == 0 and not battle.introBalls and not battle.enemy.fainted then
    drawStatusPanel(battle, battle.enemy, 0, 0, false)
  end

  -- No player status panel in a safari / old-man battle: no mon of the
  -- player's is out.  Nothing replaces it either -- the ball count is a menu
  -- item, not a HUD element (DisplayBattleMenu prints wNumSafariBalls inside
  -- the battle menu box, engine/battle/core.asm:2074-2079), so it rides in
  -- drawCommandMenu below like the classic layout's (#540).
  -- RemoveFaintedPlayerMon clears the player HUD (core.asm:1024-1026) (#1721)
  if showStatus and not battle.safari and battle.player and not battle.demo
      and not battle.showPlayerBack and slide == 0
      and not battle.player.fainted then
    local w, _, fb = D(battle)
    -- lower-right, its base flush on the field bottom (just over the message
    -- strip), mirroring the foe panel pinned to the top-left corner
    drawStatusPanel(battle, battle.player, w - 15 * 8, fb - 5 * 8, true)
  end
end

local function drawMessageBox(battle)
  local w, _, fb = D(battle)
  Font.drawBox(0, fb / 8, w / 8, 5)
  love.graphics.setColor(0, 0, 0, 1)
  if battle.scrollPx and battle.scrollPx > 0 then
    battle.scrollPx = battle.scrollPx - 2
    if battle.scrollPx <= 0 then battle.scrollPx = nil end
  end
  local off = battle.scrollPx or 0
  local ys = { fb + 8, fb + 24 }
  for li, line in ipairs(battle.shown or {}) do
    local y = (ys[li] or ys[2]) + off
    for i = 1, #line do
      Font.drawCode(line[i], 8 + (i - 1) * 8, y)
    end
  end
  if (battle.msgWaiting or battle.msgPrompt) and battle.frame % 60 < 30 then
    Font.drawCode(0xEE, w - 16, fb + 28)
  end
end

-- the fixed-width right-hand strip: the 2x2 command grid and the move-detail
-- panel are this wide, the prompt / move-list gets the rest of the window
local CMD_W = 144   -- 18 tiles
local DTL_W = 80    -- 10 tiles

local function drawCommandMenu(battle)
  local w, _, fb = D(battle)
  local mr = fb / 8
  local t1, t2 = fb + 8, fb + 24
  local col = (battle.menuIndex - 1) % 2
  local row = math.floor((battle.menuIndex - 1) / 2)
  if battle.safari then
    Font.drawBox(0, mr, w / 8, 5)
    love.graphics.setColor(0, 0, 0, 1)
    Font.draw(Strings("BALLx"), 16, t1)
    -- wNumSafariBalls immediately after the label, as at hlcoord 7,14
    -- (engine/battle/core.asm:2074-2079) (#540)
    Font.draw(("%2d"):format(battle.safari.balls), 56, t1)
    Font.draw(Strings("BAIT"), w / 2 + 16, t1)
    Font.draw(Strings("THROW ROCK"), 16, t2)
    Font.draw(Strings("RUN"), w / 2 + 16, t2)
    Font.drawCode(0xED, col == 0 and 8 or w / 2 + 8, t1 + row * 16)
    return
  end

  -- the prompt on the left, the 2x2 commands on the right
  local px = w - CMD_W       -- left edge of the command box
  Font.drawBox(0, mr, px / 8, 5)
  Font.drawBox(px / 8, mr, CMD_W / 8, 5)
  love.graphics.setColor(0, 0, 0, 1)
  -- The old-man / PROF.OAK catch demo has no party, so makeOldManDemo parks
  -- the WILD mon in battle.player as a placeholder (BattleState:1209).  The
  -- classic layout's demo branch never names anyone (DisplayBattleMenu,
  -- core.asm:2038-2049, just draws the menu), so naming it here printed
  -- "What will PIKACHU do?" over Oak's scripted throw (#557).  Leave the
  -- prompt side blank and run the same scripted hand the classic does.
  if battle.demo then
    Font.draw(Strings("FIGHT"), px + 16, t1)
    Font.drawCode(0xE1, px + 80, t1); Font.drawCode(0xE2, px + 88, t1)
    Font.draw(Strings("ITEM"), px + 16, t2)
    Font.draw(Strings("RUN"), px + 80, t2)
    -- next to FIGHT for the first 80 frames, then ITEM
    Font.drawCode(0xED, px + 8, (battle.demoTimer or 0) <= 80 and t1 or t2)
    return
  end
  Font.draw(Strings("What will"), 8, t1)
  local who = battle.player and battle.player.name or ""
  Font.draw(fitName(who, px - 48) .. Strings(" do?"), 8, t2)
  Font.draw(Strings("FIGHT"), px + 16, t1)
  Font.drawCode(0xE1, px + 80, t1) -- 'PK'
  Font.drawCode(0xE2, px + 88, t1) -- 'MN'
  Font.draw(Strings("ITEM"), px + 16, t2)
  Font.draw(Strings("RUN"), px + 80, t2)
  Font.drawCode(0xED, col == 0 and px + 8 or px + 72, t1 + row * 16)
end

local function drawMoveDetails(battle, move)
  local w, _, fb = D(battle)
  local dx = w - DTL_W
  Font.drawBox(dx / 8, fb / 8, DTL_W / 8, 5)
  if not move then return end
  local def = battle.data.moves[move.id]
  if not def then return end
  local maxPP = def.pp + (move.ppUps or 0) * math.floor(def.pp / 5)
  love.graphics.setColor(0, 0, 0, 1)
  Font.draw(("PP %2d/%2d"):format(move.pp or 0, maxPP), dx + 8, fb + 8)
  -- battle.data is game.data by reference (BattleState:startBattle sets it
  -- before TypeChart.load(game.data)), so this resolves through the exact
  -- same merged table TypeChart's own cache already has -- a no-op today,
  -- kept only for the same call convention as the pre-battle screens
  -- (SummaryMenu, HallOfFame) that genuinely need the explicit data.
  Font.draw(fitName(TypeChart.displayName(def.type, battle.data), 64),
    dx + 8, fb + 24)
end

-- move-name column x and cursor x for the given grid column, plus the row y
local function moveSlot(battle, col, row)
  local w, _, fb = D(battle)
  local half = math.floor((w - DTL_W) / 2)
  local nameX = col == 0 and 16 or half + 8
  local curX = col == 0 and 8 or half
  return nameX, curX, fb + 8 + row * 16
end

local function drawMoveGrid(battle, moves, selected)
  local w, _, fb = D(battle)
  -- the move list gets everything left of the PP/type panel
  Font.drawBox(0, fb / 8, (w - DTL_W) / 8, 5)
  love.graphics.setColor(0, 0, 0, 1)
  local nameBudget = math.floor((w - DTL_W) / 2) - 24
  for i, move in ipairs(moves or {}) do
    local nx, _, y = moveSlot(battle, (i - 1) % 2, math.floor((i - 1) / 2))
    local def = battle.data.moves[move.id]
    Font.draw(fitName(def and def.name or move.id or "", nameBudget), nx, y)
  end
  local _, cx, cy = moveSlot(battle, (selected - 1) % 2,
    math.floor((selected - 1) / 2))
  Font.drawCode(0xED, cx, cy)
  drawMoveDetails(battle, moves and moves[selected])
end

local function drawMoveMenu(battle)
  drawMoveGrid(battle, battle.player.curMoves, battle.moveIndex)
  -- The filled cursor replaces the hollow swap marker when they share a row
  -- (PlaceMenuCursor's tilemap write, home/window.asm:184-185); drawCode blits
  -- black-on-transparent, so skip the 0xEC instead of stacking glyphs (#814).
  if battle.moveSwapIndex and battle.moveSwapIndex ~= battle.moveIndex then
    local _, cx, cy = moveSlot(battle, (battle.moveSwapIndex - 1) % 2,
      math.floor((battle.moveSwapIndex - 1) / 2))
    Font.drawCode(0xEC, cx, cy)
  end
end

local function drawTextArea(battle)
  if not battle:bottomUIVisible() then return end
  if battle.phase == "messages" and (battle.current or battle.animPlaying) then
    drawMessageBox(battle)
  elseif battle.phase == "menu" then
    drawCommandMenu(battle)
  elseif battle.phase == "moveSelect" then
    drawMoveMenu(battle)
  elseif battle.phase == "mimicSelect" then
    drawMoveGrid(battle, battle.mimicMoves, battle.mimicIndex)
  else
    local w, _, fb = D(battle)
    Font.drawBox(0, fb / 8, w / 8, 5)
  end
  local w, h, fb = D(battle)
  anchorHUD(battle, 0, fb, w, h - fb, "bottom")
end

-- Battle animations are authored in the original 160px coordinate space.
-- Shift each complete OAM frame as one rigid group between the new player
-- and enemy anchors: drawing the whole animation through both side regions
-- would duplicate any tiles overlapping the other side's source range (most
-- visibly the send-out POOF reappearing on the far right).
function WideBattle.animationOffset(sprites, w, fb)
  w = (type(w) == "number" and w) or WideBattle.WIDTH
  fb = (type(fb) == "number" and fb) or WideBattle.FIELD_BOTTOM
  if not sprites or #sprites == 0 then return 0, 0 end
  local minX, maxX = math.huge, -math.huge
  for _, sprite in ipairs(sprites) do
    minX = math.min(minX, sprite.x - 8)
    maxX = math.max(maxX, sprite.x)
  end
  local center = (minX + maxX) / 2
  local t = math.max(0, math.min(1, (center - 40) / 80))
  local px, ex = 20, w - 168        -- the player / enemy region x-translates
  return math.floor(px + (ex - px) * t + 0.5),
         math.floor((fb - 96) * (1 - t) + 0.5)
end

local function currentAnimationSprites(battle)
  if battle.animPlaying and battle.animPlayer then
    local step = battle.animPlayer.steps[battle.animPlayer.stepIndex]
    return step and step.sprites
  end
  if battle.lockedBall and battle.animPlayer then
    return battle.lockedBall
  end
end

local function drawAnimationLayer(battle)
  local sprites = currentAnimationSprites(battle)
  if not sprites or #sprites == 0 then return end
  local w, _, fb = D(battle)
  local dx, dy = WideBattle.animationOffset(sprites, w, fb)
  inRegion(0, 0, w, fb, dx, dy,
    function() battle:drawAnimLayer(false) end)
end

-- The whole window-sized composition for one frame.
function WideBattle.draw(battle)
  local g = love.graphics
  battle.wideW, battle.wideH, battle.wideFB = WideBattle.dims(battle)
  local W, H, FB = battle.wideW, battle.wideH, battle.wideFB
  local renderer = battle.game and battle.game.renderer
  local extendedHUD = battle:extendedHUD() and renderer
                      and renderer.beginBattleHUDPass
                      and renderer.endBattleHUDPass
  -- The field is the display mode's paper.  Under a forced-mono mode the
  -- whole surface is remapped downstream (WideBattle.zones), so the field
  -- goes down as DMG white and comes out of that pass as the mode's paper;
  -- painting the resolved shade there would run it through the remap twice
  -- and land a shade off the letterbox the renderer fills around it.
  if not (extendedHUD and battle:extendedWorldHUD()) then
    if monoMode() then
      g.setColor(1, 1, 1, 1)
    else
      g.setColor(PaletteFX.paperShade(battle.data))
    end
    g.rectangle("fill", 0, 0, W, H)
  end
  -- AskName clears the field the same way the classic layout does
  if battle.blankForAskName or coveredByOpaqueState(battle) then return end

  local fx = battle.fx
  local sx = (fx and fx.shakeX) or 0
  local sy = (fx and fx.shakeY) or 0
  if sx == 0 and sy == 0 and fx and fx.shake and fx.shake > 0 then
    sx = battle.frame % 4 < 2 and 2 or -2
  end
  -- same 2 px/frame silhouette slide the 160px layout uses
  local slide = (battle.introSlide or 0)
                * require("src.core.Timing").BATTLE_SLIDE_PX_PER_FRAME

  -- Each side keeps its original sprite pixels and placement math: the two
  -- 160x144 OAM regions are translated apart and clipped into the wider
  -- battlefield rather than either monster being scaled.  wideRegion tells
  -- drawBattlerPic its own side window is already the clip.  A shake moves
  -- each region's clip with its contents, so a pic pushed toward a region
  -- edge is not sheared off it (a vertical shake used to clip the player's
  -- feet at FIELD_BOTTOM).
  battle.wideRegion = true
  -- player pic: lower-left, its feet on FB (classic feet are at y=96, so the
  -- region translates down by FB-96).  enemy pic: upper-right.
  inRegion(sx, 32 + sy, 160, FB - 32, 20 + sx, (FB - 96) + sy,
    function() battle:drawPicsLayer(slide, 0, 0, "player", true) end)
  inRegion((W - 144) + sx, sy, 144, FB, (W - 168) + sx, sy,
    function() battle:drawPicsLayer(slide, 0, 0, "enemy", true) end)
  battle.wideRegion = nil
  drawIntroBalls(battle)

  -- A battle sets rWY to 0 (engine/battle/core.asm), so the window the
  -- shakes move IS the whole screen: PredefShakeScreenHorizontally,
  -- PredefShakeScreenVertically and AnimationShakeScreenHorizontallySlow
  -- displace the HUDs and the message window along with the pics, exactly as
  -- drawClassic offsets its whole BG canvas.  Shaking only the two pic
  -- regions left the foe gliding sideways across a nailed-down screen on
  -- every applying-attack shake -- TAIL WHIP and every other status move
  -- (#562).  The OAM anim layer stays put, as it does in drawClassic.
  local function shaken(fn)
    if sx == 0 and sy == 0 then return fn() end
    g.push()
    g.translate(sx, sy)
    battle.extendedHUDOffsetX, battle.extendedHUDOffsetY = sx, sy
    fn()
    battle.extendedHUDOffsetX, battle.extendedHUDOffsetY = nil, nil
    g.pop()
  end
  drawAnimationLayer(battle)

  if extendedHUD then
    local previous = renderer:beginBattleHUDPass()
    shaken(function() drawHUDs(battle, slide) end)
    shaken(function() drawTextArea(battle) end)
    if fx and fx.flash and fx.flash > 0 and battle.frame % 4 < 2 then
      g.setColor(1, 1, 1, 0.85)
      g.rectangle("fill", 0, 0, W, H)
    end
    renderer:endBattleHUDPass(previous)
  else
    shaken(function() drawHUDs(battle, slide) end)
    shaken(function() drawTextArea(battle) end)
  end

  if fx and fx.flash and fx.flash > 0 and battle.frame % 4 < 2 then
    g.setColor(1, 1, 1, 0.85)
    g.rectangle("fill", 0, 0, W, H)
  end
  g.setColor(1, 1, 1, 1)
  if Runtime.wantsHook("battle.overlay") then
    Runtime.call("battle.overlay", function() end, battle)
  end
end

-- The palette zones for the wide surface.  The composition already resolves
-- species colors, paper shade and HP-bar colors itself, so the colorized
-- modes take the trueColor opt-out (`colors = false`) over the whole
-- surface; the forced-mono modes still want their whole-screen remap, and
-- get one sized to the wide surface instead of the 160x144 rectangle
-- PaletteFX.ensureZones would invent (which would leave 144 columns raw).
function WideBattle.zones(battle)
  local w, h = WideBattle.WIDTH, WideBattle.HEIGHT
  if battle then w, h = D(battle) end
  if monoMode() then
    -- sendColors runs the mode's own substitution (CLASSIC's pea greens,
    -- the inverted permutation), exactly as it does for ensureZones' zone
    return { PaletteFX.zone(PaletteFX.GRAYS, 0, 0, w / 8 - 1, h / 8 - 1) }
  end
  return { { colors = false, x = 0, y = 0, w = w, h = h } }
end

-- 2x2 move-grid navigation: LEFT/RIGHT cross the row, UP/DOWN the column,
-- and a direction pointing at an empty slot holds the current one.
function WideBattle.moveGridIndex(index, count, direction)
  if count < 1 then return nil end
  local row = math.floor((index - 1) / 2)
  local col = (index - 1) % 2
  if direction == "left" or direction == "right" then
    local other = row * 2 + (1 - col) + 1
    return other <= count and other or index
  end
  local otherRow = 1 - row
  local other = otherRow * 2 + col + 1
  return other <= count and other or index
end

local DIRECTIONS = { "left", "right", "up", "down" }

-- the slot a directional press selects, or nil when none was pressed (the
-- caller then runs its normal list navigation / A / B / SELECT handling)
function WideBattle.navigate(index, count, input)
  for _, key in ipairs(DIRECTIONS) do
    if input:wasPressed(key) then
      return WideBattle.moveGridIndex(index, count, key)
    end
  end
  return nil
end

return WideBattle
