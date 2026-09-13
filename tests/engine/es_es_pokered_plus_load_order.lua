-- Regression: es_es must load AFTER pokered_plus.
--
-- es_es's type_names catalog (mods/es_es/lang/type_names.lua) applies via
-- mod.content.type_chart:override(id, {...}) for every id it lists
-- (mods/es_es/main.lua). override() appends an op unconditionally -- with
-- NO prior "register" op, Registry:get(id) still folds to a non-nil value
-- (Registry.lua's fold() treats "override" as a straight replace) -- so an
-- override on an id nothing has registered yet quietly creates one. DARK,
-- STEEL and FAIRY do not exist anywhere in Gen 1's own data; only
-- pokered_plus's own tc:register() calls (mods/pokered_plus/main.lua)
-- create them. Loading es_es BEFORE pokered_plus therefore made es_es's
-- override "arrive first", and pokered_plus's later register() saw
-- Registry:get(id) ~= nil and threw "type_chart already registered: DARK"
-- -- which is a "record" registry's hard collision guard, so the whole
-- pokered_plus mod aborted, silently losing the Gen 6 type chart, the
-- retyping, the new moves, everything past that point (a screenshot
-- caught this: MAGNEMITE showed ELECTRIC only, no STEEL, and the type
-- itself showed as the untranslated English "STEEL"/"FAIRY").
--
-- Fixed with mods/es_es/manifest.json's optional_dependencies (ordering
-- only, no hard requirement -- es_es still loads fine with pokered_plus
-- disabled or absent).
--   luajit tests/engine/es_es_pokered_plus_load_order.lua

package.path = "./?.lua;./?/init.lua;" .. package.path

local T = require("tests.modkit")
local Data = require("src.core.Data")
Data:load()

local run = T.sdk.loadMods({ "mods/pokered_plus", "mods/es_es" }, { data = Data })
T.eq(#run.errors, 0, "both mods load clean (" .. tostring(run.errors[1]) .. ")")
T.eq(run.mods.pokered_plus and run.mods.pokered_plus.state, "loaded",
  "pokered_plus reached the loaded state (not aborted by a later collision)")
T.eq(run.mods.es_es and run.mods.es_es.state, "loaded", "es_es reached the loaded state")

-- the actual symptom: a species pokered_plus retypes must carry BOTH types
T.check(Data.pokemon.MAGNEMITE ~= nil, "MAGNEMITE is in the merged data")
local types = Data.pokemon.MAGNEMITE and Data.pokemon.MAGNEMITE.types or {}
T.eq(types[1], "ELECTRIC", "MAGNEMITE keeps its Gen 1 primary type")
T.eq(types[2], "STEEL",
  "and gains STEEL from pokered_plus -- lost entirely when the mod aborted")

-- and es_es's own translation must actually apply to them
local TypeChart = require("src.battle.TypeChart")
TypeChart.load(Data)
T.eq(TypeChart.displayName("STEEL", Data), "ACERO", "STEEL -> ACERO")
T.eq(TypeChart.displayName("FAIRY", Data), "HADA", "FAIRY -> HADA")
T.eq(TypeChart.displayName("DARK", Data), "SINIESTRO", "DARK -> SINIESTRO")
-- a Gen 1 type, unaffected either way, stays a sanity check on the pair
T.eq(TypeChart.displayName("WATER", Data), "AGUA", "an original type still translates")

run.release()
T.finish("es_es / pokered_plus load order")
