-- pokered-plus FIELD MOVE PROMPT (Gen 3 remake style): facing a cuttable
-- tree or the water's edge and pressing A offers CUT/SURF directly, reusing
-- the exact gates/actions the PARTY menu's field-move submenu already uses.
--   luajit tests/engine/field_move_prompt.lua
package.path = "./?.lua;./?/init.lua;" .. package.path
if not _G.love then _G.love = require("tests.love_stub") end

local Data = require("src.core.Data")
if not (Data.maps and Data.maps.PALLET_TOWN) then Data:load() end

local Game = require("src.core.Game")
local Input = require("src.core.Input")
local Renderer = require("src.render.Renderer")
local SaveData = require("src.core.SaveData")
local StateStack = require("src.core.StateStack")
local OW = require("src.world.OverworldController")
local T = require("tests.modkit")

local function mkMon(species, ...)
  local moves = {}
  for _, id in ipairs({ ... }) do
    table.insert(moves, { id = id, pp = 10, ppUp = 0 })
  end
  return { species = species, level = 30, hp = 50, maxHp = 50,
           status = 0, moves = moves, nickname = nil }
end

Game.data = Data
Game.input = Input; Input:init()
Game.renderer = Renderer; Renderer:init()
Game.stack = StateStack
Game.overworld = OW

local function freshOverworld(mapId, x, y, facing)
  StateStack:init()
  while Game.stack:top() do Game.stack:pop() end
  Game.stack:push(OW, mapId, x, y, facing)
  return Game.stack:top()
end

-- ------------------------------------------------------------- SURF: mount
Game.save = SaveData.newGame()
Game.save.party = { mkMon("SQUIRTLE", "SURF") }
Game.save.inventory = { SOULBADGE = true }
local ow = freshOverworld("PALLET_TOWN", 4, 13, "down")
T.eq(ow:useSurfFieldMove(), "ok", "facing Pallet's south shore: mountable")

local surfCalled = false
local realTrySurf = ow.trySurf
ow.trySurf = function(self, fx, fy, onClose)
  surfCalled = true
  T.check(self == ow, "trySurf called on the same overworld instance")
end

T.eq(ow:tryFieldMovePrompt(ow.player:facingCell()), true,
  "tryFieldMovePrompt claims the A-press facing water")
local box = Game.stack:top()
T.check(box ~= nil and box.choice ~= nil,
  "a choice-driven TextBox was pushed")
T.check(box.pages ~= nil, "and it actually has text to show")

box.choice(false)
T.eq(surfCalled, false, "answering NO does not mount")

ow = freshOverworld("PALLET_TOWN", 4, 13, "down") -- re-arm: still facing water
ow.trySurf = function(self, fx, fy, onClose) surfCalled = true end
ow:tryFieldMovePrompt(ow.player:facingCell())
Game.stack:top().choice(true)
T.eq(surfCalled, true, "answering YES calls trySurf")
ow.trySurf = realTrySurf

-- --------------------------------------------------------- SURF: dismount
-- same water/land seam parity_cinnabar_east_surf.lua proved: surfing on
-- Route 20's west edge (0,8), facing left, dismounts onto Cinnabar's coast.
ow = freshOverworld("ROUTE_20", 0, 8, "left")
ow.player.surfing = true
local dismountCalled = false
ow.stopSurfing = function(self, onClose) dismountCalled = true end
T.eq(ow:useSurfFieldMove(), "dismount", "surfing + facing the Cinnabar coast: dismount")
T.eq(ow:tryFieldMovePrompt(ow.player:facingCell()), true,
  "tryFieldMovePrompt claims the A-press for a dismount too")
Game.stack:top().choice(true)
T.check(dismountCalled, "answering YES calls stopSurfing")

-- ----------------------------------------------------- silent refusals
-- no SURF-knowing mon at all: no prompt, no crash, no badge nag
Game.save.party = { mkMon("SQUIRTLE", "TACKLE") }
ow = freshOverworld("PALLET_TOWN", 4, 13, "down")
T.eq(ow:useSurfFieldMove(), "no_badge", "party has no SURF: no_badge")
T.eq(ow:tryFieldMovePrompt(ow.player:facingCell()), false,
  "no SURF mon: the A-press is not claimed (falls through silently)")

-- facing plain land: nothing to offer
Game.save.party = { mkMon("SQUIRTLE", "SURF") }
ow = freshOverworld("PALLET_TOWN", 4, 13, "up")
T.eq(ow:useSurfFieldMove(), "no_water", "facing north (land): no_water")
T.eq(ow:tryFieldMovePrompt(ow.player:facingCell()), false,
  "facing land: the A-press is not claimed")

-- -------------------------------------------------------------------- CUT
-- Real cuttable-tree coordinates aren't needed to prove the wiring: stub
-- the same gate useSurfFieldMove/useCutFieldMove already expose (and that
-- PartyMenu's own CUT action reads) and check tryFieldMovePrompt reaches
-- tryCut through it, exactly as it does for SURF above.
ow = freshOverworld("PALLET_TOWN", 4, 13, "up") -- facing land: SURF says no_water
ow.useCutFieldMove = function(self) return "ok" end
local cutCalled = false
ow.tryCut = function(self, fx, fy) cutCalled = true end
T.eq(ow:tryFieldMovePrompt(ow.player:facingCell()), true,
  "tryFieldMovePrompt claims the A-press for a cuttable tree")
Game.stack:top().choice(true)
T.check(cutCalled, "answering YES calls tryCut")

cutCalled = false
ow = freshOverworld("PALLET_TOWN", 4, 13, "up")
ow.useCutFieldMove = function(self) return "ok" end
ow.tryCut = function(self, fx, fy) cutCalled = true end
ow:tryFieldMovePrompt(ow.player:facingCell())
Game.stack:top().choice(false)
T.eq(cutCalled, false, "answering NO does not cut")

-- ------------------------------------------------------------- the option
Game.save.options.fieldMovePrompt = false
ow = freshOverworld("PALLET_TOWN", 4, 13, "down")
T.eq(ow:useSurfFieldMove(), "ok", "still mountable...")
T.eq(ow:tryFieldMovePrompt(ow.player:facingCell()), false,
  "...but OPTIONS -> FIELD MOVE PROMPT = OFF suppresses the hook entirely")
Game.save.options.fieldMovePrompt = true

T.finish("field move prompt")
