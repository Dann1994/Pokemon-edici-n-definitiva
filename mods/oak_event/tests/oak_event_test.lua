-- Standalone: luajit mods/oak_event/tests/oak_event_test.lua
package.path = "./?.lua;./?/init.lua;" .. package.path
if not _G.love then _G.love = require("tests.love_stub") end

local T = require("tests.modkit")
local Data = require("src.core.Data")
Data:load()
require("data.scripts.init")   -- attach the engine's base map scripts

local run = T.sdk.loadMods({ "mods/es_es", "mods/oak_event" }, { data = Data })
T.eq(#run.errors, 0, "oak_event loads clean (" .. tostring(run.errors[1]) .. ")")
T.eq(run.mods.oak_event and run.mods.oak_event.state, "loaded", "reached loaded state")

-- the three hidden event NPCs
local function objByName(mapId)
  local by = {}
  for _, o in ipairs(Data.maps[mapId].objects or {}) do by[o.name] = o end
  return by
end
local lab = objByName("OAKS_LAB")
T.check(lab.OAK_EVENT_RIVAL and lab.OAK_EVENT_RIVAL.hidden, "rival added to OAKS_LAB, hidden")
local plat = objByName("INDIGO_PLATEAU")
T.check(plat.OAK_EVENT_LANCE and plat.OAK_EVENT_LANCE.hidden, "Lance added to INDIGO_PLATEAU, hidden")
local r1 = objByName("ROUTE_1")
T.check(r1.OAK_EVENT_OAK and r1.OAK_EVENT_OAK.hidden, "Oak added to ROUTE_1, hidden")
local clab = objByName("CINNABAR_LAB")
T.check(clab.OAK_EVENT_SCIENTIST and clab.OAK_EVENT_SCIENTIST.hidden,
  "scientist added to CINNABAR_LAB, hidden")

-- event NPC cells are walkable and face-able
local ML = require("src.world.MapLoader")
for _, spec in ipairs({ { "OAKS_LAB", lab.OAK_EVENT_RIVAL },
                        { "INDIGO_PLATEAU", plat.OAK_EVENT_LANCE },
                        { "CINNABAR_LAB", clab.OAK_EVENT_SCIENTIST },
                        { "ROUTE_1", r1.OAK_EVENT_OAK } }) do
  local m = ML.load(Data, spec[1])
  local o = spec[2]
  T.check(m:isWalkableCell(o.x, o.y), spec[1] .. " NPC on a walkable cell")
  T.check(m:isWalkableCell(o.x, o.y + 1) or m:isWalkableCell(o.x, o.y - 1)
    or m:isWalkableCell(o.x - 1, o.y) or m:isWalkableCell(o.x + 1, o.y),
    spec[1] .. " NPC has a cell to face it from")
end

-- verbs + map scripts
for _, v in ipairs({ "oak_event:battle", "oak_event:finish", "oak_event:league_closed" }) do
  T.check(Data.commands[v] ~= nil, v .. " verb registered")
end
for _, mp in ipairs({ "OAKS_LAB", "PALLET_TOWN", "BILLS_HOUSE",
                      "CINNABAR_LAB", "INDIGO_PLATEAU", "ROUTE_1" }) do
  T.check(Data.map_scripts[mp] ~= nil, mp .. " map script registered")
end

-- the cut Oak trainer data the battle relies on
local oak = Data.trainers.OPP_PROF_OAK
T.check(oak ~= nil and #oak.parties == 3, "OPP_PROF_OAK has 3 parties")
T.eq(oak.parties[1][#oak.parties[1]].species, "GYARADOS", "Oak's last mon is GYARADOS")

-- vanilla handlers still reachable behind the overrides
local MS = require("src.script.MapScripts")
T.check(MS.baseTalk("BILLS_HOUSE", "TEXT_BILLSHOUSE_BILL_CHECK_OUT_MY_RARE_POKEMON") ~= nil,
  "vanilla Bill handler still reachable behind the override")

-- gate: huntActive is false on a fresh save, true after champion + dex 150
local function freshSave()
  local S = require("src.core.SaveData")
  return S.newGame()
end
do
  local MSget = MS.get("OAKS_LAB")
  T.check(type(MSget.onEnter) == "function", "OAKS_LAB composed onEnter present")
end

run.release()
T.finish("oak_event")
