-- Standalone: luajit mods/es_ES/tests/es_ES_test.lua
package.path = "./?.lua;./?/init.lua;" .. package.path

local T = require("tests.modkit")
local Data = require("src.core.Data")
Data:load()

-- ---- es_ES on its own: Spain move/type/item names -----------------------
local run = T.sdk.loadMod("mods/es_es", { data = Data })
T.eq(#run.errors, 0, "es_ES loads clean (" .. tostring(run.errors[1]) .. ")")
T.eq(Data.moves.TACKLE.name, "Placaje", "es_ES: TACKLE -> Placaje")
T.eq(Data.moves.THUNDERBOLT.name, "Rayo", "es_ES: THUNDERBOLT -> Rayo")
T.eq(Data.moves.SURF.name, "Surf", "es_ES: SURF -> Surf")
T.eq(Data.moves.POUND.power, 40, "move mechanics untouched")
T.eq(Data.items.POTION.name, "POCIÓN", "es_ES: POTION -> POCIÓN")
T.eq(Data.items.GREAT_BALL.name, "SUPER BALL", "es_ES: GREAT BALL -> SUPER BALL")
T.eq(Data.statuses.PSN.label, "ENV", "es_ES: PSN -> ENV")
T.eq(Data.trainers.OPP_BUG_CATCHER.name, "CAZABICHOS", "es_ES: bug catcher class")
local TC = require("src.battle.TypeChart"); TC.load(Data)
T.eq(TC.displayName("BUG", Data), "BICHO", "es_ES: BUG type -> BICHO")
T.eq(TC.displayName("FIGHTING", Data), "LUCHA", "es_ES: FIGHTING -> LUCHA")
-- place names: TownMap:bannerText renders loc.name through Strings(),
-- which folds the strings registry
T.eq(Data.strings["PALLET TOWN"], "PUEBLO PALETA", "es_ES: place name PALLET TOWN")
T.eq(Data.strings["CERULEAN CITY"], "CIUDAD CELESTE", "es_ES: place name CERULEAN CITY")
T.eq(Data.strings["ROUTE 5"], "RUTA 5", "es_ES: ROUTE 5 -> RUTA 5")
T.eq(Data.strings["ATTACK"], "ATAQUE", "es_ES: UI string still there")
run.release()

-- ---- es_419 catalogs carry the Legends Z-A move / type names -----------
local function catalog(mod, name)
  return assert(loadfile("mods/" .. mod .. "/lang/" .. name .. ".lua"))()
end
local m419 = catalog("es_419", "move_names")
T.eq(m419.TACKLE, "Tacleada", "es_419 catalog: TACKLE -> Tacleada")
T.eq(m419.THUNDERBOLT, "Atactrueno", "es_419 catalog: THUNDERBOLT -> Atactrueno")
T.eq(m419.SWORDS_DANCE, "Danza de Espadas", "es_419 catalog: SWORDS DANCE")
local count419 = 0
for _ in pairs(m419) do count419 = count419 + 1 end
T.eq(count419, 165, "es_419 has all 165 move names")
local t419 = catalog("es_419", "type_names")
T.eq(t419.BUG, "INSECTO", "es_419 catalog: BUG -> INSECTO")
T.eq(t419.FIGHTING, "PELEA", "es_419 catalog: FIGHTING -> PELEA")
T.eq(catalog("es_419", "item_names").GREAT_BALL, "Superbola", "es_419: GREAT BALL -> Superbola")

T.finish("es_ES")
