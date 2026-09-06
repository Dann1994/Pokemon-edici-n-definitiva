-- FAIRY / STEEL / DARK types + the full Gen 6 type chart.
--
-- `chart[ATTACKER][DEFENDER]` is the engine's x10 multiplier:
--   20 = super effective, 5 = not very effective, 0 = immune.
-- Neutral (x1) pairs are omitted.  main.lua overrides the vanilla row
-- where one exists and registers a new one otherwise; pairs in
-- `neutralized` are non-neutral in Gen 1 but neutral in Gen 6 and get
-- removed.
--
-- Gen 1 PSYCHIC's type id is PSYCHIC_TYPE; every other type is its bare
-- name.

return {
  types = {
    FAIRY = { name = "FAIRY", category = "special" },
    STEEL = { name = "STEEL", category = "physical" },
    DARK  = { name = "DARK",  category = "physical" },
  },

  chart = {
    NORMAL = { ROCK = 5, GHOST = 0, STEEL = 5 },
    FIRE = { FIRE = 5, WATER = 5, GRASS = 20, ICE = 20, BUG = 20, ROCK = 5,
             DRAGON = 5, STEEL = 20 },
    WATER = { FIRE = 20, WATER = 5, GRASS = 5, GROUND = 20, ROCK = 20,
              DRAGON = 5 },
    ELECTRIC = { WATER = 20, ELECTRIC = 5, GRASS = 5, GROUND = 0, FLYING = 20,
                 DRAGON = 5 },
    GRASS = { FIRE = 5, WATER = 20, GRASS = 5, POISON = 5, GROUND = 20,
              FLYING = 5, BUG = 5, ROCK = 20, DRAGON = 5, STEEL = 5 },
    ICE = { FIRE = 5, WATER = 5, GRASS = 20, ICE = 5, GROUND = 20, FLYING = 20,
            DRAGON = 20, STEEL = 5 },
    FIGHTING = { NORMAL = 20, ICE = 20, POISON = 5, FLYING = 5,
                 PSYCHIC_TYPE = 5, BUG = 5, ROCK = 20, GHOST = 0, DARK = 20,
                 STEEL = 20, FAIRY = 5 },
    POISON = { GRASS = 20, POISON = 5, GROUND = 5, ROCK = 5, GHOST = 5,
               STEEL = 0, FAIRY = 20 },
    GROUND = { FIRE = 20, ELECTRIC = 20, GRASS = 5, POISON = 20, FLYING = 0,
               BUG = 5, ROCK = 20, STEEL = 20 },
    FLYING = { ELECTRIC = 5, GRASS = 20, FIGHTING = 20, BUG = 20, ROCK = 5,
               STEEL = 5 },
    PSYCHIC_TYPE = { FIGHTING = 20, POISON = 20, PSYCHIC_TYPE = 5, DARK = 0,
                     STEEL = 5 },
    BUG = { FIRE = 5, GRASS = 20, FIGHTING = 5, POISON = 5, FLYING = 5,
            PSYCHIC_TYPE = 20, GHOST = 5, DARK = 20, STEEL = 5, FAIRY = 5 },
    ROCK = { FIRE = 20, ICE = 20, FIGHTING = 5, GROUND = 5, FLYING = 20,
             BUG = 20, STEEL = 5 },
    GHOST = { NORMAL = 0, PSYCHIC_TYPE = 20, GHOST = 20, DARK = 5 },
    DRAGON = { DRAGON = 20, STEEL = 5, FAIRY = 0 },
    DARK = { FIGHTING = 5, PSYCHIC_TYPE = 20, GHOST = 20, DARK = 5, FAIRY = 5 },
    STEEL = { FIRE = 5, WATER = 5, ELECTRIC = 5, ICE = 20, ROCK = 20,
              STEEL = 5, FAIRY = 20 },
    FAIRY = { FIRE = 5, FIGHTING = 20, POISON = 5, DRAGON = 20, DARK = 20,
              STEEL = 5 },
  },

  -- Gen 1 rows that Gen 6 makes neutral.
  neutralized = { "POISON>BUG" },

  -- Canonical Gen 6 typings for Kanto species.
  species = {
    CLEFAIRY   = { "FAIRY" },
    CLEFABLE   = { "FAIRY" },
    JIGGLYPUFF = { "NORMAL", "FAIRY" },
    WIGGLYTUFF = { "NORMAL", "FAIRY" },
    MR_MIME    = { "PSYCHIC_TYPE", "FAIRY" },
    MAGNEMITE  = { "ELECTRIC", "STEEL" },
    MAGNETON   = { "ELECTRIC", "STEEL" },
  },
}
