-- mew_event -- Stage 1: Pokemon Mansion 3F (the scientist + the F. documents)
--
-- See DESIGN.md (narrative) and PLAN.md (engine mapping). Stages 2-5
-- (Fuji / Mapa Viejo / Isla Suprema / Mew) are not implemented yet.

local MANSION = "POKEMON_MANSION_3F"

-- flags (MOD_ prefix per the project convention)
local FLED       = "MOD_MEW_SCIENTIST_FLED"
local DISCOVERED = "MOD_MEW_DISCOVERED"
local DOC_FLAG   = { "MOD_MEW_DOC1", "MOD_MEW_DOC2", "MOD_MEW_DOC3",
                     "MOD_MEW_DOC4", "MOD_MEW_DOC5", "MOD_MEW_DOC6" }

-- new objects added to Mansion 3F, hidden until the event runs. The two
-- extra "papeles" sit in the same lower-left room as the vanilla diary.
local SCIENTIST = "MEW_EVENT_SCIENTIST"
local PAPERS_B  = "MEW_EVENT_PAPERS_B"
local PAPERS_C  = "MEW_EVENT_PAPERS_C"
local VANILLA_DIARY = "POKEMONMANSION3F_DIARY"

local function readTable(mod, rel)
  local src = assert(mod:read(rel), rel .. " missing")
  return assert(loadstring(src, "@" .. mod.path .. "/" .. rel))()
end

return function(mod)
  local docs = readTable(mod, "data/documents.lua")

  -- ---- custom script verbs -------------------------------------------
  mod.content.commands:register("mew_event:owns", {
    fn = function(ctx, species)
      local dex = ctx.save.pokedex
      ctx.lastCheck = dex and dex.owned and dex.owned[species] ~= nil
    end,
  })
  mod.content.commands:register("mew_event:party_has", {
    fn = function(ctx, species)
      ctx.lastCheck = false
      for _, mon in ipairs(ctx.save.party or {}) do
        if mon.species == species then ctx.lastCheck = true; return end
      end
    end,
  })
  -- Stage A gate: league beaten + Mewtwo owned + Mewtwo in the party now
  mod.content.commands:register("mew_event:stage_a", {
    fn = function(ctx)
      local f = ctx.save.flags or {}
      local dex = ctx.save.pokedex
      local ok = f.EVENT_BEAT_CHAMPION_RIVAL == true
        and dex and dex.owned and dex.owned.MEWTWO ~= nil
      if ok then
        ok = false
        for _, mon in ipairs(ctx.save.party or {}) do
          if mon.species == "MEWTWO" then ok = true; break end
        end
      end
      ctx.lastCheck = ok
    end,
  })
  -- mark a document read; when all six are read, the player "gets it"
  mod.content.commands:register("mew_event:read_doc", {
    foreground = true,
    fn = function(ctx, n)
      require("src.script.Flags").set(ctx.save, DOC_FLAG[n])
      local all = true
      for i = 1, 6 do
        if not (ctx.save.flags and ctx.save.flags[DOC_FLAG[i]]) then all = false end
      end
      ctx.lastCheck = all
    end,
  })

  -- ---- the new Mansion 3F objects ----------------------------------
  local base = mod.content.maps:get(MANSION)
  local objects = {}
  for i, o in ipairs(base.objects) do
    objects[i] = {}
    for k, v in pairs(o) do objects[i][k] = v end
  end
  local nextIndex = #objects
  local function add(o)
    nextIndex = nextIndex + 1
    o.index = nextIndex
    o.hidden = true
    objects[#objects + 1] = o
    return o
  end
  add({ name = SCIENTIST, sprite = "SPRITE_SCIENTIST", movement = "STAY",
        range = "NONE", x = 8, y = 10, text = "TEXT_MEW_EVENT_SCIENTIST" })
  add({ name = PAPERS_B, sprite = "SPRITE_POKEDEX", movement = "STAY",
        range = "NONE", x = 4, y = 11, text = "TEXT_MEW_EVENT_PAPERS_B" })
  add({ name = PAPERS_C, sprite = "SPRITE_POKEDEX", movement = "STAY",
        range = "NONE", x = 8, y = 11, text = "TEXT_MEW_EVENT_PAPERS_C" })
  mod.content.maps:patch(MANSION, { objects = objects })

  -- ---- the map script ---------------------------------------------
  local function showPapers(game, ow)
    local C = require("src.script.Commands")
    local ctx = { game = game, save = game.save, overworld = ow }
    C.show_object(ctx, MANSION, PAPERS_B)
    C.show_object(ctx, MANSION, PAPERS_C)
  end

  mod.content.map_scripts:register(MANSION, {
    -- all-run: composes with the vanilla onEnter
    onEnter = function(game, ow)
      local f = game.save and game.save.flags or {}
      if f[FLED] then
        showPapers(game, ow)
      elseif f.EVENT_BEAT_CHAMPION_RIVAL and game.save.pokedex
             and game.save.pokedex.owned and game.save.pokedex.owned.MEWTWO then
        local hasMewtwo = false
        for _, mon in ipairs(game.save.party or {}) do
          if mon.species == "MEWTWO" then hasMewtwo = true break end
        end
        if hasMewtwo then
          require("src.script.Commands").show_object(
            { game = game, save = game.save, overworld = ow }, MANSION, SCIENTIST)
        end
      end
    end,

    -- the scientist notices the player crossing into the diary room
    onStep = function(game, ow, x, y)
      local f = game.save.flags or {}
      if f[FLED] then return false end
      if not (f.EVENT_BEAT_CHAMPION_RIVAL and game.save.pokedex
              and game.save.pokedex.owned and game.save.pokedex.owned.MEWTWO) then
        return false
      end
      local hasMewtwo = false
      for _, mon in ipairs(game.save.party or {}) do
        if mon.species == "MEWTWO" then hasMewtwo = true break end
      end
      if not hasMewtwo then return false end
      if y > 11 or x < 3 or x > 9 then return false end

      local sci = ow.npcByName and ow:npcByName(SCIENTIST)
      ow.runner:run({
        { "mew_event:approach" },
        { "face_player" },
        { "show_text", "¡Espera! Llevo días\nleyendo estos\fpapeles viejos..." },
        { "show_text", "Nadie recuerda ya\nqué se investigaba\faquí." },
        { "show_text", "¿Q-qué es ese\nPOKéMON que va\fcontigo...?" },
        { "emote", sci and "npc" or "player", "shock", 40 },
        { "show_text", "No..." },
        { "show_text", "¡Es imposible!\fMEWTWO." },
        { "show_text", "¡¿Cómo lo has\nconseguido?!\f¡No debería\nexistir!" },
        { "show_text", "¡Tengo que salir\nde aquí!" },
        { "mew_event:flee" },
      }, { npc = sci })
      return true
    end,

    scripts = {},

    talk = {
      TEXT_MEW_EVENT_SCIENTIST = {
        { "show_text", "¡No! ¡Aléjate de\nmí con eso!" },
        { "mew_event:flee" },
      },
      TEXT_MEW_EVENT_PAPERS_B = {
        { "check_flag", FLED }, { "jump_if_false", "sealed" },
        { "show_text", docs[3].text },
        { "mew_event:read_doc", 3 },
        { "show_text", docs[4].text },
        { "mew_event:read_doc", 4 },
        { "jump", "check" },
        { "label", "sealed" },
        { "show_text", "Un montón de\npapeles ordenados.\fNo parece que\nfalte nada." },
        { "jump", "end" },
        { "label", "check" },
        { "jump_if_false", "end" },
        { "mew_event:got_it" },
        { "label", "end" },
      },
      TEXT_MEW_EVENT_PAPERS_C = {
        { "check_flag", FLED }, { "jump_if_false", "sealed" },
        { "show_text", docs[5].text },
        { "mew_event:read_doc", 5 },
        { "show_text", docs[6].text },
        { "mew_event:read_doc", 6 },
        { "jump", "check" },
        { "label", "sealed" },
        { "show_text", "Un montón de\npapeles ordenados.\fNo parece que\nfalte nada." },
        { "jump", "end" },
        { "label", "check" },
        { "jump_if_false", "end" },
        { "mew_event:got_it" },
        { "label", "end" },
      },
      -- the vanilla 3F diary carries the first two documents once the event runs
      TEXT_POKEMONMANSION3F_DIARY = {
        { "check_flag", FLED }, { "jump_if_false", "vanilla" },
        { "show_text", docs[1].text },
        { "mew_event:read_doc", 1 },
        { "show_text", docs[2].text },
        { "mew_event:read_doc", 2 },
        { "jump_if_false", "end" },
        { "mew_event:got_it" },
        { "jump", "end" },
        { "label", "vanilla" },
        { "mew_event:base_diary" },
        { "label", "end" },
      },
    },
  })

  -- helper verbs that need the runner / MapScripts
  local MapScripts = require("src.script.MapScripts")
  mod.content.commands:register("mew_event:base_diary", {
    foreground = true,
    fn = function(ctx)
      local base = MapScripts.baseTalk(MANSION, "TEXT_POKEMONMANSION3F_DIARY")
      if not base then return end
      base(ctx.game, ctx.overworld, ctx.npc, function() ctx.runner:resume() end)
      ctx.runner:yield()
    end,
  })
  mod.content.commands:register("mew_event:approach", {
    foreground = true,
    fn = function(ctx)
      local ow = ctx.overworld
      local sci = ow and ow.npcByName and ow:npcByName(SCIENTIST)
      local p = ow and ow.player
      if sci and p then
        require("src.script.Commands").move_npc_to(ctx, sci.def.index,
          p.cellX, p.cellY + 1)
      end
    end,
  })
  mod.content.commands:register("mew_event:flee", {
    foreground = true,
    fn = function(ctx)
      require("src.script.Flags").set(ctx.save, FLED)
      local ow = ctx.overworld
      if ow then
        require("src.script.Commands").hide_object(ctx, MANSION, SCIENTIST)
        showPapers(ctx.game, ow)
      end
    end,
  })
  mod.content.commands:register("mew_event:got_it", {
    foreground = true,
    fn = function(ctx)
      if ctx.save.flags[DISCOVERED] then return end
      require("src.script.Flags").set(ctx.save, DISCOVERED)
      ctx.runner:run({
        { "show_text", "...\fMew. El ADN. MEWTWO.\fLa firma \"F.\"" },
        { "show_text", "El que escribió esto\nse marchó a cuidar\fPOKéMON..." },
        { "show_text", "Creo que sé quién\nfue." },
      }, {})
    end,
  })
end
