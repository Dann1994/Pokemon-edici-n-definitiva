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
| 1.1 | Pantalla panorámica (batalla widescreen 304×144) | [fuente] `SaveData.lua` | HECHO | `battleLayout = "wide"` por defecto (commit). Cambia la navegación del menú de ataques a grid — a corregir después. Tests de paridad afectados repinneados a `"og"`. **Escape:** rama `stock-defaults`. |
| 1.2 | Colores de Pokémon Amarillo en Red | [fuente] `PaletteFX` | HECHO | Nuevo modo de COLORS **`"yellow"`** en `src/render/PaletteFX.lua` (helper `yellowColors()` + `usesYellowCgb` extendido): pinta cualquier juego con las CGBBasePalettes de `data/palettes_yellow.lua` — las paletas Game Boy Color auténticas de Yellow (pueblos, cuevas, menús, barras de HP, sprites de combate). Por defecto en `SaveData.lua`. Otras opciones en OPTIONS → COLORS. **Escape:** rama `stock-defaults`. |
| 1.3 | Texto rápido por defecto | [fuente] `SaveData.lua` | HECHO | `textSpeed = 1` (FAST). Test repinneado. |
| 1.5 | Título: "Red Version" → "EDICIÓN DEFINITIVA" | [mod] `field.boot.title.versionRibbon` | HECHO | `mods/pokered_plus` v0.5.0. `tools/pokered_plus_title_ribbon.py` genera la tira 1-bit (fuente Plain Pixel) en `assets/title/`; `TitleState` la centra en y=64 y la colorea con la paleta LOGO1 (roja en el título de Red). |
| 1.4 | Sprites de Pokémon de Amarillo sobre Red | [datos] overlay de cache | HECHO | `scripts/pokered_plus_yellow_gfx.lua` copia los 305 PNGs de batalla de Yellow sobre el cache de Red y ajusta `frontSize` de las 7 especies que cambiaron de tamaño. **Re-ejecutar tras cada re-importación de Red.** `--revert` para deshacer. |

## 2. Tipos y tabla de tipos

| # | Cambio | Vía | Estado | Notas |
|---|---|---|---|---|
| 2.1–2.3 | Tipos **HADA / ACERO / SINIESTRO** | [mod] `type_chart` | HECHO | `mods/pokered_plus/data/types_modern.lua`. Registrados con la tabla Gen 6 completa. Test verde. |
| 2.4 | Reasignar especies a los tipos nuevos | [mod] `pokemon:patch` | HECHO | Tipos Gen 6 canónicos: CLEFAIRY, CLEFABLE → HADA puro (como en Gen 6); JIGGLYPUFF, WIGGLYTUFF → NORMAL/HADA; MR_MIME → PSÍQUICO/HADA; MAGNEMITE, MAGNETON → ELÉCTRICO/ACERO. |
| 2.5 | Tabla de tipos completa Gen 6 | [mod] `type_chart:override` | HECHO | `data/types_modern.lua` `chart` — 120 celdas para los 18 tipos, sobrescribe las filas vanilla de Gen 1. Corrige el bug Fantasma→Psíquico (0→2×), nerfea Bicho↔Veneno, Fuego resiste Hielo, quita `POISON>BUG`, etc. Test verde. |
| 2.6 | **Split físico/especial por movimiento** | [mod] `moves:patch` | HECHO | `data/move_categories.lua` — 164/165 movimientos con su categoría Gen 4+ (STRUGGLE reservado por el motor). Test verde. |

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
| 4.1 | Sprites de Pokémon de **Amarillo** sobre Red | [datos] overlay | HECHO | `scripts/pokered_plus_yellow_gfx.lua`: copia los 305 PNGs de `battle/front` + `battle/back` de Yellow sobre el cache de Red y corrige `frontSize` de 7 especies (dewgong, doduo, dugtrio, gastly, gengar, haunter, mankey). Re-ejecutar tras re-importar Red. Guarda backup en `battle_red_backup/`; `--revert` restaura. Falta la solución permanente (patch al extractor) para que sea automático. |
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
| 7.2 | **Captura de Mew** | [mod] | NECESITA-DECISIÓN | El usuario pasará un documento con el diseño. `example_mew_starter` ya muestra cómo inyectar Mew en el guion de Oak's Lab. |
| 7.3 | **Batalla contra el Profesor Oak** | [mod/fuente] | PENDIENTE | El equipo de Oak existe en los datos del juego original pero nunca se usa. Se puede añadir como trainer + script de evento. Referencia: es un contenido "cortado" bien documentado. |

## 7bis. Idiomas

| # | Cambio | Vía | Estado | Notas |
|---|---|---|---|---|
| 7b.1 | Selección de idioma | [mod] `LANGUAGE` | HECHO | El motor ya trae el sistema: cada traducción es un mod `category:LANGUAGE` + `language:true`. Se elige en el GESTOR DE MODS (F10) / pestaña MODS. Funciona en online. |
| 7b.2 | **Español (España)** — `mods/es_ES` | [mod] `modkit translation` | PARCIAL | `--pixel-font` (tildes/ñ/¿¡ sin hoja de glifos). Traducido: 165 movimientos, 15 tipos, ~70 objetos, clases de entrenador, HUD de estado, ~115 cadenas de interfaz/combate. **Sin traducir: el guion narrativo** (`dialogue.lua`, 2592 líneas) — cae al inglés; el inglés de referencia está en `es_ES-worksheet/` (no se sube). No reproduje el guion oficial de Nintendo; se rellena a mano o con MT. Nombres = glosario de referencia (PokéAPI/WikiDex). Test 18/18. |
| 7b.3 | **Español latino** — `mods/es_419` | [mod] delta sobre es_ES | HECHO (nombres) | Depende de `es_ES` y cambia los 165 movimientos + tipos (Insecto/Pelea) + Poké Balls (Pokébola…) a la traducción latina de **Leyendas Pokémon: Z-A**. Fuente: PokéAPI locale `es` (= la traducción de Z-A) contrastado con Pokéxperto. |
| 7b.4 | Guion narrativo en español | — | PENDIENTE | ~4500 líneas (2592 de `dialogue.lua` + narrativa de `strings.lua`). No reproduzco la localización oficial. Opciones: traducción propia incremental, pasada de traducción automática como borrador, o dejarlo en inglés. |
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

## Pendiente de vos

1. **§1.2** — colores de Yellow en Red: confirmar el parche de fuente en `PaletteFX`
   (los sprites ya están; falta la paleta).
2. **§7.2** — documento del evento de captura de Mew.
3. **§7.3** — detalles de la batalla contra Oak.
4. **§7.1** — qué eventos nuevos.
5. *(§4.2 mini sprites — HECHO)*
