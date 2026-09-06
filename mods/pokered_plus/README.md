# Pokered Plus

Quality-of-life and modernisation overhaul for the gen1recomp port of
Pokemon Red. The working mod for the `pokered-plus` fork; full roadmap in
`../../BACKLOG.md`.

## What it does (0.4.0)

1. **Physical / special / status split.** Every damaging move is tagged
   with its Gen 4+ category. The engine already prefers `move.category`
   over the Gen 1 type-based split (`src/battle/Damage.lua`).
2. **Full Gen 6 type chart.** FAIRY, STEEL and DARK types, plus every
   vanilla matchup rewritten to Gen 6 values (Ghost/Psychic bug fixed,
   Bug<->Poison nerfed, Fire resists Ice, `POISON>BUG` neutralised, ...).
   Seven Kanto species get their canonical Gen 6 typings.
3. **`modern` default ruleset.** The bug-free Gen 1 ruleset
   (`src/battle/rulesets/modern.lua`) is a builtin and the SaveData
   default; this mod keeps `constants.defaultRuleset` in step. Pick
   FAITHFUL from OPTIONS > RULESET for the original bugs.
4. **Mini sprites.** Per-species animated party-menu icons for all 151
   Kanto Pokemon (`assets/icons/`, from Pokemon Yellow Legacy via
   `tools/pokered_plus_convert_icons.py`).
5. **Overworld Pokemon art.** The legendary birds, Mewtwo, Snorlax and the
   decorative pet Pokemon in houses each get their own overworld sprite
   (`assets/ow/`, derived from the mini sprites by
   `tools/pokered_plus_overworld_mons.py`). Voltorb/Electrode in the Power
   Plant stay disguised as items.

Sibling changes that are **not** in this mod:

- Widescreen battles, FAST text, `modern` default -> `src/core/SaveData.lua`
  (escape hatch: the `stock-defaults` branch).
- Yellow battle sprites -> `scripts/pokered_plus_yellow_gfx.lua` (cache overlay,
  re-run after each Red import; `--revert` to undo).

## Verify

```sh
export MODKIT_LUAJIT=".../LuaJIT/bin/luajit.exe"
python3 tools/modkit.py validate mods/pokered_plus --base imported
luajit mods/pokered_plus/tests/pokered_plus_test.lua
```

## Not done yet (see BACKLOG.md)

- Yellow colour system on Red (PaletteFX source patch)
- Map / item / menu bug fixes
- New events, Mew capture, Prof. Oak battle
- LAN play verification
