# pokered-plus — backlog de cambios

Lista viva de todo lo que se va a aplicar sobre el fork de `gen1recomp`.
Estado: `HECHO` · `EN CURSO` · `LISTO-PARA-REVISAR` (implementado, falta tu OK) ·
`PENDIENTE` · `NECESITA-DECISIÓN` (bloqueado esperando tu criterio) ·
`FUTURO` (anotado, no ahora).

Convención de vías: **[opción]** = ya existe como ajuste · **[mod]** = vía API de mods ·
**[fuente]** = editar el código del motor · **[datos]** = editar el extractor / capa de datos.

---

## 1. Presentación

| # | Cambio | Vía | Estado | Notas |
|---|---|---|---|---|
| 1.1 | Pantalla panorámica (batalla widescreen, superficie dinámica) | [fuente] `WideBattle.lua` + `SaveData.lua` | HECHO | `battleLayout = "wide"` por defecto. **Reescrito** para que la superficie se adapte al aspecto de la ventana (`WideBattle.dims`): a 16:9 se agranda el alto en vez de dejar barras, así con `BATTLE SIZE = FILL` el cuadro de mensaje/comandos queda pegado al borde inferior de la ventana y el POKéMON propio apoya sobre él. Marco del HUD (nombre/nivel/HP) conservado. Menú de ataques sigue en grid (cosmético, sin tocar). |
| 1.6 | Diálogo del mapa a lo ancho | [fuente] `UI LAYOUT = WIDE` | HECHO | Tercer valor de la opción UI LAYOUT (centrado/dinámico/ancho). El cuadro de diálogo del mapa (y su SÍ/NO) se dibuja a su ancho real de mosaicos —tomado del área jugable— sobre una capa aparte que se estira al borde inferior de la ventana. Inerte fuera de pantalla panorámica. |
| 1.7 | Ventana fija en 16:9 | [fuente] `src/core/WindowAspect.lua` | HECHO | Al entrar al juego (no en el launcher) la ventana se bloquea en 16:9: en modo ventana se ajusta y se mantiene en cada resize; en pantalla completa/bordes rotos se recorta el renderizado a un rectángulo 16:9 centrado (`Playfield.forceAspect`). Se libera al volver al launcher. |
| 1.2 | Colores de Pokémon Amarillo en Red | [fuente] `PaletteFX` | HECHO | Nuevo modo de COLORS **`"yellow"`** en `src/render/PaletteFX.lua` (helper `yellowColors()` + `usesYellowCgb` extendido): pinta cualquier juego con las CGBBasePalettes de `data/palettes_yellow.lua` — las paletas Game Boy Color auténticas de Yellow (pueblos, cuevas, menús, barras de HP, sprites de combate). Por defecto en `SaveData.lua`. Otras opciones en OPTIONS → COLORS. **Escape:** rama `stock-defaults`. |
| 1.3 | Texto rápido por defecto | [fuente] `SaveData.lua` | HECHO | `textSpeed = 1` (FAST). Test repinneado. |
| 1.5 | Título: "Red Version" → "EDICIÓN DEFINITIVA" | [mod] `field.boot.title.versionRibbon` | HECHO | `mods/pokered_plus` v0.5.0. `tools/pokered_plus_title_ribbon.py` genera la tira 1-bit (fuente Plain Pixel) en `assets/title/`; `TitleState` la centra en y=64 y la colorea con la paleta LOGO1 (roja en el título de Red). |
| 1.4 | Sprites de Pokémon de Amarillo sobre Red | [datos] overlay de cache | HECHO | `scripts/pokered_plus_yellow_gfx.lua` copia los 305 PNGs de batalla de Yellow sobre el cache de Red y ajusta `frontSize` de las 7 especies que cambiaron de tamaño. **Re-ejecutar tras cada re-importación de Red.** `--revert` para deshacer. |
| 1.8 | **Aviso de MO al interactuar** (estilo remakes de 3ª gen) | [fuente] `OverworldController.lua` + `SaveData.lua` | HECHO | Al acercarse al agua o a un árbol cortable y tocar A, pregunta directo "¿Quieres usar SURF/CORTE?" en vez de exigir el submenú de MO del menú de equipo. Cablea primitivas que ya existían sin usar (`useSurfFieldMove/useCutFieldMove/trySurf/tryCut/stopSurfing`) al único A-press hook que pokered nunca tuvo (`OverworldState:tryFieldMovePrompt`). Sin insignia / nada que cortar / sin agua → rechazo silencioso, nunca insiste. Opción **FIELD MOVE PROMPT** en OPCIONES → EXTRAS (por defecto ON). Test `field_move_prompt.lua` 18/18. |
| 1.9 | **Menús a pantalla ancha** (rediseño estilo remakes 3ª gen) | [fuente] `PartyMenu.lua` / `ListMenu.lua` / `BoxMenu.lua` | EN CURSO | Decisión tomada: rediseño de contenido, no solo estético (ver `Pendiente` más abajo). **Fase 1 (equipo) HECHA**: con UI LAYOUT = WIDE, el menú de selección de Pokémon suma un panel lateral propio en los 144px extra (mismo total de 304px que la batalla ancha) con el sprite, nivel, ATAQUE/DEFENSA/VELOCIDAD/ESPECIAL y TIPO1/TIPO2 del Pokémon resaltado — diseño propio (no reproduce SummaryMenu, que sigue siendo la pantalla de estado real de dos páginas), inactivo fuera de UI LAYOUT = WIDE y fuera de un menú de equipo abierto DURANTE una batalla ancha (ese sigue centrado clásico dentro de la superficie de la batalla). `PartyMenu:uiSize/wantsPanel/drawPanel`, zona SGB del sprite del panel. Test `party_wide_panel.lua` 13/13, suite completa sin regresiones nuevas (14 fallos preexistentes, iguales antes y después). **Fase 2 (bolsa/tienda/PC) HECHA**: `ListMenu:drawItemBox` (la caja compartida detrás de la bolsa, la tienda y la PC) ahora se ensancha con UI LAYOUT = WIDE — el borde izquierdo se queda pegado donde ya estaba en modo clásico (no se recentra: la tienda mantiene su propio cuadro BUY/SELL/QUIT + dinero abierto detrás de la lista, igual que la bolsa mantiene el menú START abierto detrás de la suya, así que recentrar hubiera dejado esos cuadros vistos a medias) y crece hacia la derecha hasta el ancho del área jugable. Ganancia real: en modo COMPRAR se suma una columna "ya tenés ×N" con el inventario real (`game.save.inventory`) — no hay datos de descripción de objetos en este motor, así que en vez de inventar texto se optó por mostrar ese dato real. La bolsa (`BagMenu.lua`) queda excluida a propósito (ya marca `holdsUIAnchors = true` por el mismo motivo del cuadro START superpuesto). Nuevo `Renderer:beginWideItemPass/endWideItemPass/setWideItemAnchor` (anchor `"top"`, superficie propia, análoga a la del diálogo ancho). Test `wide_item_box.lua` 23/23. **Corrección post-playtest**: la caja se ensanchaba usando el ancho TOTAL de la ventana, pero se anclaba al origen del letterbox clásico (que en modo WIDE sigue centrado, `Renderer.uiCentered` no cambia con esta opción) — en una ventana 16:9 real eso la hacía pasarse del borde derecho y quedar recortada. Nuevo `Renderer:wideItemTiles()` calcula el espacio real disponible desde ese origen hasta el borde de la ventana (en vez de reusar `wideOverworldTiles()`, pensado para un elemento pegado al borde de la ventana, no al del letterbox). De paso se ensancharon los CUADROS DE DIÁLOGO de la tienda/PC (`ListMenu:drawMessageBox`, `ShopMenu:drawClerk`) — nunca los había tocado, seguían fijos en 160px — reusando la misma capa del diálogo ancho del mapa (anchor `"bottomwide"`, sin conflicto porque este cuadro sí puede pegarse al borde de la ventana). Test actualizado a 26/26; verificado con captura que el reflejo tenue de COMPRAR/VENDER/SALIR a la izquierda de la lista es el mismo en modo clásico (no es un bug nuevo). **Fase 3 (Datos/Pokédex) HECHA**: nuevo módulo compartido `src/ui/WidePanel.lua` (uiSize/wants/offY — el mismo trío que ya tenía `PartyMenu.lua`, factorizado para no reescribir esa pantalla ya probada — más `spriteImage/spriteRect` para el sprite del panel). **`SummaryMenu` (pantalla DATOS)**: página 1 suma un panel con los 4 movimientos + PP (lo único que antes exigía pasar a la página 2); página 2 suma un panel con ATQ/DEF/VEL/ESP + TIPO1/TIPO2 (lo que se ve en la página 1) — entre las dos páginas ya se ve todo sin duplicar nada (la primera versión repetía los movimientos en ambas páginas, se veía como un eco tonto, corregido). **`PokedexMenu` (pantalla POKéDEX)**: panel con sprite + estadísticas BASE (no las de un Pokémon concreto: acá no hay una instancia, solo la especie) + tipo del renglón resaltado — vacío si nunca se vio esa especie, igual que la fila ya oculta el nombre con guiones. Ambos usan el layout compacto de `PartyMenu.lua` (ATQ/DEF/VEL/ESP cortos) para que TIPO1/TIPO2 tenga lugar de sobra. Tests `summary_wide_panel.lua` 15/15, `pokedex_wide_panel.lua` 12/12. **Fase 4 (PC/caja, `BoxMenu.lua`) pendiente** — ver notas de alcance en `Pendiente`. |
| 1.10 | **Correr manteniendo B** | [fuente] `Player.lua` + `SaveData.lua` | HECHO | A pie, mantener B duplica la velocidad de paso (reutiliza `bikeStepFrames`, el mismo valor que ya usa la bici) **y** duplica el ritmo de la animación de caminar para que se note — a diferencia de la bici, que solo duplica la traslación y deja las piernas al ritmo normal (así se ve como que "desliza"). Se desactiva solo en bici (ya es más rápida), surfeando (no hay piernas) o en medio de un salto de repisa (mismo motivo por el que la bici tampoco acelera ahí). Opción **HOLD B TO RUN** en OPCIONES → EXTRAS (por defecto ON). Test `hold_b_to_run.lua` 19/19. |
| 1.11 | **Menú de pausa (START) pegado a la derecha en pantalla ancha** | [fuente] `Renderer.lua` + `Menu.lua` | HECHO | El menú de pausa ya se pegaba a la esquina superior derecha en UI LAYOUT = DYNAMIC, pero no en WIDE (`Renderer.uiCentered` solo lo apaga DYNAMIC, no WIDE) — quedaba centrado con el resto del letterbox clásico, lejos del borde real de la ventana. Nuevo `Renderer:setWideCornerAnchor` (usado solo por menús que ya piden un `anchor` propio, hoy nada más el de pausa) hace lo mismo que el anclaje normal pero sin depender de DYNAMIC. Test `ui_layout_option.lua` 37/37. |

## 2. Tipos y tabla de tipos

| # | Cambio | Vía | Estado | Notas |
|---|---|---|---|---|
| 2.1–2.3 | Tipos **HADA / ACERO / SINIESTRO** | [mod] `type_chart` | HECHO | `mods/pokered_plus/data/types_modern.lua`. Registrados con la tabla Gen 6 completa. Test verde. |
| 2.4 | Reasignar especies a los tipos nuevos | [mod] `pokemon:patch` | HECHO | Tipos Gen 6 canónicos: CLEFAIRY, CLEFABLE → HADA puro (como en Gen 6); JIGGLYPUFF, WIGGLYTUFF → NORMAL/HADA; MR_MIME → PSÍQUICO/HADA; MAGNEMITE, MAGNETON → ELÉCTRICO/ACERO. |
| 2.5 | Tabla de tipos completa Gen 6 | [mod] `type_chart:override` | HECHO | `data/types_modern.lua` `chart` — 120 celdas para los 18 tipos, sobrescribe las filas vanilla de Gen 1. Corrige el bug Fantasma→Psíquico (0→2×), nerfea Bicho↔Veneno, Fuego resiste Hielo, quita `POISON>BUG`, etc. Test verde. |
| 2.6 | **Split físico/especial por movimiento** | [mod] `moves:patch` | HECHO | `data/move_categories.lua` — 164/165 movimientos con su categoría Gen 4+ (STRUGGLE reservado por el motor). Test verde. |
| 2.7 | Movimientos nuevos SINIESTRO/HADA/ACERO (diseño propio) | [mod] `moves:register` + `pokemon:patch` | HECHO | `mods/pokered_plus/data/new_moves.lua` + `new_learnset.lua`. 15 movimientos (5+5+5) + Mordisco retipado a siniestro, con potencia/PP/precisión **propios del mod** (no los oficiales de Gen 2/3/6 — decisión explícita para no reconstruir esa data). Learnset restringido a 23 especies que ya existen en Kanto (nada de Gen 2/3 agregado). Test `pokered_plus_test.lua` 86/86. Pendiente: si el usuario quiere los learnsets/stats oficiales de Gen 2/3, tiene que pasar él los datos (`mods/pokered_plus-worksheet/new_moves.txt`, plantilla ya entregada) — no los reconstruyo yo. |

## 3. Corrección de bugs conocidos

### 3.1 Bugs de batalla → ruleset `modern` (POR DEFECTO)

**HECHO.** `src/battle/rulesets/modern.lua` (ahora es un ruleset *builtin*,
registrado igual que `gen1_faithful` en `BattleState`, `BattleCheckpoint`,
`OptionsMenu`, `LinkBattle`, `Builtins`). `src/core/SaveData.lua` lo pone como
default de las partidas nuevas. FAITHFUL sigue disponible en OPTIONS → RULESET.
**Escape:** rama `stock-defaults`.

Flags apagados (todos): `oneIn256Miss`, `focusEnergyBug`, `critIgnoresStages`,
`critUsesBaseSpeed`, `enemyUnlimitedPP`, `hyperBeamSkipRechargeOnKO`,
`residualAfterMove`, `badgeBoostReapplyBug`, `zeroDamageMiss`,
`statusPenaltyIsBaked`.

### 3.2 Bugs de la lista del usuario (mapas / objetos / menús)

Revisados los 10. Este motor es una **reimplementación en Lua**, no un
emulador: los glitches que dependen de corromper la RAM de la Game Boy no
existen y no hay nada que arreglar.

**A — imposibles acá (no hay RAM que corromper):**
- Glitch del Viejo / MissingNo (surf desde costa de Cinnabar) — dependía del búfer del nombre leído como datos de encuentro
- Atravesar paredes tras la Zona Safari (500 pasos) — desbordaba el contador de pasos sobre el mapa de colisiones
- Surf/pesca sobre estatuas de Rhydon — surf consulta `map:isWaterCell` por celda, no coincidencias de tile ID

**B — ya arreglados por construcción:**
- Softlock de guardería a nivel 1 — `math.max(0, curva(nivel))` en `src/pokemon/Growth.lua`, sin desbordamiento
- Piedras evolutivas en combate — `ItemEffects.use` rechaza `STONES` si `battle` (línea ~237), el camino de corrupción nunca corre
- Barra de HP "eterna" en Blissey — normalizada a ~96 frames (`PartyMenu:animateTo`)
- Repisas / agujeros de Islas Espuma — `parity_ledge_seam_hop`, `parity_seafoam_holes` verdes

**C — quirks de diseño que la reimplementación copiaba (ARREGLADOS en `modern`):**

| Quirk | Flag | Estado |
|---|---|---|
| Fallo 1/256 en moves de 100% | `oneIn256Miss` | ✅ (ya estaba) |
| Foco Energía ÷4 el crítico | `focusEnergyBug` | ✅ (ya estaba) |
| **X-Precisión salta la precisión de TODO (incl. OHKO Fisura/Guillotina)** | `xAccuracyNeverMiss=false` | ✅ **HECHO** — en `modern`, X-Precisión sube 1 nivel de precisión (estilo Gen 3) en vez de garantizar el acierto. `src/battle/rulesets/*` + `src/inventory/ItemEffects.lua`. |
| **Poké Flauta / Despertar / Cura Total limpian `status` pero no el contador `sleepTurns`** | — (siempre) | ✅ **HECHO** — `ItemEffects.lua` ahora limpia `sleepTurns` en los 4 sitios que curan el sueño. |

*Repelente al surfear: el código rechaza el Repelente en combate (#894); el
conteo de pasos tierra/agua no mostró problema. Sin cambios.*

## 4. Sprites y gráficos

| # | Cambio | Vía | Estado | Notas |
|---|---|---|---|---|
| 4.1 | Sprites de Pokémon de **Amarillo** sobre Red | [datos] overlay | HECHO | `scripts/pokered_plus_yellow_gfx.lua`: copia los 305 PNGs de `battle/front` + `battle/back` de Yellow sobre el cache de Red y corrige `frontSize` de 7 especies (dewgong, doduo, dugtrio, gastly, gengar, haunter, mankey). Re-ejecutar tras re-importar Red. Guarda backup en `battle_red_backup/`; `--revert` restaura. `Jugar Pokemon Red.bat` re-aplica el overlay en cada arranque, así sobrevive a re-importaciones de Red. |
| 4.2 | **Mini sprites** (iconos de menú por especie) para los 151 | [mod] `icons:register` | HECHO | Sacados de `cRz-Shadows/Pokemon_Yellow_Legacy` (`gfx/icons/`), convertidos a 16×32 / 2 frames RGBA **en color** (paleta Gen 2) con `tools/pokered_plus_convert_icons.py`, en `mods/pokered_plus/assets/icons/` (151 PNGs). El mod los registra en `icons.bySpecies` — ganan sobre los ~10 iconos genéricos de Gen 1. `modkit lint` verde (arte nuevo, no ROM-derived). Test verde. |
| 4.3 | Pokémon del overworld con su mini sprite | [mod] `sprites` + `maps:patch` | HECHO | Las 3 aves legendarias, Mewtwo, los 2 Snorlax y todos los Pokémon "mascota" de las casas (31 objetos) usan un sprite de overworld propio, sacado del mini sprite con `tools/pokered_plus_overworld_mons.py` (16×16, 4 grises). Voltorb/Electrode de la Central siguen disfrazados de Poké Ball. Test verde. |
| 4.4 | Mejoras de calidad de vida del repo | [opción/mod] | EN CURSO | Ver §5. `textSpeed` ya en FAST (§1.3). |

## 5. Calidad de vida (lo que ya trae el repo)

Catálogo — decidir cuáles activar por defecto:

- **Opciones ya disponibles**: `textSpeed`, `battleStyle` (SHIFT/SET), velocidad de
  juego por categoría (`speedOverworld/Battle/Menu`), `animations` on/off,
  `GAME SPEED` con atajos rebindables, guardado/carga por hotkey (F1/F2).
- **Editor de guardado** integrado (ordenar bolsa/PC, llenar stacks a ×99, editor de monedas).
- **Exportar diploma de Pokédex** e imágenes de impresora.
- **Mods de ejemplo** que muestran mecánicas QoL reutilizables: `example_dexnav`
  (buscador de Pokémon por ruta), `example_balance_tweaks`, `example_weather`.
- **A decidir**: subir `textSpeed` a máx por defecto, `battleStyle="set"`,
  `animations` — todo en `SaveData.lua`.

## 6. Multijugador / red

| # | Cambio | Vía | Estado | Notas |
|---|---|---|---|---|
| 6.1 | Modo de juego **LAN** | [ya existe] | HECHO (upstream) | P2P sobre lua-enet. START → LINK → HOST A GAME / unirse por IP. Puerto UDP 7777 (`POKEPORT_LINK_PORT`). Intercambios y combates Red/Blue/Yellow. Falta: probarlo con 2 instancias. |
| 6.2 | Lobby online (combates, espectar, torneos) | [ya existe] | INFO | En el launcher. |

## 7. Eventos y contenido nuevo

| # | Cambio | Vía | Estado | Notas |
|---|---|---|---|---|
| 7.1 | Agregar eventos nuevos | [mod] `map_scripts` + VM `src/script/` | PENDIENTE | La VM de scripting está entera (`Commands.lua`, `ScriptRunner.lua`, `Flags.lua`); scripts a mano en `data/scripts/`. Mod de ejemplo: `example_lost_parcel` (quest + NPC + diálogo). Esperando qué eventos. |
| 7.2 | **Captura de Mew — evento "Isla Suprema"** | [mod] `mew_event` | LISTO-PARA-REVISAR | Diseño → `DESIGN.md`, plan → `PLAN.md`. Decisiones: isla "Isla Suprema", Mew nv. 60, sin encuentros salvajes, música ruta marina (costa) + tema Mansión (bosque), mod propio. **Etapa 1 HECHA** (commit): Mansión 3F — científico oculto que aparece con Liga vencida + Mewtwo capturado + Mewtwo en equipo → se acerca, reconoce a Mewtwo, huye → los "papeles" del 3er piso pasan a contener los 6 documentos de "F." → leerlos todos activa `MOD_MEW_DISCOVERED`. Test 47/47. **Etapa 2 HECHA**: casa del Sr. Fuji (Lavanda) — override de `TEXT_MRFUJISHOUSE_MR_FUJI` con máquina de estados: 1ª charla evasiva → `MOD_MEW_FUJI_MYSTERY`; con **150 de Kanto registrados + Mewtwo en el equipo** → 2ª charla: "Yo soy F.", entrega el key item **MAPA VIEJO** → `MOD_MEW_OLD_MAP`. Rama pre-Etapa-1 = diálogo vanilla de Fuji reinsertado literal. `simulate_stage2.lua` 13/13. **Etapas 3-5 HECHAS**: (3) override de `TEXT_VERMILIONCITY_SAILOR1` — con `MAPA_VIEJO` + `MOD_MEW_OLD_MAP` el marinero de Carmín ofrece el viaje (`warp` a `ISLA_SUPREMA`), rama sin mapa = flujo vanilla del S.S. Anne vía `baseTalk`. (4) mapa nuevo `ISLA_SUPREMA` (`mods/mew_event/data/isla_suprema.lua`, OVERWORLD 8×13 bloques: muelle al sur con marinero de vuelta, senda al norte, cartel "- F." junto al bosque, claro con la estatua; bloques confirmados contra el tileset vanilla; test de transitabilidad). (5) estatua (`SPRITE_BOULDER` — la de Gimnasio Plateado, cambiada desde `SPRITE_FOSSIL` tras playtest): 1ª interacción texto + `MOD_MEW_STATUE_SEEN`, 2ª → `play_cry MEW` + diálogo "Mew..." + `static_battle "MEW" 60 "MOD_MEW_CAPTURED"` (se oculta capturado o derrotado). **Corrección post-playtest**: el grito nunca sonaba — `play_cry` solo arma `ctx.pendingCry`, hace falta un `show_text` después para que realmente se reproduzca (igual que las aves legendarias: `play_cry` + `show_text "¡Gyaoo!"`), y no había ninguno entre el grito y el combate. Agregado el `show_text "Mew..."` que faltaba. Música: `Music_Lavender` en `onEnter` (no-op hasta regenerar `data.audio`). `simulate_stage3.lua` 13/13, `mew_event_test.lua` 48/48. **Pendiente de pulido visual del mapa** (el usuario puede refinarlo en Tiled). |
| 7.3 | **Batalla contra el Profesor Oak** | [mod] `oak_event` | LISTO-PARA-REVISAR | Mod nuevo `mods/oak_event` que envuelve el combate cortado `OPP_PROF_OAK` (3 equipos por starter, `assets/generated/battle/trainers/prof.oak.png`) en el evento del usuario. Gate: `EVENT_BEAT_CHAMPION_RIVAL` + 150 registrados + no `EVENT_BEAT_PROF_OAK`. Cadena: rival en el lab (Oak ausente) -> Bill (override de `TEXT_BILLSHOUSE_BILL_SS_TICKET`, vanilla reinsertado) -> cientifico de Isla Canela (`CINNABAR_LAB_METRONOME_ROOM` scientist 2) -> Lance en la Meseta con la Liga bloqueada por `onStep` -> Oak en la Ruta 1 (14,30): revelacion completa -> `start_battle trainer OPP_PROF_OAK` -> al ganar `EVENT_BEAT_PROF_OAK` + `record_hall_of_fame` (creditos + cura + habitacion + guardado + reset al titulo). El mundo se revierte solo al fijarse el flag. Test 24/24, `simulate_oak.lua` 22/22. |

## 7bis. Idiomas

| # | Cambio | Vía | Estado | Notas |
|---|---|---|---|---|
| 7b.1 | Selección de idioma | [mod] `LANGUAGE` | HECHO | El motor ya trae el sistema: cada traducción es un mod `category:LANGUAGE` + `language:true`. Se elige en el GESTOR DE MODS (F10) / pestaña MODS. Funciona en online. |
| 7b.2 | **Español (España)** — `mods/es_ES` | [mod] `modkit translation` | PARCIAL | `--pixel-font` (tildes/ñ/¿¡ sin hoja de glifos). Traducido: 165 movimientos + los 15 nuevos de §2.7, 15 tipos, ~70 objetos, clases de entrenador, HUD de estado. **`strings.lua`** (cadenas de interfaz/combate del motor + launcher): ~1080/1882 traducidas — todo lo visible jugando (combate, menús, OPCIONES, guardar/PC/tienda, objetos, nombres, evolución, POKéDEX, Salón de la Fama) + el launcher y el juego online. Quedan ~800: tripas del launcher que casi nunca se ven (resolución de dependencias, sync entre dispositivos, Estudio de Pieles, sellado de cartuchos) — caen a inglés sin molestar. Nombres = glosario de referencia (PokéAPI/WikiDex). Test 22/22. |
| 7b.3 | **Español latino** — `mods/es_419` | [mod] delta sobre es_ES | HECHO (nombres) | Depende de `es_ES` y cambia los 165 movimientos + tipos (Insecto/Pelea) + Poké Balls (Pokébola…) a la traducción latina de **Leyendas Pokémon: Z-A**. Fuente: PokéAPI locale `es` (= la traducción de Z-A) contrastado con Pokéxperto. |
| 7b.4 | Guion narrativo en español | traducción propia | HECHO | `mods/es_es/lang/dialogue.lua` — **2592/2592 líneas traducidas** (100%) en 13 lotes, traducción propia (no la localización oficial de Nintendo). Glosario de topónimos/objetos consistente con 7b.2. Merge vía `scripts/apply_es_dialogue.py` desde TSVs en `es_ES-worksheet/es/` (no se suben). Los diálogos de los eventos Mew/Oak van aparte (hard-coded en cada mod). Test `es_ES_test.lua` 22/22, suite completa sin regresiones (11 fallos de infra de base). **Pasada de neutralización** (86 sustituciones): sin modismos de España (vale→bueno, crío→niño, colega→amigo, prismáticos→binoculares, tragaperras→tragamonedas, coger→agarrar, seta→hongo, vosotros→ustedes…) para que sirva también a LATAM. |
| 7b.5 | Rejilla de nombres con Ñ | [mod] hook `ui.naming.grid` | FUTURO | `es_ES/lang/naming.lua` puede añadir la Ñ a la pantalla de poner mote. |

## 8. Ya aplicado en el fork (infra)

- `git`: fork completo (1541 commits), remoto `upstream`, rama `pokered-plus`. Ver `FORK.md`.
- `Jugar Pokemon Red.bat` — lanzador directo.
- Toolchain: Python 3.12, LÖVE 11.5, LuaJIT 2.1. Shims `python`/`python3` en
  `C:\Users\dani_\bin` apuntando al Python real (el de la Store no sirve).
  `modkit` necesita `MODKIT_LUAJIT` o luajit en PATH:
  `export MODKIT_LUAJIT="/c/Users/dani_/AppData/Local/Programs/LuaJIT/bin/luajit.exe"`.
- ROM de Red verificada e importada.
- **`mods/pokered_plus`** (v0.2.0) — el mod de trabajo del fork. `modkit validate`
  + `modkit lint` + `tests/pokered_plus_test.lua` (35/35) en verde. Contiene:
  split físico/especial, tipos HADA/ACERO/SINIESTRO + tabla Gen 6 completa,
  `constants.defaultRuleset`. Auto-activado (no `experimental`, vive en `mods/`).
- Ruleset `modern` = builtin + default (§3.1). Widescreen + texto rápido =
  defaults en `SaveData.lua`. Sprites de Yellow = overlay de cache (§1.4).
  **Escape de todos los defaults:** rama `stock-defaults`.
- Baseline de tests: `luajit tests/run_tests.lua` = **11 fallos preexistentes**
  (audio ausente del `data/generated/` del repo, FPS headless, `python3` para
  unos tests de modkit). Los cambios de pokered-plus **no añaden regresiones**
  (tests de paridad afectados por los defaults nuevos repinneados a mano).

---

## Decisiones aplicadas (sesión 2026-09-06)

- ✅ Tabla de tipos → **Gen 6 completa**; Clefairy → **Hada puro** (como Gen 6).
- ✅ Widescreen → **por defecto** (detalles de navegación del menú, después).
- ✅ Ruleset → **`modern` por defecto**.
- ✅ Juego base **Red** + **sprites de Yellow** aplicados.
- ✅ Texto **rápido** por defecto.

## Pendiente

### De mí (implementar)
1. **§7.2** — pulido visual del mapa de la Isla Suprema (cuando el usuario lo edite en Tiled
   y me pase el export) + integrar ese export en `mods/mew_event/data/isla_suprema.lua`.
2. **§1.9 — Fase 2 (bolsa/tienda/PC)**: ~~ver detalle en §1.9 arriba~~ HECHA. Si el usuario
   prefiere que además escriba descripciones **propias** de objeto (mecánicas, en una línea,
   sacadas de lo que `ItemEffects.lua` hace realmente, no de Nintendo) para ocupar el resto de
   la columna nueva, lo agrego — que lo pida.
3. **§1.9 — Fase 4 (PC/caja)**: `BoxMenu.lua`, mismo patrón de panel lateral que las Fases 1/3
   (sprite + tipo del Pokémon resaltado en la caja) usando `src/ui/WidePanel.lua` ya factorizado.

### De vos (decisión / prueba)
3. **§7.2 / §7.3** — playtest real en el juego: (Mew) Mansión → Fuji → marinero → isla → Mew;
   (Oak) lab/rival → Bill → Isla Canela → Lance → Ruta 1 → combate → créditos.
4. **§7.1** — qué eventos nuevos querés además de Mew y Oak.
5. **§7b.4** — ~~guion narrativo en español~~ HECHO (2592/2592). Falta solo tu revisión en juego y ajustes de tono si algo chirría.
6. **§6.1** — probar el modo LAN con 2 instancias.
7. **§1.8 / §1.9 / §1.10** — ~~aviso de MO al interactuar~~ / ~~menús anchos~~ / ~~correr con B~~ HECHOS.
   Falta tu playtest real de los tres en el juego corriendo.
8. **§5** — QoL: ¿subir `textSpeed` a máx, `battleStyle="set"`, `animations`?
9. **§7b.2** — si querés, sigo con las ~800 cadenas de tripas del launcher que quedan sin traducir.
10. **§2.7** — si querés los learnsets/stats *oficiales* de Gen 2/3 (no los inventados por el mod), completá `mods/pokered_plus-worksheet/new_moves.txt` (plantilla ya entregada) y lo cableo.
11. Playtest del combate ancho en la ventana real (yo lo verifiqué con capturas/driver; falta tu ojo en el juego corriendo).
