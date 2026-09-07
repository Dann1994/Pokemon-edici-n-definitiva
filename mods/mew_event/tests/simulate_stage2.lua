-- Simulación jugable de la Etapa 2 (casa del Sr. Fuji, Pueblo Lavanda).
--   luajit mods/mew_event/tests/simulate_stage2.lua
-- Imprime, en orden, el texto que vería el jugador en cada visita a Fuji
-- y comprueba que el gate de flags avanza: 1ª charla -> condición -> 2ª
-- charla con la revelación y la entrega del MAPA VIEJO.
package.path = "./?.lua;./?/init.lua;" .. package.path
if not _G.love then _G.love = require("tests.love_stub") end

local T = require("tests.modkit")
local Data = require("src.core.Data"); Data:load()
local run = T.sdk.loadMods({ "mods/es_es", "mods/mew_event" }, { data = Data })
assert(#run.errors == 0, tostring(run.errors[1]))

local Commands = require("src.script.Commands")
local ScriptRunner = require("src.script.ScriptRunner")

-- ---- capture text, stub the world-facing verbs ------------------------
local transcript = {}
Commands.show_text = function(_, text, subs)
  local s = tostring(text)
  if subs then for k, v in pairs(subs) do s = s:gsub("{" .. k .. "[^}]*}", tostring(v)) end end
  transcript[#transcript + 1] = s
end
Commands.face_player = function() end
local given = {}
Commands.give_item = function(ctx, itemId, count)
  given[#given + 1] = itemId
  ctx.save.inventory[itemId] = (ctx.save.inventory[itemId] or 0) + (count or 1)
end

-- ---- a post-League save with Stage 1 already cleared -----------------
local Pokemon = require("src.pokemon.Pokemon")
local SaveData = require("src.core.SaveData")
local save = SaveData.newGame()
save.flags.EVENT_BEAT_CHAMPION_RIVAL = true
save.flags.EVENT_RESCUED_MR_FUJI = true
save.flags.EVENT_GOT_POKE_FLUTE = true
save.flags.MOD_MEW_DISCOVERED = true          -- <- salida de la Etapa 1
save.pokedex.owned.MEWTWO = true
save.party = { Pokemon.new(Data, "MEWTWO", 70), Pokemon.new(Data, "PIKACHU", 60) }

local ow = {
  map = { id = "MR_FUJIS_HOUSE", def = { label = "MR_FUJIS_HOUSE" } },
  npcs = {}, entities = {}, player = { cellX = 3, cellY = 2 },
  npcByName = function() return { def = { index = 5 } } end,
}
local game = { data = Data, save = save,
               stack = { push = function() end, top = function() end } }
ow.runner = ScriptRunner.new(game, ow)

local MapScripts = require("src.script.MapScripts")
local FUJI = MapScripts.get("MR_FUJIS_HOUSE").talk.TEXT_MRFUJISHOUSE_MR_FUJI
assert(FUJI, "Fuji talk script missing")

local function talkToFuji()
  transcript = {}
  local r = ScriptRunner.new(game, ow)
  r:run(FUJI, { overworld = ow, npc = { def = {}, facePlayer = function() end } })
  local guard = 0
  while r:isRunning() and guard < 4000 do guard = guard + 1; r:update() end
end

local function printTranscript(header)
  print("--- " .. header .. " ---")
  for _, line in ipairs(transcript) do
    for page in (line .. "\f"):gmatch("(.-)\f") do
      if page ~= "" then print("  FUJI: " .. page:gsub("\n", " ")) end
    end
  end
  print("")
end

local pass, fails = 0, {}
local function ck(cond, msg)
  if cond then pass = pass + 1 else fails[#fails + 1] = msg end
end

print("========================================================")
print("  SIMULACIÓN -- Etapa 2: casa del Sr. Fuji (Lavanda)")
print("========================================================\n")

-- 1) primera charla: evasiva, fija MOD_MEW_FUJI_MYSTERY
talkToFuji()
printTranscript("Primera visita (evasivo)")
ck(save.flags.MOD_MEW_FUJI_MYSTERY == true, "1ª charla -> MOD_MEW_FUJI_MYSTERY")
ck(#given == 0, "no entrega el mapa todavía")
ck(#transcript > 6, "la 1ª charla tiene varias páginas")

-- 2) volver sin cumplir la condición (menos de 150 registrados)
talkToFuji()
printTranscript("Segunda visita (condición sin cumplir)")
ck(save.flags.MOD_MEW_OLD_MAP == nil, "sin los 150 no entrega el mapa")
ck(#given == 0, "sigue sin entregar el mapa")

-- 3) cumplir la condición: 150 de Kanto + Mewtwo en el equipo
for i = 1, 151 do save.pokedex.owned["SP" .. i] = true end
save.pokedex.owned.MEW = nil            -- Mew aún no; 150 exactos
local owned = 0; for _ in pairs(save.pokedex.owned) do owned = owned + 1 end
assert(owned >= 150, "el fixture debe tener >=150 registrados, tiene " .. owned)

talkToFuji()
printTranscript("Tercera visita (150 + Mewtwo -> revelación)")
ck((transcript[1] or ""):find("Mewtwo"), "reconoce a Mewtwo al abrir")
local joined = table.concat(transcript, " | ")
ck(joined:find("Yo soy F%."), "Fuji revela: \"Yo soy F.\"")
ck(given[1] == "MAPA_VIEJO", "entrega el MAPA VIEJO")
ck(save.inventory.MAPA_VIEJO == 1, "el MAPA VIEJO entra en la bolsa")
ck(save.flags.MOD_MEW_OLD_MAP == true, "fija MOD_MEW_OLD_MAP")

-- 4) volver con el mapa: despedida breve que apunta al puerto
talkToFuji()
printTranscript("Cuarta visita (ya tiene el mapa)")
ck(#given == 1, "no vuelve a entregar el mapa")
ck(table.concat(transcript, " "):find("mar"), "sugiere buscar a alguien del mar")

-- 5) el item quedó registrado como key item
local def = Data.items.MAPA_VIEJO
ck(def ~= nil and def.keyItem == true and def.tossable == false,
   "MAPA_VIEJO registrado como key item no descartable")

print("========================================================")
print(("  %d comprobaciones OK, %d fallos"):format(pass, #fails))
for _, f in ipairs(fails) do print("  FALLO: " .. f) end
print("========================================================")
run.release()
os.exit(#fails == 0 and 0 or 1)
