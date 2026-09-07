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
| Viaje por barco | override de `TEXT_VERMILIONCITY_SAILOR1` (hoy en `data/scripts/story.lua`): si `check_item MAPA_VIEJO` y flag `SOUTH_ISLAND_UNLOCKED` → `warp` a la isla. |
| Mapa nuevo (Isla del Sur) | `mod.content.maps:register("SOUTH_ISLAND_*", { id, label, tileset, width, height, blocks, borderBlock, warps, objects, signs })` (patrón de `example_mini_conversion`). `warps` de ida (barco) y vuelta. |
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
marinero Carmín + MAPA_VIEJO → set MOD_MEW_SOUTH_ISLAND → warp SOUTH_ISLAND
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

## Decisiones abiertas (necesito tu OK antes de codificar)

1. **Isla del Sur — tamaño/forma.** Propuesta: ~2–3 pantallas. Costa (warp del
   barco) → claro con el cartel "— F." → bosque corto y lineal → claro final
   con la estatua y unas ruinas. Tileset `OVERWORLD` (tiene césped, árboles,
   agua, flores, estatua). ¿OK o querés algo distinto?
2. **Nivel de Mew.** Mewtwo estático es **nv. 70**. Propuesta: **Mew nv. 70**
   (a la par) o nv. 60. ¿Cuál?
3. **Encuentros salvajes en la isla.** Propuesta: un parche de hierba con
   Chansey / Tangela / Scyther / Pinsir / Kangaskhan (raros, aire "tropical").
   ¿O sin encuentros?
4. **Los documentos.** Como **carteles** (`signs`) que abren una caja de texto
   con `\f` para pasar de página. Es lo más vanilla. ¿OK?
5. **Música de la isla.** Reutilizar una pista existente. Opciones: tema de
   ruta marina, tema de Isla Canela, tema del Bosque Verde, o el tema de
   cueva "misterioso". ¿Cuál?
6. **Mod propio vs. dentro de pokered_plus.** Está como mod propio
   `mods/mew_event` (activable/desactivable aparte). ¿OK?
7. **La firma "— F."** — texto literal idéntico en los documentos y en el
   cartel. ¿OK?
