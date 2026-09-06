-- pokered_plus: quality-of-life + modernisation overhaul for Pokemon Red.
--
-- This first slice does three things, all through the public mod API:
--   1. the Gen 4+ physical / special / status move split
--   2. the FAIRY, STEEL and DARK types, with their type-chart interactions
--   3. a "modern" battle ruleset that turns off the famous Gen 1 bugs
--      (opt in from OPTIONS > RULESET; not forced)
--
-- Everything else on the roadmap (modern type chart, Yellow colours, map
-- and menu bug fixes, new events, Mew capture, Prof. Oak battle) lives in
-- ../../BACKLOG.md.

local function readTable(mod, rel)
  local source = mod:read(rel)
  if not source then
    mod.log:error("%s missing -- reinstall the mod", rel)
    return nil
  end
  local chunk, err = load(source, "@" .. mod.path .. "/" .. rel)
  if not chunk then
    mod.log:error("%s did not compile: %s", rel, tostring(err))
    return nil
  end
  local ok, value = pcall(chunk)
  if not ok then
    mod.log:error("%s failed: %s", rel, tostring(value))
    return nil
  end
  return value
end

return function(mod)
  -- ---------------------------------------------------------------- 1. split
  local categories = readTable(mod, "data/move_categories.lua")
  local split = 0
  if categories then
    for id, category in pairs(categories) do
      if mod.content.moves:get(id) then
        mod.content.moves:patch(id, { category = category })
        split = split + 1
      else
        mod.log:warn("move %s not in the merged view; category skipped", id)
      end
    end
  end
  mod.log:info("phys/spec split: categorised %d moves", split)

  -- ------------------------------------------------------------ 2. new types
  local modern = readTable(mod, "data/types_modern.lua")
  if modern then
    for id, record in pairs(modern.types) do
      mod.content.type_chart:register(id, record)
    end
    for pair, multiplier in pairs(modern.matchups) do
      -- every pair here involves a brand-new type, so it cannot already
      -- exist in the vanilla chart -- register, not override
      mod.content.type_chart:register(pair, { multiplier = multiplier })
    end
    local retyped = 0
    for id, types in pairs(modern.species) do
      if mod.content.pokemon:get(id) then
        mod.content.pokemon:patch(id, { types = types })
        retyped = retyped + 1
      else
        mod.log:warn("species %s not in the merged view; retype skipped", id)
      end
    end
    mod.log:info("types: +FAIRY +STEEL +DARK, %d species retyped", retyped)
  end

  -- ------------------------------------------------------- 3. modern ruleset
  -- Mirrors src/battle/rulesets/gen1_faithful.lua with every quirk flag
  -- flipped to its fixed value.  Selectable as OPTIONS > RULESET > MODERN.
  mod.content.rulesets:register("modern", {
    name = "modern",
    oneIn256Miss = false,
    critUsesBaseSpeed = false,
    critIgnoresStages = false,
    focusEnergyBug = false,
    enemyUnlimitedPP = false,
    hyperBeamSkipRechargeOnKO = false,
    residualAfterMove = false,
    badgeBoostReapplyBug = false,
    zeroDamageMiss = false,
    statusPenaltyIsBaked = false,
    randMin = 217,
    randMax = 255,
  })
  mod.log:info("registered the 'modern' ruleset (opt in from OPTIONS)")
end
