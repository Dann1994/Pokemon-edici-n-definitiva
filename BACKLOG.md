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
| 1.1 | Pantalla panorámica (batalla widescreen 304×144) | [opción] `battleLayout="wide"` | NECESITA-DECISIÓN | Ya existe y funciona: OPTIONS → BATTLE LAYOUT → WIDE. **Probé ponerlo por defecto en `SaveData.lua` y rompe `tests/parity_J`**: el layout wide cambia la navegación del menú de ataques (grid en vez de lista, `BattleState:moveGridNavigation`). Hay que decidir si asumimos ese cambio de comportamiento como "el juego de pokered-plus" o lo dejamos como opción. Revertido por ahora. |
| 1.2 | Sistema de colores de Pokémon Amarillo | [fuente/datos] | NECESITA-DECISIÓN | El motor trae `data/palettes_yellow.lua` + `palettes_gbc_yellow.lua` y `PaletteFX.yellowPack()`, pero el modo "OG YELLOW" (`ogred`) sólo se activa en una partida de **Yellow** (`GameVersion.isYellow()`). En Red hay que forzar el pack amarillo en `PaletteFX` — es un parche de fuente, no un switch. Ver §7.1. |
| 1.3 | Modos de color disponibles hoy | [opción] `colors` | INFO | `ogred / gbc / redpp / og / og_inv / gbc_inv / classic` (`PaletteFX.MODES`). `gbc` (Advanced GBC) es el default actual. |

## 2. Tipos y tabla de tipos

| # | Cambio | Vía | Estado | Notas |
|---|---|---|---|---|
| 2.1 | Añadir tipo **HADA (FAIRY)** | [mod] `type_chart:register` | LISTO-PARA-REVISAR | `mods/pokered_plus/data/types_modern.lua`. Tipo + matchups aditivos completos. Test verde. |
| 2.2 | Añadir tipo **ACERO (STEEL)** | [mod] | LISTO-PARA-REVISAR | Íd. Resistencias completas de Steel + inmunidad a Poison. Test verde. |
| 2.3 | Añadir tipo **SINIESTRO (DARK)** | [mod] | LISTO-PARA-REVISAR | Íd. Dark↔Psychic/Ghost/Fighting/Bug/Fairy. Test verde. |
| 2.4 | Reasignar especies a los tipos nuevos | [mod] `pokemon:patch` | LISTO-PARA-REVISAR | Aplicado (tipos modernos canónicos): CLEFAIRY, CLEFABLE → FAIRY puro; JIGGLYPUFF, WIGGLYTUFF → NORMAL/FAIRY; MR_MIME → PSYCHIC/FAIRY; MAGNEMITE, MAGNETON → ELECTRIC/STEEL. Sin candidatos Kanto para DARK. **Confirmar: ¿Clefairy pura Hada o Normal/Hada?** |
| 2.5 | "Actualizar tabla de tipos" a la moderna (Gen 6) | [mod] `type_chart:override` | NECESITA-DECISIÓN | Reescribir matchups vanilla de Gen 1: Bug↔Poison 2× → 0.5×, Ice→Fire ½, Ghost↔Psychic, Poison→Bug… Cambio de balance grande, **no aplicado**. Se haría por `override("ATK>DEF", {multiplier=N})` (escala ×10). Pendiente tu OK. |
| 2.6 | **Split físico/especial por movimiento** (moderno) | [mod] `moves:patch` | LISTO-PARA-REVISAR | El motor YA lo soportaba (`src/battle/Damage.lua:143`). `mods/pokered_plus/data/move_categories.lua` puebla `category` en los 165 movimientos (categorías Gen 4+ de PokeAPI). 164 aplicados (STRUGGLE está reservado por el motor). Test verde. |

## 3. Corrección de bugs conocidos

### 3.1 Bugs de batalla → ruleset `modern` (en `mods/pokered_plus`)

Registrado vía `mod.content.rulesets:register("modern", {...})` con todos los
flags en su valor "arreglado". **Estado: LISTO-PARA-REVISAR** — aparece en
OPTIONS → RULESET → MODERN. Falta decidir si lo hacemos el ruleset por defecto
(hoy el default sigue siendo `gen1_faithful`). Test verde.

| Bug | Flag | Estado |
|---|---|---|
| Fallo 1/256 en moves de 100% precisión | `oneIn256Miss=false` | LISTO-PARA-REVISAR |
| Focus Energy **divide** el crítico ×¼ en vez de ×4 | `focusEnergyBug=false` | LISTO-PARA-REVISAR |
| Críticos ignoran los stat stages | `critIgnoresStages=false` | LISTO-PARA-REVISAR |
| Críticos usan velocidad base, no la actual | `critUsesBaseSpeed=false` | LISTO-PARA-REVISAR |
| Enemigos con PP infinito (nunca Struggle) | `enemyUnlimitedPP=false` | LISTO-PARA-REVISAR |
| Hyper Beam no recarga si el objetivo cae | `hyperBeamSkipRechargeOnKO=false` | LISTO-PARA-REVISAR |
| Residuales (veneno/quemadura/drenadoras) tras cada move en vez de fin de turno | `residualAfterMove=false` | LISTO-PARA-REVISAR |
| Re-aplicación de badge boost al bajar/subir stats | `badgeBoostReapplyBug=false` | LISTO-PARA-REVISAR |
| "Daño 0 = fallo" | `zeroDamageMiss=false` | LISTO-PARA-REVISAR |
| Penalización de status "horneada" en el stat | `statusPenaltyIsBaked=false` | LISTO-PARA-REVISAR |

### 3.2 Bugs de la lista del usuario (mapas / objetos / menús) → revisar vs `tests/parity_*`

El motor **ya reproduce a propósito** muchos glitches vía tests de paridad
nombrados por número de bug. Hay que ver, uno por uno, si está reproducido
(y con qué flag/opción se desactiva) o si hay que parchearlo en `src/`.
Referencia de cómo se arreglan en asm: **shinpokered** (jojobear13 / CyanSMP64),
rama "Lite".

| Bug reportado | ¿Dónde se toca? | Estado |
|---|---|---|
| Surfear/pescar sobre estatuas de Rhydon (gimnasios / Alto Mando) — tiles de estatua comparten ID con agua | `src/world/Collision.lua` + `data/generated/tilesets.lua` (behaviour de tile) | PENDIENTE — verificar si `parity_*` ya lo cubre |
| Surfear desde tierra en costas de Cinnabar / Seafoam (base del "Old Man glitch" / MissingNo) | `src/world/Collision.lua` / `Encounter.lua` | PENDIENTE — hay `parity_cinnabar_east_surf.lua`, `parity_seafoam_holes.lua`, `parity_surf_rod_refusal.lua`: revisar |
| Salto de repisa hacia el este (Ruta 4) deja atravesar pared | `src/world/` salto de ledge | PENDIENTE — hay `parity_ledge_seam_hop.lua`, `parity_ledge_*`: revisar |
| Caminar por paredes tras la Zona Safari (guardar, 500 pasos, romper colisión) | contador de pasos Safari + warp | PENDIENTE — hay `parity_static.lua` / safari step tests: revisar |
| X-Accuracy salta toda comprobación de precisión (incl. OHKO como Fissure/Guillotine) | `src/battle/MoveEffects.lua` / item effect X_ACCURACY | PENDIENTE |
| Poké Flauta no limpia el contador de turnos de sueño | `src/battle/Status.lua` sueño + item PokeFlute | PENDIENTE |
| Piedras evolutivas en combate de entrenador corrompen stats temporalmente | item effect de evolution stones en batalla | PENDIENTE |
| Repelente: contador de pasos se congela / gasta doble al surfear | `src/world/` conteo de pasos tierra vs agua | PENDIENTE |
| Softlock al sacar de guardería un Pokémon nivel 1 (curva Medium Slow) | `src/pokemon/Growth.lua` / daycare | PENDIENTE — hay `parity_daycare.lua`: revisar |
| Barra de HP tarda "una eternidad" en mons con mucha vida | `src/ui/` rutina de animación de barra de HP | PENDIENTE — hay `parity_party_hp_bar_palette.lua`, `low_health_alarm`: revisar animación |

*(Anotado: el usuario dejará más errores para sumar a esta tabla.)*

## 4. Sprites y gráficos

| # | Cambio | Vía | Estado | Notas |
|---|---|---|---|---|
| 4.1 | Reemplazar sprites de Pokémon por los de **Amarillo** | [datos] extractor | NECESITA-DECISIÓN | La ROM de Yellow ya está (`C:\...\Roms\Gb`). Yellow tiene su propio ROM de front sprites (retoques en varios). Opciones: (a) importar Yellow y que el extractor de Red use su banco de sprites; (b) mod GRAPHICS que sobrescriba `assets/generated/sprites/*`. Hay `assets/generated/sprites/back/` y `/front/`. |
| 4.2 | **Mini sprites** (iconos de menú estilo Gen 2) para los 151 | [datos/mod] desde `cRz-Shadows/Pokemon_Yellow_Legacy` | FUTURO | Anotado como mejora futura. Gen 1 tiene sólo ~10 iconos genéricos (`data/generated/icons.lua`). Sacar los 151 mini-sprites de Yellow Legacy y meterlos como set nuevo. |
| 4.3 | Mejoras de calidad de vida del repo | [opción/mod] | EN CURSO | Ver §5. |

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

## 8. Ya aplicado en el fork (infra)

- `git`: fork completo (1541 commits), remoto `upstream`, rama `pokered-plus`. Ver `FORK.md`.
- `Jugar Pokemon Red.bat` — lanzador directo.
- Toolchain: Python 3.12, LÖVE 11.5, LuaJIT 2.1. Shims `python`/`python3` en
  `C:\Users\dani_\bin` apuntando al Python real (el de la Store no sirve).
  `modkit` necesita `MODKIT_LUAJIT` o luajit en PATH:
  `export MODKIT_LUAJIT="/c/Users/dani_/AppData/Local/Programs/LuaJIT/bin/luajit.exe"`.
- ROM de Red verificada e importada.
- **`mods/pokered_plus`** (v0.1.0) — el mod de trabajo del fork. `modkit validate`
  + `modkit lint` + `tests/pokered_plus_test.lua` en verde. Contiene: split
  físico/especial, tipos FAIRY/STEEL/DARK, ruleset `modern`. Se activa desde
  MOD MANAGER (F10) o la pestaña MODS del launcher.
- Baseline de tests: `luajit tests/run_tests.lua` da ~11 fallos preexistentes
  (audio ausente del `data/generated/` del repo, detección de FPS headless,
  `python3` para unos tests de modkit) — no son regresiones nuestras.

---

## Decisiones que necesito de vos (resumen)

1. **§2.4** — lista final de qué especie recibe qué tipo (¿Clefairy pura Hada o Normal/Hada?, etc.).
2. **§2.5** — ¿aplicamos la tabla de tipos Gen 6 completa (cambia balance de todo el juego) o sólo añadimos las interacciones de los tipos nuevos?
3. **§1.2 / §7.1** — colores de Amarillo en Red: ¿vale un parche de fuente en `PaletteFX`?
4. **§4.1** — sprites de Amarillo: ¿importación cruzada o mod de gráficos?
5. **§5** — qué QoL activar por defecto (textSpeed máx, battleStyle SET, etc.).
6. **§7.2** — documento del evento de Mew.
