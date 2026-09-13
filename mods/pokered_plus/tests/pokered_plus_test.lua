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

-- src/link/Fingerprint.lua hashes type_chart.matchups in registration order
-- (not sorted, unlike every named-key map in the link surface -- see its own
-- header comment), so the order this mod's :register/:override calls fire in
-- is part of the LAN/online link fingerprint. The two nested loops used to
-- walk modern.chart/row with a bare pairs(), whose order is not guaranteed
-- across separate process launches -- confirmed live by booting two real
-- instances of the same build and finding they disagreed on the fingerprint
-- and refused to link battle with each other, despite being byte-identical
-- installs. All the DARK/STEEL/FAIRY attacker rows are new (those types don't
-- exist pre-mod), so they were all just :register'd in this call, in
-- whatever order the two loops produced -- asserting that subsequence is
-- sorted pins the fix (sorted iteration) rather than the bug (hash order).
do
  local newRows = {}
  for _, row in ipairs(Data.type_chart.matchups) do
    if row.attacker == "DARK" or row.attacker == "STEEL" or row.attacker == "FAIRY" then
      newRows[#newRows + 1] = row.attacker .. ">" .. row.defender
    end
  end
  T.check(#newRows > 0, "the Gen 6 chart actually added DARK/STEEL/FAIRY attacker rows")
  local sorted = {}
  for i, v in ipairs(newRows) do sorted[i] = v end
  table.sort(sorted)
  local inOrder = true
  for i = 1, #newRows do
    if newRows[i] ~= sorted[i] then inOrder = false break end
  end
  T.check(inOrder,
    "new Gen 6 chart rows register in a deterministic sorted order "
    .. "(not raw pairs() order, which could differ between two identical "
    .. "installs and desync the link fingerprint)")
end

-- 3. species retypes
T.eq(Data.pokemon.CLEFAIRY.types[1], "FAIRY", "CLEFAIRY is FAIRY")
T.eq(Data.pokemon.MAGNEMITE.types[2], "STEEL", "MAGNEMITE is ELECTRIC/STEEL")
T.eq(Data.pokemon.JIGGLYPUFF.types[2], "FAIRY", "JIGGLYPUFF is NORMAL/FAIRY")
T.check(#Data.pokemon.CLEFAIRY.learnset > 0, "CLEFAIRY keeps its learnset")

-- 4. mini sprites
T.check(type(Data.icons.bySpecies) == "table", "icons.bySpecies exists")
T.check(type(Data.icons.bySpecies.PIKACHU) == "table"
  and Data.icons.bySpecies.PIKACHU.frames == 2, "PIKACHU has a per-species icon")
T.check(Data.icons.bySpecies.MEWTWO ~= nil, "MEWTWO has a per-species icon")
do
  local n = 0
  for _ in pairs(Data.icons.bySpecies) do n = n + 1 end
  T.eq(n, 151, "all 151 species get a mini sprite")
end

-- 4b. overworld Pokemon art
T.check(Data.sprites.SPRITE_MON_MEWTWO ~= nil, "Mewtwo has an overworld sprite")
T.check(Data.sprites.SPRITE_MON_ARTICUNO ~= nil, "Articuno has an overworld sprite")
T.check(Data.sprites.SPRITE_MON_SNORLAX ~= nil, "Snorlax has an overworld sprite")
do
  local mewtwo
  for _, o in ipairs(Data.maps.CERULEAN_CAVE_B1F.objects) do
    if o.pokemon == "MEWTWO" then mewtwo = o end
  end
  T.check(mewtwo ~= nil, "the Mewtwo object is still there")
  T.eq(mewtwo.sprite, "SPRITE_MON_MEWTWO", "the Mewtwo object points at its sprite")
  T.eq(mewtwo.text, "TEXT_CERULEANCAVEB1F_MEWTWO", "and keeps its other fields")
end
do
  -- the Power Plant Voltorb/Electrode keep the poke-ball disguise
  local disguised = 0
  for _, o in ipairs(Data.maps.POWER_PLANT.objects) do
    if o.sprite == "SPRITE_POKE_BALL" then disguised = disguised + 1 end
  end
  T.check(disguised >= 8, "Power Plant Voltorb/Electrode still look like items")
end

-- 4c. title ribbon
do
  local bt = Data.field and Data.field.boot and Data.field.boot.title
  T.check(bt ~= nil and type(bt.versionRibbon) == "string"
    and bt.versionRibbon:match("edicion_definitiva%.png$"),
    "title ribbon points at EDICIÓN DEFINITIVA art")
end

-- 5. modern ruleset
T.check(Data.rulesets ~= nil and Data.rulesets.modern ~= nil,
  "modern ruleset registered")
T.eq(Data.rulesets.modern.oneIn256Miss, false, "modern ruleset kills the 1/256 miss")
T.eq(Data.rulesets.modern.xAccuracyNeverMiss, false,
  "modern: X ACCURACY no longer skips the accuracy check (no free OHKOs)")
T.eq(Data.rulesets.gen1_faithful.oneIn256Miss, true, "gen1_faithful is untouched")
T.eq(Data.rulesets.gen1_faithful.xAccuracyNeverMiss, true, "gen1_faithful keeps the quirk")
T.eq(Data.constants.defaultRuleset, "modern", "modern is the default ruleset")

-- 7. new DARK/FAIRY/STEEL moves + learnset
T.eq(Data.moves.BITE.type, "DARK", "BITE retyped to DARK")
T.check(Data.moves.CRUNCH ~= nil, "CRUNCH registered")
T.eq(Data.moves.CRUNCH.type, "DARK", "CRUNCH is DARK")
T.eq(Data.moves.CRUNCH.category, "physical", "CRUNCH is physical")
T.eq(Data.moves.MOONBLAST.type, "FAIRY", "MOONBLAST is FAIRY")
T.eq(Data.moves.MOONBLAST.category, "special", "MOONBLAST is special")
T.eq(Data.moves.IRON_DEFENSE.type, "STEEL", "IRON_DEFENSE is STEEL")
T.eq(Data.moves.IRON_DEFENSE.power, 0, "IRON_DEFENSE is a status move")
for _, id in ipairs({ "PURSUIT", "THIEF", "FEINT_ATTACK", "TAUNT",
    "DISARMING_VOICE", "DRAINING_KISS", "DAZZLING_GLEAM", "PLAY_ROUGH",
    "METAL_CLAW", "STEEL_WING", "IRON_TAIL", "METAL_SOUND" }) do
  T.check(Data.moves[id] ~= nil, id .. " registered")
  T.check(Data.moves[id].effect ~= nil, id .. " has a move_effects id")
end

do
  local function hasLevel(learnset, move, level)
    for _, e in ipairs(learnset) do
      if e.move == move and e.level == level then return true end
    end
    return false
  end
  local function sorted(learnset)
    for i = 2, #learnset do
      if learnset[i - 1].level > learnset[i].level then return false end
    end
    return true
  end
  T.check(hasLevel(Data.pokemon.CLEFAIRY.learnset, "MOONBLAST", 40),
    "CLEFAIRY learns MOONBLAST at 40")
  T.check(hasLevel(Data.pokemon.ONIX.learnset, "IRON_TAIL", 30),
    "ONIX learns IRON_TAIL at 30")
  T.check(sorted(Data.pokemon.CLEFAIRY.learnset),
    "CLEFAIRY's merged learnset stays level-ascending")
  T.check(sorted(Data.pokemon.ONIX.learnset),
    "ONIX's merged learnset stays level-ascending")
  -- the vanilla entries are still there -- patch merged, it did not replace
  T.check(#Data.pokemon.ONIX.learnset > 2,
    "ONIX kept its vanilla learnset alongside the new moves")
end

run.release()
T.finish("pokered_plus")
