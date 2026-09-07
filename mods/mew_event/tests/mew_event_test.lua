-- Standalone: luajit mods/mew_event/tests/mew_event_test.lua
package.path = "./?.lua;./?/init.lua;" .. package.path
if not _G.love then _G.love = require("tests.love_stub") end

local T = require("tests.modkit")
local Data = require("src.core.Data")
Data:load()

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
T.check(Data.commands["mew_event:flee"] ~= nil, "mew_event:flee verb")
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

run.release()
T.finish("mew_event")
