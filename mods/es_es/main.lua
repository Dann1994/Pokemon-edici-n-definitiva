-- es_ES: a translation of the game into Español.
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
  -- Text rendering through the bundled Plain Pixel TTF ("Plain Pixel
  -- Font" by Douglas Vautour (Burpy Fresh), CC-BY 4.0 -- see
  -- assets/fonts/plainpixel/README.md).  Registered, it replaces the tile
  -- font for ordinary characters, so a translation needs no glyph sheet
  -- at all; box borders and <PK>-style macros keep their tiles.  Options:
  -- { file = mod.assets:path("myfont.ttf"), size = 15, spacing = 0,
  --   yOffset = -6, bold = true } -- size is the font's design em (Plain
  -- Pixel only rasterizes cleanly at multiples of 15), bold thickens a
  -- 1px-stroke font that reads too light.
  -- Spanish accents as an 8px glyph page LAYERED on the ROM tile font, so
  -- ordinary text keeps the native Game Boy size.  The bundled Plain Pixel
  -- TTF (register("ttf", {})) is the alternative, but its glyphs are ~1.5x
  -- taller than the tile font and read as oversized in the text box.
  -- "e" acute (é, code 186) and the ellipsis already have ROM tiles.
  mod.content.font:register("es_accents", {
    image = mod.assets:path("assets/font/accents.png"),
    base = 0x100,
    glyphsPerRow = 16,
    charmap = {
      { code = 0x100, seq = "\195\161" }, -- á
      { code = 0x101, seq = "\195\173" }, -- í
      { code = 0x102, seq = "\195\179" }, -- ó
      { code = 0x103, seq = "\195\186" }, -- ú
      { code = 0x104, seq = "\195\188" }, -- ü
      { code = 0x105, seq = "\195\177" }, -- ñ
      { code = 0x106, seq = "\194\191" }, -- ¿
      { code = 0x107, seq = "\194\161" }, -- ¡
      { code = 0x108, seq = "\195\129" }, -- Á
      { code = 0x109, seq = "\195\137" }, -- É
      { code = 0x10A, seq = "\195\141" }, -- Í
      { code = 0x10B, seq = "\195\147" }, -- Ó
      { code = 0x10C, seq = "\195\154" }, -- Ú
      { code = 0x10D, seq = "\195\145" }, -- Ñ
      { code = 0x10E, seq = "\194\170" }, -- ª
    },
  })

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
  -- The naming screen's letter grid.  Leave lang/naming.lua returning nil
  -- to keep the English alphabet.
  local grid = catalog("naming")
  if grid.upper then
    mod.hooks:on("ui.naming.grid", function(base, ctx)
      local want = ctx.lower and grid.lower or grid.upper
      return want or base
    end)
  end

  mod.events:on("game.ready", function()
    local total = 0
    for _, n in pairs(counts) do total = total + n end
    mod.log:info("Español: %d strings translated", total)
  end)
end
