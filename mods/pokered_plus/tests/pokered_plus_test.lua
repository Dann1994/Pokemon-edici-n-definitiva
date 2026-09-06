-- Standalone: luajit mods/pokered_plus/tests/pokered_plus_test.lua
-- Loads the mod through the real headless loader and asserts its stated
-- effects against the player's imported dataset.
package.path = "./?.lua;./?/init.lua;" .. package.path

local T = require("tests.modkit")
local Data = require("src.core.Data")
Data:load()

local run = T.sdk.loadMod("mods/pokered_plus", { data = Data })
T.eq(#run.errors, 0, "loads clean (" .. tostring(run.errors[1]) .. ")")
T.eq(run.mod and run.mod.state, "loaded", "reached the loaded state")

-- 1. phys/spec split
T.eq(Data.moves.TACKLE.category, "physical", "TACKLE is physical")
T.eq(Data.moves.SURF.category, "special", "SURF is special")
T.eq(Data.moves.BITE.category, "physical", "BITE is physical (Gen 4+)")
T.eq(Data.moves.GUST.category, "special", "GUST is special (Gen 4+)")
T.eq(Data.moves.RAZOR_LEAF.category, "physical", "RAZOR_LEAF is physical")
T.eq(Data.moves.SWORDS_DANCE.category, "status", "SWORDS_DANCE is status")
T.eq(Data.moves.SEISMIC_TOSS.power, 1, "SEISMIC_TOSS keeps its fixed-damage power")

-- 2. new types
T.check(Data.type_chart.types.FAIRY ~= nil, "FAIRY type registered")
T.check(Data.type_chart.types.STEEL ~= nil, "STEEL type registered")
T.check(Data.type_chart.types.DARK ~= nil, "DARK type registered")

local TypeChart = require("src.battle.TypeChart")
TypeChart.load(Data)
-- new types
T.eq(TypeChart.effectiveness("FAIRY", { "DRAGON" }), 20, "FAIRY 2x vs DRAGON")
T.eq(TypeChart.effectiveness("DRAGON", { "FAIRY" }), 0, "DRAGON 0x vs FAIRY")
T.eq(TypeChart.effectiveness("POISON", { "STEEL" }), 0, "POISON 0x vs STEEL")
T.eq(TypeChart.effectiveness("FIGHTING", { "STEEL" }), 20, "FIGHTING 2x vs STEEL")
T.eq(TypeChart.effectiveness("DARK", { "PSYCHIC_TYPE" }), 20, "DARK 2x vs PSYCHIC")
T.eq(TypeChart.effectiveness("PSYCHIC_TYPE", { "DARK" }), 0, "PSYCHIC 0x vs DARK")
T.eq(TypeChart.effectiveness("STEEL", { "FAIRY" }), 20, "STEEL 2x vs FAIRY")
T.eq(TypeChart.effectiveness("STEEL", { "WATER" }), 5, "STEEL 0.5x vs WATER")
-- Gen 6 rewrites of vanilla rows
T.eq(TypeChart.effectiveness("GHOST", { "PSYCHIC_TYPE" }), 20,
  "GHOST 2x vs PSYCHIC (Gen 1 no-effect bug fixed)")
T.eq(TypeChart.effectiveness("BUG", { "POISON" }), 5, "BUG 0.5x vs POISON (was 2x)")
T.eq(TypeChart.effectiveness("POISON", { "BUG" }), 10, "POISON neutral vs BUG (was 2x)")
T.eq(TypeChart.effectiveness("ICE", { "FIRE" }), 5, "ICE 0.5x vs FIRE (Fire now resists)")
T.eq(TypeChart.effectiveness("GRASS", { "STEEL" }), 5, "GRASS 0.5x vs STEEL")
-- an unchanged vanilla row still works
T.eq(TypeChart.effectiveness("WATER", { "FIRE" }), 20, "WATER 2x vs FIRE unchanged")
T.eq(TypeChart.effectiveness("ELECTRIC", { "GROUND" }), 0, "ELECTRIC 0x vs GROUND unchanged")

-- 3. species retypes
T.eq(Data.pokemon.CLEFAIRY.types[1], "FAIRY", "CLEFAIRY is FAIRY")
T.eq(Data.pokemon.MAGNEMITE.types[2], "STEEL", "MAGNEMITE is ELECTRIC/STEEL")
T.eq(Data.pokemon.JIGGLYPUFF.types[2], "FAIRY", "JIGGLYPUFF is NORMAL/FAIRY")
T.check(#Data.pokemon.CLEFAIRY.learnset > 0, "CLEFAIRY keeps its learnset")

-- 4. modern ruleset
T.check(Data.rulesets ~= nil and Data.rulesets.modern ~= nil,
  "modern ruleset registered")
T.eq(Data.rulesets.modern.oneIn256Miss, false, "modern ruleset kills the 1/256 miss")
T.eq(Data.rulesets.gen1_faithful.oneIn256Miss, true, "gen1_faithful is untouched")
T.eq(Data.constants.defaultRuleset, "modern", "modern is the default ruleset")

run.release()
T.finish("pokered_plus")
