-- es_419: a translation of the game into Español (Latinoamérica).
--
-- Nothing here is translated yet.  Every table under lang/ starts with
-- empty strings; fill one in and it takes effect on the next boot, and
-- anything still empty keeps rendering in English.  That means a
-- half-finished translation is always playable, so you can ship early and
-- fill the long tail in later.
--
-- Read TRANSLATING.md before the first edit; the font is the part people
-- get wrong.
return function(mod)
  -- mod:read is the supported way into your own directory; the catalogs are
  -- plain Lua tables, so read and run them rather than require()ing them.
  local function catalog(name)
    local rel = "lang/" .. name .. ".lua"
    local body = mod:read(rel)
    if not body then return {} end
    local chunk, err = loadstring(body, rel)
    if not chunk then
      mod.log:warn("%s has a syntax error: %s", rel, tostring(err))
      return {}
    end
    local ok, table_ = pcall(chunk)
    if not ok or type(table_) ~= "table" then
      mod.log:warn("%s did not return a table: %s", rel, tostring(table_))
      return {}
    end
    return table_
  end

  -- An empty value means "not translated yet", never "translate to blank".
  local function each(name, apply)
    local n = 0
    for key, value in pairs(catalog(name)) do
      if type(value) == "string" and value ~= "" then
        apply(key, value)
        n = n + 1
      end
    end
    return n
  end

  -- ---- glyphs -------------------------------------------------------
  -- es_ES (loaded first as a dependency) registers the Spanish accent
  -- glyph page (assets/font/accents.png) over the ROM tile font, so this
  -- mod ships no font of its own.  Anything under lang/font.lua /
  -- lang/charmap.lua here still layers on top if you add it.

  -- Register the sheet BEFORE anything asks for a glyph on it.  base is
  -- the first code the page owns; 0x100 and up is free space above the
  -- vanilla pages, so a new alphabet never collides with them.
  for id, page in pairs(catalog("font")) do
    mod.content.font:register(id, page)
  end
  -- charmap: which byte sequence draws which code
  for seq, code in pairs(catalog("charmap")) do
    mod.content.font:register("charmap:" .. seq, { seq = seq, code = code })
  end

  -- ---- text ---------------------------------------------------------
  local counts = {}
  counts.dialogue = each("dialogue", function(id, value)
    mod.content.text:override(id, value)
  end)
  counts.strings = each("strings", function(source, value)
    mod.content.strings:override(source, value)
  end)
  counts.species = each("species_names", function(id, value)
    mod.content.pokemon:patch(id, { name = value })
  end)
  counts.moves = each("move_names", function(id, value)
    mod.content.moves:patch(id, { name = value })
  end)
  counts.items = each("item_names", function(id, value)
    mod.content.items:patch(id, { name = value })
  end)
  counts.trainers = each("trainer_names", function(id, value)
    mod.content.trainers:patch(id, { name = value })
  end)
  counts.statuses = each("status_labels", function(id, value)
    mod.content.statuses:patch(id, { label = value })
  end)
  counts.types = each("type_names", function(id, value)
    local rec = mod.content.type_chart:get(id) or {}
    mod.content.type_chart:override(id,
      { name = value, category = rec.category or "physical", index = rec.index })
  end)

  -- ---- name entry ---------------------------------------------------
  -- The naming screen's letter grid: lang/naming.lua replaces rows 1-4 of
  -- each page and keeps the rest of the grid it is handed (row 5's ED
  -- cell, row 6's case switch), so the screen's confirm/case-flip lookup
  -- still finds them. Leave lang/naming.lua returning {} to keep the
  -- English alphabet. (mod.hooks only offers wrap(name, fn(next, ...)).)
  local grid = catalog("naming")
  if grid.upper then
    mod.hooks:wrap("ui.naming.grid", function(nextGrid, base, ctx)
      base = nextGrid(base, ctx)
      local want = ctx and ctx.lower and grid.lower or grid.upper
      if type(base) ~= "table" or not want then return base end
      local out = {}
      for i, row in ipairs(base) do out[i] = want[i] or row end
      return out
    end)
  end

  mod.events:on("game.ready", function()
    local total = 0
    for _, n in pairs(counts) do total = total + n end
    mod.log:info("Español (Latinoamérica): %d strings translated", total)
  end)
end
