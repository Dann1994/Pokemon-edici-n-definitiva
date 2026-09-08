-- Simulación jugable del evento del Profesor Oak.
--   luajit mods/oak_event/tests/simulate_oak.lua
-- Recorre la cadena de pistas (rival -> Bill -> Isla Canela -> Lance ->
-- Ruta 1), el combate y los créditos, e imprime el guion. Comprueba que
-- el gate de flags avanza y que el mundo vuelve a la normalidad al final.
package.path = "./?.lua;./?/init.lua;" .. package.path
if not _G.love then _G.love = require("tests.love_stub") end

local T = require("tests.modkit")
local Data = require("src.core.Data"); Data:load()
require("data.scripts.init")
local run = T.sdk.loadMods({ "mods/es_es", "mods/oak_event" }, { data = Data })
assert(#run.errors == 0, tostring(run.errors[1]))

local Commands = require("src.script.Commands")
local ScriptRunner = require("src.script.ScriptRunner")
local MapScripts = require("src.script.MapScripts")

-- ---- stubs --------------------------------------------------------
local transcript, toggles, credits, battles = {}, {}, { n = 0 }, {}
Commands.show_text = function(_, text) transcript[#transcript + 1] = tostring(text) end
Commands.face_player = function() end
Commands.give_item = function() error("vanilla give_item path should not run in the event branch") end
local function setToggle(ctx, mapId, name, on)
  toggles[mapId] = toggles[mapId] or {}
  toggles[mapId][name] = on
  ctx.save.objectToggles = ctx.save.objectToggles or {}
  ctx.save.objectToggles[mapId] = ctx.save.objectToggles[mapId] or {}
  ctx.save.objectToggles[mapId][name] = on
end
Commands.show_object = function(ctx, m, n) setToggle(ctx, m, n, true) end
Commands.hide_object = function(ctx, m, n) setToggle(ctx, m, n, false) end
Commands.start_battle = function(ctx, kind, cls, party)
  battles[#battles + 1] = { kind = kind, cls = cls, party = party }
  ctx.lastBattleResult = "win"
  ctx.lastCheck = true
end
Commands.record_hall_of_fame = function() credits.n = credits.n + 1 end

local SaveData = require("src.core.SaveData")
local save = SaveData.newGame()
save.flags.EVENT_BEAT_CHAMPION_RIVAL = true
save.flags.EVENT_GOT_SS_TICKET = true
save.flags.EVENT_CHOSE_SQUIRTLE = true          -- -> Oak fields VENUSAUR (party 2)
for i = 1, 150 do save.pokedex.owned["SP" .. i] = true end

local ow = {
  map = { id = "OAKS_LAB", def = { label = "OAKS_LAB" } },
  player = { cellX = 5, cellY = 5, facing = "up" },
  npcByName = function() return { def = { index = 1 } } end,
  scriptMove = function(self, who, dir, n, cb) if cb then cb() end end,
}
local game = { data = Data, save = save,
               stack = { push = function() end, top = function() end } }
ow.runner = ScriptRunner.new(game, ow)

local function onEnter(mapId)
  ow.map = { id = mapId, def = { label = mapId } }
  local v = MapScripts.get(mapId)
  if v and v.onEnter then v.onEnter(game, ow) end
end
local function talk(mapId, key)
  transcript = {}
  local rows = MapScripts.get(mapId).talk[key]
  assert(rows, key .. " missing on " .. mapId)
  local r = ScriptRunner.new(game, ow)
  r:run(rows, { overworld = ow, npc = { def = {}, facePlayer = function() end } })
  local g = 0
  while r:isRunning() and g < 6000 do g = g + 1; r:update() end
end
local function step(mapId, x, y)
  ow.map = { id = mapId, def = { label = mapId } }
  local v = MapScripts.get(mapId)
  return v.onStep and v.onStep(game, ow, x, y)
end
local function show(h)
  print("--- " .. h .. " ---")
  for _, line in ipairs(transcript) do
    for page in (line .. "\f"):gmatch("(.-)\f") do
      if page ~= "" then print("  " .. page:gsub("\n", " ")) end
    end
  end
  print("")
end
local pass, fails = 0, {}
local function ck(c, m) if c then pass = pass + 1 else fails[#fails + 1] = m end end

print("========================================================")
print("  SIMULACIÓN -- El desafío del Profesor Oak")
print("========================================================\n")

-- 1) laboratorio: Oak ausente, rival dentro
onEnter("OAKS_LAB")
ck(toggles.OAKS_LAB and toggles.OAKS_LAB.OAK_EVENT_RIVAL == true, "el rival aparece en el laboratorio")
ck(toggles.OAKS_LAB.OAKSLAB_OAK1 == false, "OAK no está en el laboratorio")
onEnter("PALLET_TOWN")
ck(toggles.PALLET_TOWN and toggles.PALLET_TOWN.PALLETTOWN_OAK == false, "OAK tampoco está en el pueblo")
talk("OAKS_LAB", "TEXT_OAK_EVENT_RIVAL")
show("El rival, en el laboratorio")
ck(save.flags.MOD_OAK_RIVAL_TOLD == true, "1ª pista -> MOD_OAK_RIVAL_TOLD")

-- 2) Bill
talk("BILLS_HOUSE", "TEXT_BILLSHOUSE_BILL_CHECK_OUT_MY_RARE_POKEMON")
show("Bill, en su casa")
ck(save.flags.MOD_OAK_BILL_TOLD == true, "2ª pista -> MOD_OAK_BILL_TOLD")
ck(#battles == 0, "hablar con Bill no dispara nada raro")

-- 3) científico de Isla Canela
onEnter("CINNABAR_LAB")
ck(toggles.CINNABAR_LAB and toggles.CINNABAR_LAB.OAK_EVENT_SCIENTIST == true,
   "el científico aparece en el laboratorio de Isla Canela")
talk("CINNABAR_LAB", "TEXT_OAK_EVENT_SCIENTIST")
show("Científico del laboratorio de Isla Canela")
ck(save.flags.MOD_OAK_CINNABAR_TOLD == true, "3ª pista -> MOD_OAK_CINNABAR_TOLD")

-- 4) Meseta Añil: Lance y la Liga cerrada
onEnter("INDIGO_PLATEAU")
ck(toggles.INDIGO_PLATEAU and toggles.INDIGO_PLATEAU.OAK_EVENT_LANCE == true, "LANCE aparece en la Meseta")
transcript = {}
local blocked = step("INDIGO_PLATEAU", 10, 5)
ck(blocked == true, "intentar entrar a la Liga te bloquea")
show("Lance bloquea la entrada")
ck((table.concat(transcript, " ")):find("cerrada"), "Lance dice que la LIGA está cerrada")
talk("INDIGO_PLATEAU", "TEXT_OAK_EVENT_LANCE")
show("Lance")
ck(save.flags.MOD_OAK_LANCE_TOLD == true, "4ª pista -> MOD_OAK_LANCE_TOLD")

-- 5) Ruta 1: Oak, la revelación, el combate, los créditos
onEnter("ROUTE_1")
ck(toggles.ROUTE_1 and toggles.ROUTE_1.OAK_EVENT_OAK == true, "OAK aparece en la RUTA 1")
talk("ROUTE_1", "TEXT_OAK_EVENT_OAK")
show("Oak, en la Ruta 1 (extracto)")
ck(#battles == 1 and battles[1].cls == "OPP_PROF_OAK", "combate contra OPP_PROF_OAK")
ck(battles[1].party == 2, "Oak usa el equipo 2 (VENUSAUR, contra Squirtle)")
ck(save.flags.EVENT_BEAT_PROF_OAK == true, "vencerlo -> EVENT_BEAT_PROF_OAK")
ck(credits.n == 1, "se muestran los créditos (record_hall_of_fame)")

-- 6) el mundo vuelve a la normalidad
onEnter("OAKS_LAB"); onEnter("PALLET_TOWN"); onEnter("INDIGO_PLATEAU"); onEnter("ROUTE_1")
ck(toggles.OAKS_LAB.OAK_EVENT_RIVAL == false, "el rival se va del laboratorio")
ck(toggles.OAKS_LAB.OAKSLAB_OAK1 == true, "OAK vuelve al laboratorio")
ck(toggles.PALLET_TOWN.PALLETTOWN_OAK == true, "OAK vuelve al pueblo")
ck(toggles.INDIGO_PLATEAU.OAK_EVENT_LANCE == false, "LANCE se va de la Meseta")
ck(step("INDIGO_PLATEAU", 10, 5) == nil or step("INDIGO_PLATEAU", 10, 5) == false,
   "la Liga vuelve a estar abierta")
ck(toggles.ROUTE_1.OAK_EVENT_OAK == false, "OAK ya no está en la RUTA 1")

print("========================================================")
print(("  %d comprobaciones OK, %d fallos"):format(pass, #fails))
for _, f in ipairs(fails) do print("  FALLO: " .. f) end
print("========================================================")
run.release()
os.exit(#fails == 0 and 0 or 1)
