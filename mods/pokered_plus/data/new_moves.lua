-- New DARK / FAIRY / STEEL moves for pokered_plus.
--
-- Mechanically these use the same move_effects the Gen 1 engine already
-- runs (see src/battle/Damage.lua), each picked to match a real Gen 1
-- move's shape (damaging + side effect, or a 0-power self-buff status
-- move) so the combo is one the engine has already exercised. Power / PP /
-- accuracy are this mod's own numbers, not the source games' -- see
-- BACKLOG.md and the mod README for why.
--
-- retype: existing moves that just change type (BITE was NORMAL).
-- moves: brand-new move records, registered fresh (moves:register).
return {
  retype = {
    BITE = "DARK",
  },
  moves = {
    -- ---------------------------------------------------------- DARK
    PURSUIT = { name = "Pursuit", type = "DARK", category = "physical",
      power = 45, pp = 16, accuracy = 100, effect = "NO_ADDITIONAL_EFFECT" },
    THIEF = { name = "Thief", type = "DARK", category = "physical",
      power = 35, pp = 12, accuracy = 100, effect = "NO_ADDITIONAL_EFFECT" },
    CRUNCH = { name = "Crunch", type = "DARK", category = "physical",
      power = 75, pp = 12, accuracy = 95, effect = "SPECIAL_DOWN_SIDE_EFFECT" },
    FEINT_ATTACK = { name = "Feint Attack", type = "DARK", category = "physical",
      power = 55, pp = 18, accuracy = 100, effect = "SWIFT_EFFECT" },
    TAUNT = { name = "Taunt", type = "DARK", category = "status",
      power = 0, pp = 16, accuracy = 100, effect = "DEFENSE_DOWN1_EFFECT" },
    -- ---------------------------------------------------------- FAIRY
    DISARMING_VOICE = { name = "Disarming Voice", type = "FAIRY", category = "special",
      power = 40, pp = 15, accuracy = 100, effect = "SWIFT_EFFECT" },
    DRAINING_KISS = { name = "Draining Kiss", type = "FAIRY", category = "special",
      power = 50, pp = 10, accuracy = 100, effect = "DRAIN_HP_EFFECT" },
    MOONBLAST = { name = "Moonblast", type = "FAIRY", category = "special",
      power = 90, pp = 12, accuracy = 100, effect = "SPECIAL_DOWN_SIDE_EFFECT" },
    DAZZLING_GLEAM = { name = "Dazzling Gleam", type = "FAIRY", category = "special",
      power = 65, pp = 10, accuracy = 100, effect = "NO_ADDITIONAL_EFFECT" },
    PLAY_ROUGH = { name = "Play Rough", type = "FAIRY", category = "physical",
      power = 75, pp = 10, accuracy = 90, effect = "ATTACK_DOWN_SIDE_EFFECT" },
    -- ---------------------------------------------------------- STEEL
    METAL_CLAW = { name = "Metal Claw", type = "STEEL", category = "physical",
      power = 45, pp = 30, accuracy = 95, effect = "NO_ADDITIONAL_EFFECT" },
    STEEL_WING = { name = "Steel Wing", type = "STEEL", category = "physical",
      power = 65, pp = 20, accuracy = 85, effect = "FLINCH_SIDE_EFFECT1" },
    IRON_TAIL = { name = "Iron Tail", type = "STEEL", category = "physical",
      power = 90, pp = 12, accuracy = 70, effect = "DEFENSE_DOWN_SIDE_EFFECT" },
    IRON_DEFENSE = { name = "Iron Defense", type = "STEEL", category = "status",
      power = 0, pp = 12, accuracy = 100, effect = "DEFENSE_UP2_EFFECT" },
    METAL_SOUND = { name = "Metal Sound", type = "STEEL", category = "special",
      power = 30, pp = 20, accuracy = 90, effect = "SPECIAL_DOWN_SIDE_EFFECT" },
  },
}
