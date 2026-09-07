-- mew_event -- the secret post-game Mew quest (DESIGN.md / PLAN.md).
--   Stage 1  Pokemon Mansion 3F: the scientist + the six "F." documents
--   Stage 2  Mr. Fuji's house, Lavender Town: the evasive talk, the
--            condition, the revelation ("Yo soy F.") and the MAPA VIEJO
-- Stages 3-5 (Vermilion sailor / Isla Suprema map / Mew) are still to do.

local MANSION = "POKEMON_MANSION_3F"
local FUJI_HOUSE = "MR_FUJIS_HOUSE"

-- flags (MOD_ prefix per the project convention)
local FLED       = "MOD_MEW_SCIENTIST_FLED"
local DISCOVERED = "MOD_MEW_DISCOVERED"
local DOC_FLAG   = { "MOD_MEW_DOC1", "MOD_MEW_DOC2", "MOD_MEW_DOC3",
                     "MOD_MEW_DOC4", "MOD_MEW_DOC5", "MOD_MEW_DOC6" }
local FUJI_MYSTERY = "MOD_MEW_FUJI_MYSTERY"  -- 1st Fuji talk done
local OLD_MAP      = "MOD_MEW_OLD_MAP"       -- Fuji handed over the map
local MAPA_VIEJO   = "MAPA_VIEJO"            -- the key item

local ISLA          = "ISLA_SUPREMA"          -- the new island map id
local ISLA_UNLOCKED = "MOD_MEW_ISLA_UNLOCKED" -- the sailor has taken you once
local STATUE_SEEN   = "MOD_MEW_STATUE_SEEN"   -- talked to the statue once
local MEW_CAPTURED  = "MOD_MEW_CAPTURED"      -- the encounter has happened

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
      local C = require("src.script.Commands")
      C.show_text(ctx, "...\fMew. El ADN.\nMEWTWO.\fLa firma \"F.\"")
      C.show_text(ctx, "El que escribió\nesto se marchó a\fcuidar POKéMON...")
      C.show_text(ctx, "Creo que sé quién\nfue.")
    end,
  })

  -- ================================================================
  --  Stage 2 -- Mr. Fuji's house (Lavender Town)
  -- ================================================================

  -- the MAPA VIEJO key item (like every vanilla key item: price 0,
  -- keyItem, not tossable)
  mod.content.items:register(MAPA_VIEJO, {
    id = MAPA_VIEJO, name = "MAPA VIEJO", price = 0,
    keyItem = true, tossable = false,
  })

  mod.content.map_scripts:register(FUJI_HOUSE, {
    talk = {
      TEXT_MRFUJISHOUSE_MR_FUJI = {
        -- gate the whole quest branch behind Stage 1
        { "check_flag", DISCOVERED }, { "jump_if_false", "vanilla" },

        -- already has the map: a short send-off
        { "check_flag", OLD_MAP }, { "jump_if_false", "no_map_yet" },
        { "show_text", "El MAPA VIEJO\nseñala una isla\fmuy lejana." },
        { "show_text", "Quizás alguien\nacostumbrado al\fmar sepa cómo\nllegar hasta\fallí." },
        { "jump", "end" },

        { "label", "no_map_yet" },
        -- first talk done? -> check the condition for the second talk
        { "check_flag", FUJI_MYSTERY }, { "jump_if_false", "first_talk" },
        { "check_dex_owned", 150 }, { "jump_if_false", "not_yet" },
        { "mew_event:party_has", "MEWTWO" }, { "jump_if_false", "not_yet" },
        { "jump", "second_talk" },

        -- --- first conversation: evasive -----------------------------
        { "label", "first_talk" },
        { "face_player" },
        { "show_text", "¿F...?\fNo sé de quién\nme hablas." },
        { "show_text", "Hay cosas del\npasado que es\fmejor dejar\natrás." },
        { "show_text", "Hace muchos años\nviajé a lugares\fmuy lejanos.\fPero eso ya\npertenece al\fpasado." },
        { "show_text", "...Existe una isla\nque no aparece en\flos mapas que\nconocen los\fentrenadores." },
        { "show_text", "Allí encontré algo\nque cambió mi\fvida." },
        { "show_text", "Desde entonces he\nintentado olvidar\faquel lugar." },
        { "show_text", "¿Mew?\fNo.\fDe eso no puedo\nhablar." },
        { "show_text", "Hay cosas que un\nhombre debe\faprender a dejar\natrás." },
        { "show_text", "Sólo confiaría ese\nlugar a alguien\fque comprendiera\nlo que yo no\fcomprendí\nentonces." },
        { "show_text", "Alguien que no vea\na los POKéMON como\fsimples criaturas\nque coleccionar." },
        { "show_text", "Alguien cuyo deseo\nde conocerlos a\ftodos nazca del\nrespeto, y no de\fla ambición." },
        { "show_text", "Si algún día\nconozco a una\fpersona así...\fquizás pueda\nconfiarle lo que\fjuré ocultar." },
        { "set_flag", FUJI_MYSTERY },
        { "jump", "end" },

        -- --- condition not met yet ---------------------------------
        { "label", "not_yet" },
        { "face_player" },
        { "show_text", "Aún no.\fVuelve cuando los\nhayas conocido a\ftodos, uno por\funo..." },
        { "show_text", "...y cuando ese\nPOKéMON siga a tu\flado por voluntad\npropia." },
        { "jump", "end" },

        -- --- second conversation: recognition + revelation ----------
        { "label", "second_talk" },
        { "face_player" },
        { "show_text", "Mewtwo..." },
        { "show_text", "Así que finalmente\nte encontró." },
        { "show_text", "Durante tantos\naños me pregunté\fqué habría sido\nde él." },
        { "show_text", "Los has conocido a\ntodos. Uno por\nuno." },
        { "show_text", "Los has buscado en\ncada rincón de\fKANTO." },
        { "show_text", "Y aun así...\fhas conseguido\nalgo que nosotros\fnunca pudimos." },
        { "show_text", "Has conseguido que\nMewtwo encuentre\fsu propio camino." },
        { "show_text", "Ya no tiene\nsentido seguir\focultándolo." },
        { "show_text", "Sí.\fYo soy F." },
        { "show_text", "Yo estuve allí.\fYo encontré a Mew." },
        { "show_text", "Nunca revelé dónde\nestaba. Y jamás lo\fharé." },
        { "show_text", "Durante todos\nestos años guardé\fel secreto." },
        { "show_text", "No porque quisiera\nregresar." },
        { "show_text", "Sino porque temía\nque alguien\fvolviera a\nbuscarlo." },
        { "show_text", "Durante todos\nestos años también\fguardé este mapa." },
        { "give_item", MAPA_VIEJO, 1, "Recibiste el\nMAPA VIEJO." },
        { "show_text", "Ahora creo que\npuedo confiar en\fti." },
        { "show_text", "Si decides ir,\nrecuerda esto." },
        { "show_text", "No vayas a buscar\nun trofeo." },
        { "show_text", "Ve a conocer al\nPOKéMON que una\fvez tuve el\nprivilegio de\fconocer." },
        { "set_flag", OLD_MAP },
        { "jump", "end" },

        -- --- pre-Stage-1: the vanilla conversation, inlined ---------
        -- talk dispatch is single-winner, so this override replaces the
        -- engine rows outright; these mirror data/scripts/story.lua
        -- M.MR_FUJIS_HOUSE (flute give-then-print, then the has-it and
        -- pre-rescue lines).
        { "label", "vanilla" },
        { "face_player" },
        { "check_flag", "EVENT_GOT_POKE_FLUTE" }, { "jump_if_true", "v_flute_done" },
        { "check_flag", "EVENT_RESCUED_MR_FUJI" }, { "jump_if_false", "v_no_rescue" },
        { "show_text", "_MrFujisHouseMrFujiIThinkThisMayHelpYourQuestText" },
        { "give_item", "POKE_FLUTE", 1, false },
        { "show_text", "_MrFujisHouseMrFujiReceivedPokeFluteText" },
        { "set_flag", "EVENT_GOT_POKE_FLUTE" },
        { "show_text", "_MrFujisHouseMrFujiPokeFluteExplanationText" },
        { "jump", "end" },
        { "label", "v_flute_done" },
        { "show_text", "_MrFujisHouseMrFujiHasMyFluteHelpedYouText" },
        { "jump", "end" },
        { "label", "v_no_rescue" },
        { "show_text", "_MrFujisHouseMrFujiPokedexText" },

        { "label", "end" },
      },
    },
  })

  -- ================================================================
  --  Stage 3 -- the sailor at the Vermilion dock
  -- ================================================================
  -- The vanilla TEXT_VERMILIONCITY_SAILOR1 handler is a Lua function
  -- (S.S. ANNE ticket flow), so the branch this quest does not own is
  -- handed back to it through baseTalk, exactly like example_lost_parcel.
  mod.content.commands:register("mew_event:base_sailor", {
    foreground = true,
    fn = function(ctx)
      local base = MapScripts.baseTalk("VERMILION_CITY", "TEXT_VERMILIONCITY_SAILOR1")
      if not base then return end
      local runner = ctx.runner
      base(ctx.game, ctx.overworld, ctx.npc, function() runner:resume() end)
      runner:yield()
    end,
  })

  mod.content.commands:register("mew_event:sail_to_isla", {
    foreground = true,
    fn = function(ctx)
      require("src.script.Flags").set(ctx.save, ISLA_UNLOCKED)
      require("src.script.Commands").warp(ctx, ISLA, 6, 24, "up")
    end,
  })

  mod.content.map_scripts:register("VERMILION_CITY", {
    talk = {
      TEXT_VERMILIONCITY_SAILOR1 = {
        -- only react to the map once Fuji has handed it over
        { "check_flag", OLD_MAP }, { "jump_if_false", "vanilla" },
        { "check_item", MAPA_VIEJO }, { "jump_if_false", "vanilla" },
        { "face_player" },
        { "check_flag", ISLA_UNLOCKED }, { "jump_if_true", "again" },
        -- first time: he studies the map
        { "show_text", "¿Qué es esto?" },
        { "show_text", "Hace muchos años\nque no veía uno de\festos." },
        { "show_text", "¿Quieres ir\nallí?" },
        { "show_text", "No sé qué\nencontrarás..." },
        { "show_text", "Pero si el viejo\nFUJI te entregó\fese mapa, supongo\nque tendrá sus\frazones." },
        { "choice", { "IR", "AHORA NO" } },
        { "jump_if_false", "end" },
        { "mew_event:sail_to_isla" },
        { "jump", "end" },
        { "label", "again" },
        { "show_text", "¿De vuelta a la\nisla?" },
        { "choice", { "SÍ", "NO" } },
        { "jump_if_false", "end" },
        { "mew_event:sail_to_isla" },
        { "jump", "end" },
        { "label", "vanilla" },
        { "mew_event:base_sailor" },
        { "label", "end" },
      },
    },
  })

  -- ================================================================
  --  Stage 4 + 5 -- Isla Suprema (the island map, sign, statue, Mew)
  -- ================================================================
  mod.content.maps:register(ISLA, readTable(mod, "data/isla_suprema.lua"))

  mod.content.commands:register("mew_event:sail_home", {
    foreground = true,
    fn = function(ctx)
      require("src.script.Commands").warp(ctx, "VERMILION_CITY", 18, 28, "up")
    end,
  })

  -- the ancient statue: first touch = flavour, second = the encounter
  mod.content.commands:register("mew_event:mew_battle", {
    foreground = true,
    fn = function(ctx)
      local C = require("src.script.Commands")
      C.play_cry(ctx, "MEW", true)
      C.static_battle(ctx, "MEW", 60, MEW_CAPTURED)
    end,
  })

  mod.content.map_scripts:register(ISLA, {
    onEnter = function(game, ow)
      -- one eerie theme for the whole island (data.audio is absent in
      -- this build, so this is a no-op until audio data is regenerated)
      pcall(function()
        require("src.core.Music").play(game.data, "Music_Lavender", nil,
          { reason = "map", mapId = ISLA })
      end)
    end,
    talk = {
      TEXT_ISLA_SUPREMA_SAILOR = {
        { "face_player" },
        { "show_text", "Te espero aquí." },
        { "show_text", "¿Volvemos a\nCIUDAD CARMÍN?" },
        { "choice", { "SÍ", "TODAVÍA NO" } },
        { "jump_if_false", "stay" },
        { "mew_event:sail_home" },
        { "jump", "end" },
        { "label", "stay" },
        { "show_text", "Tómate tu tiempo." },
        { "label", "end" },
      },
      TEXT_ISLA_SUPREMA_SIGN = {
        { "show_text", "A quien encuentre\neste lugar:" },
        { "show_text", "No intentes\ncapturar aquello\fque vive aquí." },
        { "show_text", "Algunas cosas\ndeben ser\fconocidas sin\nnecesidad de ser\fposeídas." },
        { "show_text", "     - F." },
      },
      TEXT_ISLA_SUPREMA_STATUE = {
        { "check_flag", MEW_CAPTURED }, { "jump_if_true", "after" },
        { "check_flag", STATUE_SEEN }, { "jump_if_true", "second" },
        -- first interaction
        { "show_text", "Es una estatua muy\nantigua." },
        { "show_text", "No reconoces al\nPOKéMON que\frepresenta." },
        { "set_flag", STATUE_SEEN },
        { "jump", "end" },
        -- second interaction: the encounter
        { "label", "second" },
        { "show_text", "La estatua parece\nmirarte." },
        { "show_text", "..." },
        { "show_text", "Algo se mueve\ndetrás de ti." },
        { "mew_event:mew_battle" },
        { "jump", "end" },
        { "label", "after" },
        { "show_text", "La estatua sigue\nahí, en silencio." },
        { "label", "end" },
      },
    },
  })
end
