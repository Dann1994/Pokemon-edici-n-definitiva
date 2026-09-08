# Plan técnico — evento del Profesor Oak

Diseño narrativo en `DESIGN.md`. Este archivo mapea cada pieza a la API
existente del motor (`gen1recomp` / fork pokered-plus). **Nada de sistemas
nuevos.**

## Lo que YA existe y se reutiliza

| Necesidad | Mecanismo existente |
|---|---|
| **El combate de Oak** | `OPP_PROF_OAK` ya está en `data/generated/trainers.lua` (3 equipos nv. 66-70 por starter, contenido "cortado"). El sprite de combate está en `assets/generated/battle/trainers/prof.oak.png`. `data/scripts/pallet_town.lua` ya lo dispara al hablar con Oak en Pueblo Paleta tras la Liga → fija `EVENT_BEAT_PROF_OAK`. **El mod se apropia de ese combate y le pone la cadena de pistas + créditos + reversión del mundo alrededor.** |
| Elegir el equipo por starter | `check_flag EVENT_CHOSE_BULBASAUR / EVENT_CHOSE_SQUIRTLE` → `start_battle "trainer" "OPP_PROF_OAK" <1 BLASTOISE / 2 VENUSAUR / 3 CHARIZARD>` (igual que `pallet_town.lua`). |
| Flags de evento | `check_flag` / `set_flag`, prefijo `MOD_OAK_`. Gate: `EVENT_BEAT_CHAMPION_RIVAL` ∧ `check_dex_owned 150` ∧ ¬`EVENT_BEAT_PROF_OAK`. |
| Diálogos por NPC | `mod.content.map_scripts:register(MAP, { talk = { TEXT_KEY = {...} } })`. Para las ramas que el evento no toca: texto vanilla vía `MapScripts.baseTalk` o `show_text` del text key. |
| NPC condicional (rival, Lance, Oak en Ruta 1) | objeto nuevo `hidden = true` vía `maps:patch`; `onEnter` llama `show_object` con el gate, `hide_object` tras `EVENT_BEAT_PROF_OAK`. Patrón: `mods/mew_event` (el científico de la Mansión). |
| Oak ausente | `hide_object` de `OAKSLAB_OAK1`/`OAKSLAB_OAK2` (laboratorio) y `PALLETTOWN_OAK` (pueblo) mientras el evento está activo; restaurar tras vencerlo. |
| Liga cerrada | `onStep` en `INDIGO_PLATEAU` que intercepta el pasillo de entrada (celdas x 9-10, y ≤ 6) mientras el evento está activo → diálogo de Lance + `scriptMove` del jugador 1 al sur. |
| Créditos + fin | verbo nativo **`record_hall_of_fame`** — corre la inducción + los créditos + cura + `SaveData.applyPostGameHome` (habitación de Pueblo Paleta) + autoguardado + reset al título. Es el mismo camino que usa el combate final de campeón. |
| Reversión del mundo | automática: al fijarse `EVENT_BEAT_PROF_OAK`, todos los `onEnter` del mod dejan de mostrar los NPC del evento y de bloquear la Liga; Oak reaparece por la lógica vanilla. |

## Máquina de estados (flags `MOD_OAK_*`)

```
(EVENT_BEAT_CHAMPION_RIVAL ∧ check_dex_owned 150 ∧ ¬EVENT_BEAT_PROF_OAK)
        → OAKS_LAB.onEnter: Oak oculto, rival visible (OAK_EVENT_RIVAL)
                            PALLET_TOWN.onEnter: PALLETTOWN_OAK oculto
hablar rival        → MOD_OAK_RIVAL_TOLD   ("donde todo comenzó" / "el Pokémaníaco")
hablar Bill         → MOD_OAK_BILL_TOLD    (requiere RIVAL_TOLD; "el laboratorio más grande")
hablar científico   → MOD_OAK_CINNABAR_TOLD (requiere BILL_TOLD; "los combates más importantes")
                     → INDIGO_PLATEAU.onEnter: OAK_EVENT_LANCE visible, Liga bloqueada
hablar Lance        → MOD_OAK_LANCE_TOLD   (requiere CINNABAR_TOLD; "una ruta cerca de Paleta")
                     → ROUTE_1.onEnter: OAK_EVENT_OAK visible (~14,30)
hablar Oak (Ruta 1) → diálogo completo → combate OPP_PROF_OAK
   gana/pierde      → EVENT_BEAT_PROF_OAK → oak_event:finish
                       record_hall_of_fame (créditos + casa + guardar + título)
```

Tras `EVENT_BEAT_PROF_OAK`: rival, Lance y Oak-de-Ruta-1 ocultos; Liga
desbloqueada; Oak restaurado en el laboratorio/pueblo. Diálogo permanente de
Oak opcional ("Creo que voy a entrenar un poco más...").

## Archivos

- `mods/oak_event/main.lua` — item(ninguno), verbos, `map_scripts` para
  `OAKS_LAB`, `PALLET_TOWN`, `BILLS_HOUSE`, `CINNABAR_LAB`,
  `INDIGO_PLATEAU`, `ROUTE_1`; `maps:patch` para los 3 objetos nuevos.
- `mods/oak_event/tests/oak_event_test.lua` — carga headless + gate + verbos.
- `mods/oak_event/tests/simulate_oak.lua` — recorre la cadena de pistas y el
  combate en headless, imprime el guion.

## NPC del evento (objetos nuevos, ocultos por flag)

| id | mapa | sprite | celda | text |
|---|---|---|---|---|
| `OAK_EVENT_RIVAL` | OAKS_LAB | SPRITE_BLUE | (4,4) | TEXT_OAK_EVENT_RIVAL |
| `OAK_EVENT_SCIENTIST` | CINNABAR_LAB | SPRITE_SCIENTIST | (9,6) | TEXT_OAK_EVENT_SCIENTIST |
| `OAK_EVENT_LANCE` | INDIGO_PLATEAU | SPRITE_LANCE | (9,6) | TEXT_OAK_EVENT_LANCE |
| `OAK_EVENT_OAK` | ROUTE_1 | SPRITE_OAK | (14,30) | TEXT_OAK_EVENT_OAK |

Stage 2 (Bill) hooks `TEXT_BILLSHOUSE_BILL_CHECK_OUT_MY_RARE_POKEMON` — the
post-quest human Bill (`BILLSHOUSE_BILL2`), not the S.S. TICKET one.
