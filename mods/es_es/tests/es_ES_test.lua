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

-- name entry (lang/naming.lua through ui.naming.grid): Spanish alphabet
-- with the Ñ after N, accented vowels on row 4, ED + case switch kept
do
  local NamingScreen = require("src.ui.NamingScreen")
  local game = { data = Data, stack = { pop = function() end },
                 input = { wasPressed = function() return false end } }
  local ns = NamingScreen.new(game, { title = "MOTE?", maxLen = 10 })
  local g = ns:grid()
  T.eq(g[2][6], "Ñ", "naming grid: Ñ right after N (upper)")
  T.eq(g[2][5], "N", "naming grid: N stays before it")
  T.eq(g[3][9], "Z", "naming grid: the 27 letters fill rows 1-3")
  T.eq(g[4][1], " ", "naming grid: the space moved to row 4")
  T.eq(g[4][2], "Á", "naming grid: accented capitals on row 4")
  T.eq(g[4][6], "Ú", "naming grid: Ú")
  -- the accents page (main.lua) has ü but no Ü: a glyph-less cell would
  -- type an invisible character, so the grid must not offer one
  for r = 1, 4 do
    for _, cell in ipairs(g[r]) do
      T.check(cell ~= "95n", "naming grid: no glyph-less Ü cell")
    end
  end
  T.eq(g[5][9], "ED", "naming grid: ED cell kept from the base grid")
  T.eq(#g, 6, "naming grid: still 5 rows + the case switch")
  T.eq(#g[6], 1, "naming grid: case-switch row kept")
  ns.lower = true
  local lg = ns:grid()
  T.eq(lg[2][6], "ñ", "naming grid: ñ on the lower-case page")
  T.eq(lg[4][3], "é", "naming grid: accented lower-case vowels")
  for r = 1, 5 do
    T.eq(#lg[r], 9, "naming grid: lower row " .. r .. " is 9 cells")
  end
end
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
