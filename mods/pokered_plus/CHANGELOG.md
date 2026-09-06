# Changelog

Format: [keep a changelog](https://keepachangelog.com/en/1.1.0/).
Version headings match `manifest.json`'s `version`.

## 0.1.0

### Added

- Gen 4+ physical / special / status category on all 165 Gen 1 moves
  (`data/move_categories.lua`), driving the modern damage split through the
  engine's existing `move.category` path.
- FAIRY, STEEL and DARK types plus their additive type-chart rows
  (`data/types_modern.lua`).
- Canonical modern typings for CLEFAIRY, CLEFABLE, JIGGLYPUFF, WIGGLYTUFF,
  MR_MIME, MAGNEMITE, MAGNETON.
- `modern` battle ruleset registered for OPTIONS > RULESET (opt in).
