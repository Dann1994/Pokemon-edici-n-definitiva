# Plan técnico — evento de Mew

Análisis del motor (`gen1recomp` / fork pokered-plus) y mapeo de cada pieza
del diseño (`DESIGN.md`) a la API existente. **Nada de sistemas nuevos.**

## Sistemas del motor que se reutilizan

| Necesidad | Mecanismo existente |
|---|---|
| Key item (MAPA VIEJO) | `mod.content.items:register(id, { keyItem = true, tossable = false, price = 0 })` |
| Flags de evento | verbos `check_flag` / `set_flag` / `clear_flag`; viven en `game.save.flags`. Convención del proyecto: prefijo `MOD_` para mods. |
| Diálogos por NPC / cartel | `mod.content.map_scripts:register(MAP, { talk = { TEXT_KEY = { ...filas... } } })`. `MapScripts.baseTalk(map, TEXT_KEY)` cae al diálogo vanilla en las ramas que el evento no toca (patrón de `example_lost_parcel`). |
| Texto multipágina (documentos) | filas `{ "show_text", "…\f…\f…" }` — `\f` es salto de página dentro de la caja. |
| NPC condicional (científico) | objeto nuevo con `hidden = true` en `POKEMON_MANSION_3F` vía `maps:patch`; `onEnter` llama `show_object` cuando se cumple la Etapa A; `hide_object` cuando huye. Patrón: `data/scripts/celadon_eevee.lua`, `hideBeatenSnorlax`. |
| "¿Tiene Mewtwo en el equipo?" | verbo propio `mew_event:party_has MEWTWO` (registrado con `mod.content.commands:register`) que lee `ctx.save.party` y pone `ctx.lastCheck`. No hay verbo nativo. |
| "150 de Kanto registrados" | verbo nativo **`check_dex_owned 150`** — cuenta `save.pokedex.owned`. |
| Viaje por barco | override de `TEXT_VERMILIONCITY_SAILOR1` (hoy en `data/scripts/story.lua`): si `check_item MAPA_VIEJO` y flag `ISLA_SUPREMA_UNLOCKED` → `warp` a la isla. |
| Mapa nuevo (Isla Suprema) | `mod.content.maps:register("ISLA_SUPREMA_*", { id, label, tileset, width, height, blocks, borderBlock, warps, objects, signs })` (patrón de `example_mini_conversion`). `warps` de ida (barco) y vuelta. |
| Encuentros salvajes de la isla | `mod.content.encounters:register(MAP, { grass = { rate, slots = {...} } })` |
| Estatua / pistas en el bosque | objetos nuevos + `talk` handler; `onEnter`/`scripts` paralelos con `emote`/`wait`/`hide_object` para las "pistas". |
| Combate único contra Mew | verbo nativo **`static_battle "MEW" <nivel> "MOD_MEW_CAPTURED"`** — corre `start_battle "wild"`, y si no pierdes: pone el flag y oculta el objeto. `check_battle_result "win" "run"` separa capturado / derrotado. |
| Intro especial del combate | `play_cry "MEW"` + fila de texto propia antes de `static_battle`. |

## Máquina de estados (flags `MOD_MEW_*`)

```
(Liga vencida ∧ MEWTWO capturado ∧ MEWTWO en equipo)
        → onEnter POKEMON_MANSION_3F: show_object del científico
hablar científico → texto pánico → hide_object → set MOD_MEW_SCIENTIST_FLED
leer documentos (6) → set MOD_MEW_DISCOVERED
        → habilita diálogos nuevos de Fuji
Fuji 1ª charla (evasiva) → set MOD_MEW_FUJI_MYSTERY
        (condición: check_dex_owned 150 ∧ party_has MEWTWO)
Fuji 2ª charla → revela "soy F." → give_item MAPA_VIEJO → set MOD_MEW_OLD_MAP
marinero Carmín + MAPA_VIEJO → set MOD_MEW_ISLA_SUPREMA → warp ISLA_SUPREMA
estatua 1ª vez → texto ; 2ª vez → play_cry + static_battle MEW → MOD_MEW_CAPTURED
```

## Archivos que tocará el mod

- `mods/mew_event/main.lua` — registro de item, verbos, `map_scripts` para
  `POKEMON_MANSION_3F`, `LAVENDER_TOWN` (Fuji), `VERMILION_CITY` (marinero) y
  los mapas nuevos; `maps:patch` para el objeto del científico.
- `mods/mew_event/data/south_island.lua` — layout(s) del mapa nuevo (blocks,
  warps, objects, signs).
- `mods/mew_event/tests/mew_event_test.lua` — carga headless + asserts de que
  el item, los verbos y el mapa quedan registrados y que el gate de flags
  avanza en orden.
- **Sin tocar `src/`** salvo que el override del marinero lo exija (a
  confirmar: `TEXT_VERMILIONCITY_SAILOR1` hoy es una función Lua en
  `data/scripts/story.lua`; `MapScripts.baseTalk` debería alcanzarla).

## Decisiones (resueltas por el usuario)

1. **Isla Suprema — tamaño/forma.** Un mapa `ISLA_SUPREMA`, tileset
   `OVERWORLD`, 8×13 bloques: muelle al sur (el marinero espera para volver a
   Carmín) → senda al norte → cartel "- F." junto al bosque → claro con la
   estatua. Datos en `data/isla_suprema.lua`. **Pendiente: pulido visual en
   Tiled** (los bloques son funcionales pero simples).
2. **Nivel de Mew.** nv. 60.
3. **Encuentros salvajes en la isla.** Ninguno (no se registran `encounters`).
4. **Los documentos.** Etapa 1: en los objetos "papeles" del 3er piso, no en
   `signs`. El cartel de la isla sí es un `sign`.
5. **Música de la isla.** `Music_Lavender` (tema inquietante) en `onEnter`.
   Nota: `data.audio` no está en este build, así que es no-op hasta
   regenerarlo. La idea original (ruta marina en la costa + tema Mansión en el
   bosque) queda como mejora futura vía `onStep`.
6. **Mod propio** `mods/mew_event`. Sí.
7. **La firma "- F."** — literal idéntico en documentos y cartel. Sí.

## Estado de implementación

| Etapa | Estado | Archivo |
|---|---|---|
| 1 Mansión 3F (científico + 6 documentos) | HECHO | `main.lua`, `data/documents.lua` |
| 2 Sr. Fuji + Mapa Viejo | HECHO | `main.lua` |
| 3 Marinero de Carmín (`TEXT_VERMILIONCITY_SAILOR1`) | HECHO | `main.lua` |
| 4 Mapa Isla Suprema | HECHO (falta pulido) | `data/isla_suprema.lua` |
| 5 Estatua + combate contra Mew | HECHO | `main.lua` |

Tests: `tests/mew_event_test.lua` 47/47; simulaciones `simulate_stage1/2/3.lua`
11 + 13 + 12.
