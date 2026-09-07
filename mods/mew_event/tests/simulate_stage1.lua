-- Simulación jugable de la Etapa 1 (Mansión Pokémon 3F).
--   luajit mods/mew_event/tests/simulate_stage1.lua
-- Imprime, en orden, todo el texto que vería el jugador, y comprueba que
-- el gate de flags avanza. NO es un test de paridad: es una lectura del
-- flujo del evento.
package.path = "./?.lua;./?/init.lua;" .. package.path
if not _G.love then _G.love = require("tests.love_stub") end

local T = require("tests.modkit")
local Data = require("src.core.Data"); Data:load()
local run = T.sdk.loadMods({ "mods/es_es", "mods/mew_event" }, { data = Data })
assert(#run.errors == 0, tostring(run.errors[1]))

local Commands = require("src.script.Commands")
local ScriptRunner = require("src.script.ScriptRunner")
local Flags = require("src.script.Flags")

-- ---- capture text, run scripts synchronously (no TextBox / no yield) ----
local transcript = {}
local function record(text, subs)
  local s = tostring(text)
  if subs then for k, v in pairs(subs) do s = s:gsub("{" .. k .. "[^}]*}", tostring(v)) end end
  transcript[#transcript + 1] = s
end
Commands.show_text = function(_, text, subs) record(text, subs) end
Commands.emote = function() end
Commands.face_player = function() end
Commands.move_npc_to = function() end
Commands.hide_object = function(ctx, mapId, name)
  ctx.save.objectToggles = ctx.save.objectToggles or {}
  ctx.save.objectToggles[mapId] = ctx.save.objectToggles[mapId] or {}
  ctx.save.objectToggles[mapId][name] = false
end
Commands.show_object = function(ctx, mapId, name)
  ctx.save.objectToggles = ctx.save.objectToggles or {}
  ctx.save.objectToggles[mapId] = ctx.save.objectToggles[mapId] or {}
  ctx.save.objectToggles[mapId][name] = true
end

-- ---- a save that has just beaten the League with Mewtwo in the party ----
local Pokemon = require("src.pokemon.Pokemon")
local SaveData = require("src.core.SaveData")
local save = SaveData.newGame()
save.flags.EVENT_BEAT_CHAMPION_RIVAL = true
save.pokedex.owned.MEWTWO = true
save.party = { Pokemon.new(Data, "MEWTWO", 70), Pokemon.new(Data, "PIKACHU", 60) }

local ow = {
  map = { id = "POKEMON_MANSION_3F", def = { label = "POKEMON_MANSION_3F" } },
  npcs = {}, entities = {}, player = { cellX = 6, cellY = 10 },
  npcByName = function() return { def = { index = 6 } } end,
}
local game = { data = Data, save = save, stack = { push = function() end, top = function() end } }
ow.runner = ScriptRunner.new(game, ow)

local function runScript(rows)
  local r = ScriptRunner.new(game, ow)
  r:run(rows, { overworld = ow, npc = { def = {}, facePlayer = function() end } })
  local guard = 0
  while r:isRunning() and guard < 2000 do guard = guard + 1; r:update() end
end

local MapScripts = require("src.script.MapScripts")
local MS = MapScripts.get("POKEMON_MANSION_3F")
local pass, fails = 0, {}
local function ck(cond, msg)
  if cond then pass = pass + 1 else fails[#fails + 1] = msg end
end

print("========================================================")
print("  SIMULACIÓN -- Etapa 1: Mansión Pokémon, 3er piso")
print("========================================================\n")

-- 1) entrar al piso con el gate cumplido
MS.onEnter(game, ow)
ck((save.objectToggles or {}).POKEMON_MANSION_3F
   and save.objectToggles.POKEMON_MANSION_3F.MEW_EVENT_SCIENTIST == true,
   "el científico aparece al entrar")
print("[Entras al 3er piso. Un científico está junto a las mesas.]\n")

-- 2) cruzar hacia la sala de los diarios -> onStep dispara al científico
transcript = {}
local consumed = MS.onStep(game, ow, 6, 10)
ck(consumed == true, "el onStep dispara la escena del científico")
print("--- El científico se acerca ---")
for _, line in ipairs(transcript) do
  for page in (line .. "\f"):gmatch("(.-)\f") do
    if page ~= "" then print("  CIENTÍFICO: " .. page:gsub("\n", " ")) end
  end
end
ck(save.flags.MOD_MEW_SCIENTIST_FLED == true, "el científico huye (MOD_MEW_SCIENTIST_FLED)")
ck((save.objectToggles.POKEMON_MANSION_3F.MEW_EVENT_PAPERS_B == true)
   and (save.objectToggles.POKEMON_MANSION_3F.MEW_EVENT_PAPERS_C == true),
   "los papeles nuevos quedan visibles")
print("\n[El científico huye. Los papeles del piso cambian.]\n")

-- 3) leer los tres montones de papeles
local diaries = {
  { "TEXT_POKEMONMANSION3F_DIARY", "Diario junto a la ventana" },
  { "TEXT_MEW_EVENT_PAPERS_B",     "Papeles sobre la mesa" },
  { "TEXT_MEW_EVENT_PAPERS_C",     "Carpeta en el rincón" },
}
for _, d in ipairs(diaries) do
  transcript = {}
  runScript(MS.talk[d[1]])
  print("--- " .. d[2] .. " ---")
  for _, line in ipairs(transcript) do
    for page in (line .. "\f"):gmatch("(.-)\f") do
      if page ~= "" then print("  " .. page:gsub("\n", " ")) end
    end
    print("")
  end
end

for i = 1, 6 do
  ck(save.flags["MOD_MEW_DOC" .. i] == true, "documento " .. i .. " marcado como leído")
end
ck(save.flags.MOD_MEW_DISCOVERED == true,
   "leídos los 6 -> MOD_MEW_DISCOVERED (desbloquea la Etapa 2)")

print("========================================================")
print(("  %d comprobaciones OK, %d fallos"):format(pass, #fails))
for _, f in ipairs(fails) do print("  FALLO: " .. f) end
print("========================================================")
run.release()
os.exit(#fails == 0 and 0 or 1)
