# Pokered Plus

Quality-of-life and modernisation overhaul for the gen1recomp port of
Pokemon Red. This is the working mod for the `pokered-plus` fork; see
`../../BACKLOG.md` for the full roadmap.

## What 0.1.0 does

1. **Physical / special / status split.** Every damaging move is tagged
   with its Gen 4+ category. The engine already prefers `move.category`
   over the Gen 1 type-based split (`src/battle/Damage.lua`), so damage,
   burn, Reflect and Light Screen all follow the modern rules.
2. **FAIRY, STEEL and DARK types.** Registered with their standard
   type-chart interactions (additive only -- no vanilla matchup is
   rewritten). Seven Kanto species get their canonical modern typings.
3. **`modern` ruleset.** Adds a RULESET choice in OPTIONS that switches off
   the Gen 1 battle bugs (1/256 miss, Focus Energy quarter-crit, badge
   boost re-apply, faithful residual timing, enemy infinite PP, and more).
   Not the default -- pick it per save.

## Try it

```sh
python3 tools/modkit.py validate mods/pokered_plus --base imported
python3 tools/modkit.py lint mods/pokered_plus
luajit mods/pokered_plus/tests/pokered_plus_test.lua
```

Then enable it: it lives in `mods/` (not `mods/examples/`), so the loader
discovers it; turn it on from the in-game MOD MANAGER (F10) or the launcher
MODS tab.

## Not done yet (see BACKLOG.md)

- Full Gen 6 type chart rewrite (balance decision)
- Yellow colour system / Yellow sprites on Red
- Map, item and menu bug fixes
- New events, Mew capture, Prof. Oak battle
- LAN play verification
