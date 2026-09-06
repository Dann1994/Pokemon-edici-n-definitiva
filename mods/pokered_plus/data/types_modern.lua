-- New types FAIRY / STEEL / DARK and their type-chart interactions.
--
-- Multipliers are the engine's x10 scale: 20 = super effective, 5 = not
-- very effective, 0 = immune.  Neutral (10) rows are omitted -- the chart
-- defaults to neutral for any pair with no row.
--
-- Only ADDITIVE rows are here: interactions that involve at least one of
-- the three new types.  Rewriting vanilla Gen 1 matchups (Bug<->Poison,
-- Ice->Fire, Ghost<->Psychic, the Gen 1 chart quirks) is a separate,
-- balance-affecting decision -- see BACKLOG.md 2.5 and `modernTypeChart`.

return {
  -- category is the fallback the engine uses only when a move has no
  -- category of its own; with the phys/spec split every damaging move
  -- carries one, so these mostly matter for display grouping.
  types = {
    FAIRY = { name = "FAIRY", category = "special" },
    STEEL = { name = "STEEL", category = "physical" },
    DARK  = { name = "DARK",  category = "physical" },
  },

  -- "ATTACKER>DEFENDER" -> x10 multiplier
  matchups = {
    -- ---- FAIRY offence
    ["FAIRY>FIGHTING"] = 20,
    ["FAIRY>DRAGON"]   = 20,
    ["FAIRY>DARK"]     = 20,
    ["FAIRY>FIRE"]     = 5,
    ["FAIRY>POISON"]   = 5,
    ["FAIRY>STEEL"]    = 5,
    -- ---- FAIRY defence
    ["FIGHTING>FAIRY"] = 5,
    ["BUG>FAIRY"]      = 5,
    ["DARK>FAIRY"]     = 5,
    ["POISON>FAIRY"]   = 20,
    ["STEEL>FAIRY"]    = 20,
    ["DRAGON>FAIRY"]   = 0,

    -- ---- STEEL offence
    ["STEEL>ICE"]      = 20,
    ["STEEL>ROCK"]     = 20,
    ["STEEL>FAIRY"]    = 20,
    ["STEEL>FIRE"]     = 5,
    ["STEEL>WATER"]    = 5,
    ["STEEL>ELECTRIC"] = 5,
    ["STEEL>STEEL"]    = 5,
    -- ---- STEEL defence
    ["NORMAL>STEEL"]       = 5,
    ["GRASS>STEEL"]        = 5,
    ["ICE>STEEL"]          = 5,
    ["FLYING>STEEL"]       = 5,
    ["PSYCHIC_TYPE>STEEL"] = 5,
    ["BUG>STEEL"]          = 5,
    ["ROCK>STEEL"]         = 5,
    ["DRAGON>STEEL"]       = 5,
    ["FAIRY>STEEL"]        = 5,
    ["FIRE>STEEL"]         = 20,
    ["FIGHTING>STEEL"]     = 20,
    ["GROUND>STEEL"]       = 20,
    ["POISON>STEEL"]       = 0,

    -- ---- DARK offence
    ["DARK>PSYCHIC_TYPE"] = 20,
    ["DARK>GHOST"]        = 20,
    ["DARK>FIGHTING"]     = 5,
    ["DARK>DARK"]         = 5,
    ["DARK>FAIRY"]        = 5,
    -- ---- DARK defence
    ["FIGHTING>DARK"]     = 20,
    ["BUG>DARK"]          = 20,
    ["FAIRY>DARK"]        = 20,
    ["GHOST>DARK"]        = 5,
    ["PSYCHIC_TYPE>DARK"] = 0,
  },

  -- Canonical modern typings for Kanto species.  REVIEW: confirm you want
  -- the pure-Fairy retype for the Clefairy line rather than Normal/Fairy.
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
