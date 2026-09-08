-- Standalone: luajit mods/mew_event/tests/mew_event_test.lua
package.path = "./?.lua;./?/init.lua;" .. package.path
if not _G.love then _G.love = require("tests.love_stub") end

local T = require("tests.modkit")
local Data = require("src.core.Data")
Data:load()
require("data.scripts.init")   -- attach the engine's base map scripts

local run = T.sdk.loadMods({ "mods/es_es", "mods/mew_event" }, { data = Data })
T.eq(#run.errors, 0, "mew_event loads clean (" .. tostring(run.errors[1]) .. ")")
T.eq(run.mods.mew_event and run.mods.mew_event.state, "loaded", "reached loaded state")

-- Stage 1: the three new hidden objects land on Mansion 3F
local objs = Data.maps.POKEMON_MANSION_3F.objects
T.eq(#objs, 8, "Mansion 3F: 5 vanilla + 3 event objects")
local byName = {}
for _, o in ipairs(objs) do byName[o.name] = o end
for _, n in ipairs({ "MEW_EVENT_SCIENTIST", "MEW_EVENT_PAPERS_B", "MEW_EVENT_PAPERS_C" }) do
  T.check(byName[n] ~= nil and byName[n].hidden == true, n .. " added, hidden")
end

-- the event objects sit on walkable cells the player can face
local MapLoader = require("src.world.MapLoader")
local m = MapLoader.load(Data, "POKEMON_MANSION_3F")
for _, n in ipairs({ "MEW_EVENT_SCIENTIST", "MEW_EVENT_PAPERS_B", "MEW_EVENT_PAPERS_C" }) do
  local o = byName[n]
  T.check(m:isWalkableCell(o.x, o.y), n .. " on a walkable cell")
  T.check(m:isWalkableCell(o.x, o.y + 1) or m:isWalkableCell(o.x, o.y - 1)
    or m:isWalkableCell(o.x - 1, o.y) or m:isWalkableCell(o.x + 1, o.y),
    n .. " has a cell to face it from")
end

-- verbs + script registered
T.check(Data.commands["mew_event:begin"] ~= nil, "mew_event:begin verb")
T.check(Data.commands["mew_event:vanish"] ~= nil, "mew_event:vanish verb")
T.check(Data.commands["mew_event:read_doc"] ~= nil, "mew_event:read_doc verb")
T.check(Data.commands["mew_event:stage_a"] ~= nil, "mew_event:stage_a verb")
T.check(Data.map_scripts.POKEMON_MANSION_3F ~= nil, "3F map script")

-- the document text is in the mod, not empty
local docs = assert(loadstring(assert(io.open("mods/mew_event/data/documents.lua")):read("*a")))()
T.eq(#docs, 6, "six documents")
for i = 1, 6 do
  T.check(type(docs[i].text) == "string" and #docs[i].text > 40, "doc " .. i .. " has text")
end

-- stage_a verb: false on a fresh save, true after the gate
local function ctx(save) return { save = save, lastCheck = nil } end
local fresh = { flags = {}, pokedex = { owned = {} }, party = {} }
Data.commands["mew_event:stage_a"].fn(ctx(fresh))
-- (the verb writes ctx.lastCheck; call again capturing it)
do
  local c = ctx(fresh)
  Data.commands["mew_event:stage_a"].fn(c)
  T.eq(c.lastCheck, false, "stage_a: false on a fresh save")
end
do
  local gated = {
    flags = { EVENT_BEAT_CHAMPION_RIVAL = true },
    pokedex = { owned = { MEWTWO = true } },
    party = { { species = "MEWTWO" } },
  }
  local c = ctx(gated)
  Data.commands["mew_event:stage_a"].fn(c)
  T.eq(c.lastCheck, true, "stage_a: true after league + Mewtwo caught + in party")
end

-- Stage 2: the MAPA VIEJO key item + Fuji's overridden conversation
do
  local def = Data.items.MAPA_VIEJO
  T.check(def ~= nil and def.keyItem == true and def.tossable == false,
    "MAPA_VIEJO registered as a non-tossable key item")
  local fuji = Data.map_scripts.MR_FUJIS_HOUSE
  T.check(fuji ~= nil, "MR_FUJIS_HOUSE map script registered")
  local talk = require("src.script.MapScripts").get("MR_FUJIS_HOUSE").talk
  T.check(talk.TEXT_MRFUJISHOUSE_MR_FUJI ~= nil, "Fuji talk override present")
  T.check(require("src.script.MapScripts").baseTalk(
    "MR_FUJIS_HOUSE", "TEXT_MRFUJISHOUSE_MR_FUJI") ~= nil,
    "vanilla Fuji handler still reachable behind the override")
end

-- Stage 3-5: the sailor override, the island map, sign and statue
do
  local verm = require("src.script.MapScripts").get("VERMILION_CITY").talk
  T.check(verm.TEXT_VERMILIONCITY_SAILOR1 ~= nil, "Vermilion sailor talk override present")
  T.check(require("src.script.MapScripts").baseTalk(
    "VERMILION_CITY", "TEXT_VERMILIONCITY_SAILOR1") ~= nil,
    "vanilla sailor handler still reachable behind the override")

  local isla = Data.maps.ISLA_SUPREMA
  T.check(isla ~= nil, "ISLA_SUPREMA registered as a map")
  T.eq(isla.tileset, "OVERWORLD", "ISLA_SUPREMA uses the OVERWORLD tileset")

  local m = require("src.world.MapLoader").load(Data, "ISLA_SUPREMA")
  -- the dock (spawn 6,24 and the sailor at 7,24), the path north, and the
  -- statue cell (6,3) are all walkable; the tree border is not
  for _, c in ipairs({ { 6, 24 }, { 7, 24 }, { 6, 18 }, { 6, 12 }, { 6, 4 }, { 6, 3 } }) do
    T.check(m:isWalkableCell(c[1], c[2]), ("island cell %d,%d walkable"):format(c[1], c[2]))
  end
  T.check(not m:isWalkableCell(0, 12), "island tree border is solid")

  local islaTalk = require("src.script.MapScripts").get("ISLA_SUPREMA").talk
  for _, k in ipairs({ "TEXT_ISLA_SUPREMA_SAILOR", "TEXT_ISLA_SUPREMA_SIGN",
                       "TEXT_ISLA_SUPREMA_STATUE" }) do
    T.check(islaTalk[k] ~= nil, k .. " handler present")
  end
  for _, v in ipairs({ "mew_event:sail_to_isla", "mew_event:sail_home",
                       "mew_event:mew_battle", "mew_event:base_sailor" }) do
    T.check(Data.commands[v] ~= nil, v .. " verb registered")
  end
end

run.release()
T.finish("mew_event")
