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

  -- ---------------------------------------- 2. new types + full Gen 6 chart
  local modern = readTable(mod, "data/types_modern.lua")
  if modern then
    local tc = mod.content.type_chart

    for id, record in pairs(modern.types) do
      tc:register(id, record)
    end

    -- full Gen 6 chart: override the vanilla row where it exists, register
    -- it where it does not
    local cells = 0
    for attacker, row in pairs(modern.chart) do
      for defender, multiplier in pairs(row) do
        local pair = attacker .. ">" .. defender
        if tc:get(pair) ~= nil then
          tc:override(pair, { multiplier = multiplier })
        else
          tc:register(pair, { multiplier = multiplier })
        end
        cells = cells + 1
      end
    end
    for _, pair in ipairs(modern.neutralized or {}) do
      if tc:get(pair) ~= nil then tc:remove(pair) end
    end
    mod.log:info("type chart: Gen 6 (%d cells, %d neutralised)",
                 cells, #(modern.neutralized or {}))

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

  -- ---------------------------------------------------- 3. default ruleset
  -- The "modern" ruleset (bug-free Gen 1) is now a builtin
  -- (src/battle/rulesets/modern.lua) and src/core/SaveData.lua makes it the
  -- default for new saves.  Keep the engine fallback in step for any
  -- context that reads a nil options.ruleset.
  mod.content.constants:patch("defaultRuleset", "modern")

  -- ------------------------------------------------------- 4. mini sprites
  -- Per-species party-menu icons, from Pokemon Yellow Legacy, converted to
  -- the engine's 16x32 two-frame DMG-grey format by
  -- tools/pokered_plus_convert_icons.py.  icons.bySpecies wins over the
  -- vanilla ~10 shared dex icons (src/ui/PartyMenu.lua:drawIcon).
  local iconList = readTable(mod, "data/icons_list.lua")
  local icons = 0
  for _, species in ipairs(iconList or {}) do
    if mod.content.pokemon:get(species) then
      mod.content.icons:register(species, {
        image = mod.path .. "/assets/icons/" .. species:lower() .. ".png",
        frames = 2,
      })
      icons = icons + 1
    end
  end
  mod.log:info("mini sprites: %d species", icons)
end
