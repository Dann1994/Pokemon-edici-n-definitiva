-- Simulación jugable de las Etapas 3-5 (marinero de Carmín, Isla Suprema,
-- el cartel de "F.", la estatua y el encuentro con Mew).
--   luajit mods/mew_event/tests/simulate_stage3.lua
package.path = "./?.lua;./?/init.lua;" .. package.path
if not _G.love then _G.love = require("tests.love_stub") end

local T = require("tests.modkit")
local Data = require("src.core.Data"); Data:load()
require("data.scripts.init")
local run = T.sdk.loadMods({ "mods/es_es", "mods/mew_event" }, { data = Data })
assert(#run.errors == 0, tostring(run.errors[1]))

local Commands = require("src.script.Commands")
local ScriptRunner = require("src.script.ScriptRunner")
local MapScripts = require("src.script.MapScripts")

-- ---- stubs ----------------------------------------------------------
local transcript, warps, battles = {}, {}, {}
Commands.show_text = function(_, text) transcript[#transcript + 1] = tostring(text) end
Commands.face_player = function() end
Commands.play_cry = function() end
Commands.choice = function(ctx) ctx.lastCheck = true end          -- always pick option 1
Commands.warp = function(_, mapId, x, y, f)
  warps[#warps + 1] = { map = mapId, x = x, y = y, facing = f }
end
Commands.start_battle = function(ctx) ctx.lastBattleResult = "win" end
Commands.static_battle = function(ctx, species, level, flag)
  battles[#battles + 1] = { species = species, level = level }
  require("src.script.Flags").set(ctx.save, flag)
end

local SaveData = require("src.core.SaveData")
local save = SaveData.newGame()
for _, f in ipairs({ "EVENT_BEAT_CHAMPION_RIVAL", "MOD_MEW_DISCOVERED",
                     "MOD_MEW_FUJI_MYSTERY", "MOD_MEW_OLD_MAP" }) do
  save.flags[f] = true
end
save.inventory.MAPA_VIEJO = 1

local ow = {
  map = { id = "VERMILION_CITY", def = { label = "VERMILION_CITY" } },
  player = { cellX = 18, cellY = 29, facing = "down" },
  npcByName = function() return { def = { index = 1 } } end,
}
local game = { data = Data, save = save,
               stack = { push = function() end, top = function() end } }
ow.runner = ScriptRunner.new(game, ow)

local function runTalk(mapId, textKey)
  transcript = {}
  local rows = MapScripts.get(mapId).talk[textKey]
  assert(rows, textKey .. " missing on " .. mapId)
  local r = ScriptRunner.new(game, ow)
  r:run(rows, { overworld = ow, npc = { def = {}, facePlayer = function() end } })
  local guard = 0
  while r:isRunning() and guard < 4000 do guard = guard + 1; r:update() end
end

local function show(header)
  print("--- " .. header .. " ---")
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
print("  SIMULACIÓN -- Etapas 3-5: el marinero y la Isla Suprema")
print("========================================================\n")

-- 3) marinero de Carmín con el Mapa Viejo
runTalk("VERMILION_CITY", "TEXT_VERMILIONCITY_SAILOR1")
show("Marinero de Ciudad Carmín")
ck(#warps == 1 and warps[1].map == "ISLA_SUPREMA", "el marinero te lleva a ISLA_SUPREMA")
ck(warps[1].x == 6 and warps[1].y == 24, "apareces en el muelle (6,24)")
ck(save.flags.MOD_MEW_ISLA_UNLOCKED == true, "MOD_MEW_ISLA_UNLOCKED fijado")

-- 4) el cartel de F.
ow.map = { id = "ISLA_SUPREMA", def = { label = "ISLA_SUPREMA" } }
runTalk("ISLA_SUPREMA", "TEXT_ISLA_SUPREMA_SIGN")
show("Cartel junto al bosque")
do
  local joined = table.concat(transcript, " ")
  ck(joined:find("F%.%.ji"), "el cartel está firmado \"F..ji\"")
  ck(joined:find("%.%.%.mbre") and joined:find("me march%.%.%."),
     "el cartel es el diario carcomido de Fuji")
end

-- 5) la estatua: 1ª vez texto, 2ª vez combate
runTalk("ISLA_SUPREMA", "TEXT_ISLA_SUPREMA_STATUE")
show("Estatua (primera vez)")
ck(save.flags.MOD_MEW_STATUE_SEEN == true, "1ª interacción -> MOD_MEW_STATUE_SEEN")
ck(#battles == 0, "la 1ª interacción no inicia combate")

runTalk("ISLA_SUPREMA", "TEXT_ISLA_SUPREMA_STATUE")
show("Estatua (segunda vez)")
ck(#battles == 1 and battles[1].species == "MEW", "2ª interacción -> combate contra MEW")
ck(battles[1].level == 60, "Mew a nivel 60")
ck(save.flags.MOD_MEW_CAPTURED == true, "MOD_MEW_CAPTURED fijado tras el combate")

runTalk("ISLA_SUPREMA", "TEXT_ISLA_SUPREMA_STATUE")
show("Estatua (después del encuentro)")
ck(#battles == 1, "la estatua no vuelve a iniciar combate")

-- volver a Carmín por el marinero de la isla
warps = {}
runTalk("ISLA_SUPREMA", "TEXT_ISLA_SUPREMA_SAILOR")
show("Marinero de la isla")
ck(#warps == 1 and warps[1].map == "VERMILION_CITY", "el marinero de la isla te devuelve a CARMÍN")

-- el mapa quedó registrado
ck(Data.maps.ISLA_SUPREMA ~= nil, "ISLA_SUPREMA registrado como mapa")

print("========================================================")
print(("  %d comprobaciones OK, %d fallos"):format(pass, #fails))
for _, f in ipairs(fails) do print("  FALLO: " .. f) end
print("========================================================")
run.release()
os.exit(#fails == 0 and 0 or 1)
