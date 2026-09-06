-- pokered-plus default ruleset: Gen 1 formulas, but with the famous
-- engine bugs turned off.  Mirrors gen1_faithful.lua field for field with
-- every quirk flag flipped to its fixed value.
--
-- Escape hatch: the branch `stock-defaults` keeps gen1_faithful as the
-- SaveData default.

return {
  name = "modern",
  -- a 100%-accurate move never misses
  oneIn256Miss = false,
  -- crits read current (staged) speed and respect stat stages
  critUsesBaseSpeed = false,
  critIgnoresStages = false,
  -- damage random factor r in [217,255], damage = damage * r / 255
  randMin = 217,
  randMax = 255,
  -- Focus Energy multiplies the crit rate (x4), it does not quarter it
  focusEnergyBug = false,
  -- AI opponents spend PP and can Struggle when empty
  enemyUnlimitedPP = false,
  -- Hyper Beam always forces a recharge turn, even on a KO
  hyperBeamSkipRechargeOnKO = false,
  -- poison / burn / leech seed tick in an end-of-round sweep after both
  -- sides have moved (Gen 3+ order)
  residualAfterMove = false,
  -- no stale badge-boost re-application on a stat change
  badgeBoostReapplyBug = false,
  -- a hit that computes 0 damage is not silently turned into a miss
  zeroDamageMiss = false,
  -- burn / paralysis stat drops are recomputed, not baked once
  statusPenaltyIsBaked = false,
}
