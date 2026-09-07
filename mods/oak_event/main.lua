-- oak_event -- the secret post-game "Professor Oak challenge" (DESIGN.md).
--
-- With the League beaten and the Kanto Pokedex complete, a chain of
-- clues (the rival in the lab -> Bill -> the Cinnabar lab -> Lance at
-- the closed League) leads to Prof. Oak waiting on Route 1, where he
-- reveals he was once Champion and challenges the player.  Winning rolls
-- the credits and returns the world to normal.
--
-- The battle itself already exists: OPP_PROF_OAK (cut content, 3 parties
-- by starter) + assets/generated/battle/trainers/prof.oak.png, wired by
-- data/scripts/pallet_town.lua.  This mod wraps the story around it.

local BEATEN = "EVENT_BEAT_PROF_OAK"            -- vanilla flag = event done
local RIVAL_TOLD    = "MOD_OAK_RIVAL_TOLD"
local BILL_TOLD     = "MOD_OAK_BILL_TOLD"
local CINNABAR_TOLD = "MOD_OAK_CINNABAR_TOLD"
local LANCE_TOLD    = "MOD_OAK_LANCE_TOLD"

local LAB    = "OAKS_LAB"
local PALLET = "PALLET_TOWN"
local PLATEAU = "INDIGO_PLATEAU"
local ROUTE1 = "ROUTE_1"
local CINNABAR_ROOM = "CINNABAR_LAB_METRONOME_ROOM"
local BILL_HOUSE = "BILLS_HOUSE"

local RIVAL = "OAK_EVENT_RIVAL"
local LANCE = "OAK_EVENT_LANCE"
local OAK   = "OAK_EVENT_OAK"

local function dexOwned(save)
  local n = 0
  for _ in pairs(save.pokedex and save.pokedex.owned or {}) do n = n + 1 end
  return n
end

-- the hunt is on: League beaten, dex complete, Oak not yet beaten
local function huntActive(save)
  local f = save.flags or {}
  return f.EVENT_BEAT_CHAMPION_RIVAL and not f[BEATEN] and dexOwned(save) >= 150
end

return function(mod)
  local C = require("src.script.Commands")
  local Flags = require("src.script.Flags")

  local function ctxFor(game, ow)
    return { game = game, save = game.save, overworld = ow }
  end

  -- ---- add the three hidden event NPCs -----------------------------
  local function patchObjects(mapId, list)
    local base = mod.content.maps:get(mapId)
    local objs = {}
    for i, o in ipairs(base.objects or {}) do
      objs[i] = {}
      for k, v in pairs(o) do objs[i][k] = v end
    end
    for _, e in ipairs(list) do
      e.index = #objs + 1
      e.hidden = true
      objs[#objs + 1] = e
    end
    mod.content.maps:patch(mapId, { objects = objs })
  end

  patchObjects(LAB, { { name = RIVAL, sprite = "SPRITE_BLUE", movement = "STAY",
    range = "NONE", x = 4, y = 4, text = "TEXT_OAK_EVENT_RIVAL" } })
  patchObjects(PLATEAU, { { name = LANCE, sprite = "SPRITE_LANCE", movement = "STAY",
    range = "NONE", x = 9, y = 6, text = "TEXT_OAK_EVENT_LANCE" } })
  patchObjects(ROUTE1, { { name = OAK, sprite = "SPRITE_OAK", movement = "STAY",
    range = "NONE", x = 14, y = 30, text = "TEXT_OAK_EVENT_OAK" } })

  -- ---- verbs -----------------------------------------------------
  -- the battle: Oak's counter-party mirrors the rival's (beats the
  -- player's starter), exactly like data/scripts/pallet_town.lua
  mod.content.commands:register("oak_event:battle", {
    foreground = true,
    fn = function(ctx)
      local f = ctx.save.flags or {}
      local party = 1                                   -- BLASTOISE (chose Charmander)
      if f.EVENT_CHOSE_BULBASAUR then party = 3         -- CHARIZARD
      elseif f.EVENT_CHOSE_SQUIRTLE then party = 2 end  -- VENUSAUR
      C.start_battle(ctx, "trainer", "OPP_PROF_OAK", party)
    end,
  })

  -- credits + heal + back to the bedroom + autosave + soft reset to title
  -- (the exact path the Champion fight uses).  Setting BEATEN first makes
  -- every onEnter below stop showing the event NPCs and unblock the League.
  mod.content.commands:register("oak_event:finish", {
    foreground = true,
    fn = function(ctx)
      Flags.set(ctx.save, BEATEN)
      C.record_hall_of_fame(ctx)
    end,
  })

  -- Lance turns the player away from the closed League
  mod.content.commands:register("oak_event:league_closed", {
    foreground = true,
    fn = function(ctx)
      C.show_text(ctx, "LANCE: ¿Vienes a\ndesafiar a la\fLIGA?")
      C.show_text(ctx, "Me temo que\ntendrás que\fesperar.")
      C.show_text(ctx, "La LIGA POKéMON\nestá cerrada\ftemporalmente.")
      C.show_text(ctx, "Estamos con unos\ntrabajos de\fmantenimiento.")
      local ow = ctx.overworld
      if ow and ow.player and ow.scriptMove then
        ow:scriptMove(ow.player, "down", 1, nil, { collide = true })
      end
    end,
  })

  -- ================================================================
  --  Stage 1 -- Oak's lab: Oak is away, the rival is inside
  -- ================================================================
  mod.content.map_scripts:register(LAB, {
    onEnter = function(game, ow)
      local ctx = ctxFor(game, ow)
      if huntActive(game.save) then
        C.hide_object(ctx, LAB, "OAKSLAB_OAK1")
        C.hide_object(ctx, LAB, "OAKSLAB_OAK2")
        C.show_object(ctx, LAB, RIVAL)
      elseif game.save.flags[BEATEN] then
        C.hide_object(ctx, LAB, RIVAL)
        C.show_object(ctx, LAB, "OAKSLAB_OAK1")
      end
    end,
    talk = {
      TEXT_OAK_EVENT_RIVAL = {
        { "face_player" },
        { "check_flag", RIVAL_TOLD }, { "jump_if_true", "again" },
        { "show_text", "¡Ah, ahí estás!" },
        { "show_text", "¿Ya viste tu\nPOKéDEX?" },
        { "show_text", "El abuelo se\nenteró de que\fconseguiste\nregistrar a los\f150 POKéMON." },
        { "show_text", "Está realmente\nimpresionado." },
        { "show_text", "Quería hablar\ncontigo." },
        { "show_text", "Pero cuando\nllegué, ya se\fhabía marchado." },
        { "show_text", "¿Que dónde está?\fNi idea." },
        { "show_text", "Sólo me dijo que\niba a estar...\f\"donde todo\ncomenzó\"." },
        { "show_text", "No sé qué quiso\ndecir con eso." },
        { "show_text", "Algo de sus viejas\nhistorias, supongo." },
        { "show_text", "Ahora que lo\npienso..." },
        { "show_text", "Quizá esté\nvisitando a su\famigo el\nPOKéMANíACO." },
        { "set_flag", RIVAL_TOLD },
        { "jump", "end" },
        { "label", "again" },
        { "show_text", "\"Donde todo\ncomenzó\"...\fy su amigo el\nPOKéMANíACO." },
        { "show_text", "Eso fue lo único\nque dijo." },
        { "label", "end" },
      },
    },
  })

  -- ================================================================
  --  Stage 1b -- Pallet Town: Oak is not out front either
  -- ================================================================
  mod.content.map_scripts:register(PALLET, {
    onEnter = function(game, ow)
      local ctx = ctxFor(game, ow)
      if huntActive(game.save) then
        C.hide_object(ctx, PALLET, "PALLETTOWN_OAK")
      elseif game.save.flags[BEATEN] then
        C.show_object(ctx, PALLET, "PALLETTOWN_OAK")
      end
    end,
  })

  -- ================================================================
  --  Stage 2 -- Bill (his house on Route 25)
  -- ================================================================
  mod.content.map_scripts:register(BILL_HOUSE, {
    talk = {
      -- BILLSHOUSE_BILL1's object text is TEXT_BILLSHOUSE_BILL_SS_TICKET
      TEXT_BILLSHOUSE_BILL_SS_TICKET = {
        { "check_flag", "EVENT_GOT_SS_TICKET" }, { "jump_if_false", "vanilla" },
        { "check_flag", RIVAL_TOLD }, { "jump_if_false", "vanilla" },
        { "check_flag", BEATEN }, { "jump_if_true", "vanilla" },
        { "face_player" },
        { "check_flag", BILL_TOLD }, { "jump_if_true", "remind" },
        { "show_text", "¿OAK?\fSí, pasó por aquí\nhace poco." },
        { "show_text", "Estuvimos hablando\nun buen rato." },
        { "show_text", "Me preguntó cosas\nsobre mis\finvestigaciones." },
        { "show_text", "Últimamente le da\npor revisar\ftrabajos antiguos." },
        { "show_text", "¿Que a dónde fue?" },
        { "show_text", "Dijo que tenía que\nir a revisar unos\fdatos." },
        { "show_text", "Si lo conozco,\nhabrá ido al\flaboratorio más\ngrande de todo\fKANTO." },
        { "show_text", "Allí tienen\ninstalaciones que\fnosotros sólo\npodemos soñar." },
        { "set_flag", BILL_TOLD },
        { "jump", "end" },
        { "label", "remind" },
        { "show_text", "El laboratorio más\ngrande de todo\fKANTO. Ya sabes\ncuál." },
        { "jump", "end" },
        -- --- the vanilla S.S. TICKET conversation, inlined ---------
        { "label", "vanilla" },
        { "face_player" },
        { "check_flag", "EVENT_GOT_SS_TICKET" }, { "jump_if_true", "v_got" },
        { "show_text", "_BillsHouseBillThankYouText" },
        { "give_item", "S_S_TICKET", 1, false, "_SSTicketNoRoomText" },
        { "show_text", "_SSTicketReceivedText" },
        { "set_flag", "EVENT_GOT_SS_TICKET" },
        { "show_object", "CERULEAN_CITY", "CERULEANCITY_GUARD1" },
        { "hide_object", "CERULEAN_CITY", "CERULEANCITY_GUARD2" },
        { "show_text", "_BillsHouseBillWhyDontYouGoInsteadOfMeText" },
        { "jump", "end" },
        { "label", "v_got" },
        { "show_text", "_BillsHouseBillWhyDontYouGoInsteadOfMeText" },
        { "label", "end" },
      },
    },
  })

  -- ================================================================
  --  Stage 3 -- the Cinnabar lab (Metronome room scientist)
  -- ================================================================
  mod.content.map_scripts:register(CINNABAR_ROOM, {
    talk = {
      TEXT_CINNABARLABMETRONOMEROOM_SCIENTIST2 = {
        { "check_flag", BILL_TOLD }, { "jump_if_false", "vanilla" },
        { "check_flag", BEATEN }, { "jump_if_true", "vanilla" },
        { "face_player" },
        { "check_flag", CINNABAR_TOLD }, { "jump_if_true", "remind" },
        { "show_text", "¡Oh! ¡Eres tú!" },
        { "show_text", "El profesor OAK\nhabla mucho de tus\fprogresos." },
        { "show_text", "¿OAK?\fSí, vino hace\npoco." },
        { "show_text", "Estuvo revisando\nregistros\fantiguos." },
        { "show_text", "Últimamente parece\npensar mucho en\fsus años de\njuventud." },
        { "show_text", "¿No te lo contó?" },
        { "show_text", "Antes de ser\nprofesor, OAK fue\fun entrenador\nbastante famoso." },
        { "show_text", "Según los viejos\nregistros, llegó\fmuy lejos." },
        { "show_text", "Me extraña verlo\ninteresado otra\fvez en esas\ncosas." },
        { "show_text", "Siempre pensé que\nhabía dejado atrás\flos combates." },
        { "show_text", "Quizá sólo busca\nun poco de\femoción." },
        { "show_text", "Y si uno quiere\nvolver a sentir\flo de los combates\nmás importantes..." },
        { "show_text", "¿qué mejor lugar\nque donde se miden\flos mejores\nentrenadores de\fKANTO?" },
        { "set_flag", CINNABAR_TOLD },
        { "jump", "end" },
        { "label", "remind" },
        { "show_text", "Los combates más\nimportantes de\fKANTO. Ya sabes\ndónde se libran." },
        { "jump", "end" },
        { "label", "vanilla" },
        { "show_text", "_CinnabarLabMetronomeRoomScientist2Text" },
        { "label", "end" },
      },
    },
  })

  -- ================================================================
  --  Stage 4 -- Indigo Plateau: Lance, and the League is closed
  -- ================================================================
  local function lanceActive(save)
    local f = save.flags or {}
    return f[CINNABAR_TOLD] and not f[BEATEN]
  end

  mod.content.map_scripts:register(PLATEAU, {
    onEnter = function(game, ow)
      local ctx = ctxFor(game, ow)
      if lanceActive(game.save) then
        C.show_object(ctx, PLATEAU, LANCE)
      elseif game.save.flags[BEATEN] then
        C.hide_object(ctx, PLATEAU, LANCE)
      end
    end,
    -- the entrance channel is cells x 9-10, y <= 6 (the two warps to the
    -- lobby sit at y = 5); Lance stands at (9,6)
    onStep = function(game, ow, x, y)
      if not lanceActive(game.save) then return false end
      if y > 6 or (x ~= 9 and x ~= 10) then return false end
      ow.runner:run({ { "oak_event:league_closed" } }, {})
      return true
    end,
    talk = {
      TEXT_OAK_EVENT_LANCE = {
        { "face_player" },
        { "check_flag", LANCE_TOLD }, { "jump_if_true", "again" },
        { "show_text", "LANCE: ¿El\nprofesor OAK?" },
        { "show_text", "No, no lo he\nvisto." },
        { "show_text", "Aunque\nconociéndolo..." },
        { "show_text", "seguro que está\nhaciendo trabajo\fde campo." },
        { "show_text", "Nunca fue de\nquedarse encerrado\fen un laboratorio." },
        { "show_text", "Si anda por el\ncampo, estará\fbuscando POKéMON\nen alguna ruta." },
        { "show_text", "Yo probaría cerca\nde PUEBLO PALETA." },
        { "set_flag", LANCE_TOLD },
        { "jump", "end" },
        { "label", "again" },
        { "show_text", "Trabajo de campo,\nen una ruta cerca\fde PUEBLO PALETA." },
        { "label", "end" },
      },
    },
  })

  -- ================================================================
  --  Stage 5 -- Route 1: Oak, the revelation, the battle, the credits
  -- ================================================================
  local function oakActive(save)
    local f = save.flags or {}
    return f[LANCE_TOLD] and not f[BEATEN]
  end

  mod.content.map_scripts:register(ROUTE1, {
    onEnter = function(game, ow)
      local ctx = ctxFor(game, ow)
      if oakActive(game.save) then
        C.show_object(ctx, ROUTE1, OAK)
      elseif game.save.flags[BEATEN] then
        C.hide_object(ctx, ROUTE1, OAK)
      end
    end,
    talk = {
      TEXT_OAK_EVENT_OAK = {
        { "face_player" },
        { "show_text", "Ah...\fHas llegado." },
        { "show_text", "Me preguntaba\ncuánto tardarías\fen encontrarme." },
        { "show_text", "Supongo que\nnecesitaba una\fúltima excusa para\nrecorrer estos\flugares." },
        { "show_text", "Pero quería que\nllegaras hasta\faquí por tus\npropios medios." },
        { "show_text", "¿Recuerdas este\ncamino?" },
        { "show_text", "Aquí comienza el\nviaje de todo\fentrenador." },
        { "show_text", "Y, aunque no lo\ncreas...\ftambién comenzó\nel mío." },
        { "show_text", "Antes de\nconvertirme en\fprofesor, yo\ntambién fui\fentrenador." },
        { "show_text", "Recorrí KANTO." },
        { "show_text", "Combatí contra\nmuchos\fentrenadores." },
        { "show_text", "Y llegué hasta la\nLIGA." },
        { "show_text", "Incluso fui\ncampeón." },
        { "show_text", "Pensé que llegar a\nla cima sería el\fmomento más\nimportante de mi\fvida." },
        { "show_text", "Y por un tiempo lo\nfue." },
        { "show_text", "Pero comprendí que\nno quería seguir\fcombatiendo sólo\npara demostrar que\fera el mejor." },
        { "show_text", "Quería entender a\nlos POKéMON." },
        { "show_text", "Por qué\nevolucionan." },
        { "show_text", "Por qué confían en\nnosotros." },
        { "show_text", "Qué los hace\ndiferentes." },
        { "show_text", "Así que dejé atrás\nla vida de\fentrenador." },
        { "show_text", "Entonces\napareciste tú." },
        { "show_text", "Te vi empezar tu\nviaje." },
        { "show_text", "Te vi enfrentarte\na tu rival." },
        { "show_text", "Te vi recorrer\nKANTO." },
        { "show_text", "Y te vi conseguir\nalgo que yo nunca\fhice." },
        { "show_text", "Conociste a todos\nlos POKéMON.\fLos 150." },
        { "show_text", "Durante años pensé\nque había elegido\fbien." },
        { "show_text", "Investigador en\nlugar de\fentrenador." },
        { "show_text", "Pero al ver tu\nviaje..." },
        { "show_text", "recordé cuánto\ndisfrutaba\faquello." },
        { "show_text", "La emoción.\fLa incertidumbre." },
        { "show_text", "No saber quién\nsería el siguiente\frival." },
        { "show_text", "Poner a prueba a\nun POKéMON y\fconfiar en él." },
        { "show_text", "No quiero volver a\nser campeón." },
        { "show_text", "Ni demostrar que\nsoy mejor que tú." },
        { "show_text", "Sólo quiero\nrecordar cómo se\fsentía." },
        { "show_text", "Y creo que tú\ntienes la culpa." },
        { "show_text", "Así que...\f¿qué dices?" },
        { "show_text", "¿Te gustaría\ncombatir contra un\fviejo entrenador?" },
        { "oak_event:battle" },
        { "check_battle_result", "win" }, { "jump_if_false", "end" },
        { "set_flag", BEATEN },
        { "show_text", "¡Ja!" },
        { "show_text", "Había olvidado lo\nbien que se siente\festo." },
        { "show_text", "Gracias.\fDe verdad." },
        { "show_text", "Pensé que esa\nparte de mi vida\fhabía terminado." },
        { "show_text", "Pero quizá sólo la\nhabía dejado de\flado." },
        { "show_text", "No abandonaré mis\ninvestigaciones." },
        { "show_text", "Pero quizá pueda\npermitirme algún\fcombate de vez en\ncuando." },
        { "show_text", "Gracias por\nrecordármelo." },
        { "oak_event:finish" },
        { "label", "end" },
      },
    },
  })
end
