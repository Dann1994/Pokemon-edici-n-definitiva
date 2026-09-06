# Changelog

Format: [keep a changelog](https://keepachangelog.com/en/1.1.0/).
Version headings match `manifest.json`'s `version`.

## 0.5.0

### Added

- **Title-screen ribbon**: the "Red Version" text now reads "EDICIÓN
  DEFINITIVA" (`tools/pokered_plus_title_ribbon.py` -> `assets/title/`,
  wired through `field.boot.title.versionRibbon`).

## 0.4.0

### Added

- **Overworld Pokemon art**: the 3 legendary birds, Mewtwo, both Snorlax
  and every decorative pet Pokemon in a house (31 map objects) now show a
  per-species overworld sprite derived from its mini sprite
  (`tools/pokered_plus_overworld_mons.py`, 16x16 4-grey) instead of the
  shared SPRITE_MONSTER / SPRITE_BIRD. Power Plant Voltorb/Electrode keep
  SPRITE_POKE_BALL (the item disguise).

## 0.3.0

### Added

- **Mini sprites**: per-species animated party-menu icons for all 151
  Kanto Pokemon, from Pokemon Yellow Legacy
  (`cRz-Shadows/Pokemon_Yellow_Legacy`), converted to the engine's
  16x32 two-frame RGBA format by `tools/pokered_plus_convert_icons.py`
  (keeping the Gen 2 per-icon colour; index 0 forced to opaque white) and
  registered into `icons.bySpecies`.

## 0.2.0

### Changed

- Type chart is now the **full Gen 6 chart** (`data/types_modern.lua`
  `chart`): every non-neutral matchup for all 18 types, overriding the
  vanilla Gen 1 rows. Fixes the Ghost/Psychic no-effect bug, nerfs
  Bug<->Poison, adds Fire-resists-Ice, etc. `POISON>BUG` is removed
  (neutral in Gen 6).
- `modern` ruleset is now a **builtin** (`src/battle/rulesets/modern.lua`)
  and `src/core/SaveData.lua` makes it the default for new saves. The mod
  only keeps `constants.defaultRuleset` in step.

## 0.1.0

### Added

- Gen 4+ physical / special / status category on all 165 Gen 1 moves
  (`data/move_categories.lua`), driving the modern damage split through the
  engine's existing `move.category` path.
- FAIRY, STEEL and DARK types.
- Canonical Gen 6 typings for CLEFAIRY, CLEFABLE (pure FAIRY), JIGGLYPUFF,
  WIGGLYTUFF (NORMAL/FAIRY), MR_MIME (PSYCHIC/FAIRY), MAGNEMITE, MAGNETON
  (ELECTRIC/STEEL).
