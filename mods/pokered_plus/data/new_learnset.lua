-- Which of the 151 Kanto species learn the new DARK / FAIRY / STEEL moves,
-- and at what level. This mod's own design (the levels are not any source
-- game's) -- see BACKLOG.md. Only species that already exist in this
-- Pokedex; nothing from Gen 2/3 was added.
return {
  -- DARK
  RATICATE = { { move = "PURSUIT", level = 20 }, { move = "THIEF", level = 32 } },
  FEAROW = { { move = "PURSUIT", level = 24 } },
  ARBOK = { { move = "FEINT_ATTACK", level = 26 }, { move = "CRUNCH", level = 40 } },
  MEOWTH = { { move = "FEINT_ATTACK", level = 20 }, { move = "THIEF", level = 28 },
             { move = "TAUNT", level = 36 } },
  PERSIAN = { { move = "FEINT_ATTACK", level = 20 }, { move = "TAUNT", level = 36 } },
  GOLBAT = { { move = "PURSUIT", level = 30 } },
  GENGAR = { { move = "TAUNT", level = 38 }, { move = "CRUNCH", level = 45 } },

  -- FAIRY
  CLEFAIRY = { { move = "DISARMING_VOICE", level = 12 }, { move = "DRAINING_KISS", level = 24 },
               { move = "DAZZLING_GLEAM", level = 32 }, { move = "MOONBLAST", level = 40 } },
  CLEFABLE = { { move = "DISARMING_VOICE", level = 12 }, { move = "DRAINING_KISS", level = 24 },
               { move = "DAZZLING_GLEAM", level = 32 }, { move = "MOONBLAST", level = 40 },
               { move = "PLAY_ROUGH", level = 48 } },
  JIGGLYPUFF = { { move = "DISARMING_VOICE", level = 10 }, { move = "DRAINING_KISS", level = 22 },
                 { move = "PLAY_ROUGH", level = 30 }, { move = "DAZZLING_GLEAM", level = 38 } },
  WIGGLYTUFF = { { move = "DISARMING_VOICE", level = 10 }, { move = "DRAINING_KISS", level = 22 },
                 { move = "PLAY_ROUGH", level = 30 }, { move = "DAZZLING_GLEAM", level = 38 },
                 { move = "MOONBLAST", level = 46 } },
  EEVEE = { { move = "DISARMING_VOICE", level = 18 } },

  -- STEEL
  CHARMELEON = { { move = "METAL_CLAW", level = 24 } },
  CHARIZARD = { { move = "METAL_CLAW", level = 24 }, { move = "STEEL_WING", level = 42 },
                { move = "IRON_TAIL", level = 50 } },
  WARTORTLE = { { move = "IRON_DEFENSE", level = 28 } },
  BLASTOISE = { { move = "IRON_DEFENSE", level = 28 } },
  SANDSHREW = { { move = "METAL_CLAW", level = 20 } },
  SANDSLASH = { { move = "METAL_CLAW", level = 20 }, { move = "IRON_TAIL", level = 38 } },
  NIDOQUEEN = { { move = "IRON_DEFENSE", level = 38 } },
  NIDOKING = { { move = "IRON_TAIL", level = 40 } },
  ONIX = { { move = "IRON_TAIL", level = 30 }, { move = "IRON_DEFENSE", level = 45 } },
  MAGNEMITE = { { move = "METAL_SOUND", level = 18 }, { move = "IRON_DEFENSE", level = 30 } },
  MAGNETON = { { move = "METAL_SOUND", level = 18 }, { move = "IRON_DEFENSE", level = 30 } },
}
