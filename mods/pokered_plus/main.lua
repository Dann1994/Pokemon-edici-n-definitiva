-- pokered_plus: quality-of-life + modernisation overhaul for Pokemon Red.
--
--   1. the Gen 4+ physical / special / status move split
--   2. FAIRY / STEEL / DARK types + the full Gen 6 type chart
--   3. constants.defaultRuleset -> "modern" (the builtin bug-free ruleset)
--   4. per-species party-menu mini sprites for all 151
--   5. per-species overworld art for the birds, Mewtwo, Snorlax and the
--      decorative pet Pokemon
--
-- Roadmap / decisions: ../../BACKLOG.md.

local function shallowCopy(t)
  local o = {}
  for k, v in pairs(t) do o[k] = v end
  return o
end

local function shallowCopyList(t)
  local o = {}
  for i = 1, #t do o[i] = t[i] end
  return o
end

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
  -- the engine's 16x32 two-frame format by
  -- tools/pokered_plus_convert_icons.py.  icons.bySpecies wins over the
  -- vanilla ~10 shared dex icons (src/ui/PartyMenu.lua:drawIcon).
  local iconList = readTable(mod, "data/icons_list.lua")
  local speciesSet = {}
  for _, species in ipairs(iconList or {}) do
    speciesSet[species] = true
    if mod.content.pokemon:get(species) then
      mod.content.icons:register(species, {
        image = mod.path .. "/assets/icons/" .. species:lower() .. ".png",
        frames = 2,
      })
    end
  end
  mod.log:info("mini sprites: %d species", #(iconList or {}))

  -- ---------------------------------------------- 5. overworld Pokemon art
  -- The legendary birds, Mewtwo, Snorlax and the decorative pet Pokemon in
  -- houses all share a few generic overworld sprites (SPRITE_MONSTER /
  -- SPRITE_BIRD / ...).  Point each object at a per-species sprite built
  -- from its mini sprite (tools/pokered_plus_overworld_mons.py).  The
  -- Power Plant Voltorb / Electrode keep SPRITE_POKE_BALL -- they are
  -- meant to look like items until you touch them.
  local GENERIC = {
    SPRITE_MONSTER = true, SPRITE_BIRD = true, SPRITE_SNORLAX = true,
    SPRITE_SEEL = true, SPRITE_FAIRY = true,
  }
  local RENAME = {
    NIDORANF = "NIDORAN_F", NIDORANM = "NIDORAN_M", MRMIME = "MR_MIME",
  }
  local function speciesOf(obj)
    if obj.pokemon and speciesSet[obj.pokemon] then return obj.pokemon end
    local tail = tostring(obj.name or ""):match("_([A-Z0-9]+)$")
    if not tail then return nil end
    tail = RENAME[tail] or tail
    return speciesSet[tail] and tail or nil
  end

  local registered, swapped, patches = {}, 0, {}
  for mapId, map in mod.content.maps:each() do
    local objects = map.objects
    if type(objects) == "table" then
      local copy
      for i, obj in ipairs(objects) do
        if type(obj) == "table" and GENERIC[obj.sprite] then
          local sp = speciesOf(obj)
          if sp then
            local spriteId = "SPRITE_MON_" .. sp
            if not registered[sp] then
              mod.content.sprites:register(spriteId, {
                image = mod.path .. "/assets/ow/" .. sp:lower() .. ".png",
                frames = 1,
                walker = false,
              })
              registered[sp] = true
            end
            copy = copy or shallowCopyList(objects)
            copy[i] = shallowCopy(obj)
            copy[i].sprite = spriteId
            swapped = swapped + 1
          end
        end
      end
      if copy then patches[mapId] = copy end
    end
  end
  for mapId, objects in pairs(patches) do
    mod.content.maps:patch(mapId, { objects = objects })
  end
  mod.log:info("overworld Pokemon: %d objects repointed", swapped)

  -- ----------------------------------------------- 6. title-screen ribbon
  -- Replace the "Red Version" ribbon with "EDICIÓN DEFINITIVA".
  -- src/ui/TitleState.lua merges field.boot.title over the extracted
  -- field.title; versionRibbon is drawn whole (centred, y=64) and coloured
  -- by the title's LOGO1 palette.  Art: tools/pokered_plus_title_ribbon.py.
  mod.content.field:patch("boot", {
    title = {
      versionRibbon = mod.path .. "/assets/title/edicion_definitiva.png",
    },
  })
  mod.log:info("title ribbon: EDICIÓN DEFINITIVA")
end
