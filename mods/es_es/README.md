# Español (España)

Traducción al español de España para el fork pokered-plus. Mod de tipo
`LANGUAGE` (funciona también en juego online).

## Qué traduce

| Catálogo | Contenido | Estado |
|---|---|---|
| `lang/move_names.lua` | Los 165 movimientos | ✅ completo (glosario oficial) |
| `lang/type_names.lua` | Los 15 tipos | ✅ |
| `lang/item_names.lua` | Objetos (pociones, balls, piedras, llaves…) | ✅ ~70 |
| `lang/trainer_names.lua` | Clases de entrenador (Cazabichos, Motorista…) | ✅ |
| `lang/status_labels.lua` | ENV / QUE / PAR / DRM / CON en el HUD | ✅ |
| `lang/strings.lua` | Interfaz y mensajes del sistema de combate | ✅ ~115 |
| `lang/dialogue.lua` | El guion narrativo (2592 líneas) | ⬜ vacío → se ve en inglés |
| `lang/species_names.lua` | (no se incluye: en Gen 1 los Pokémon conservan su nombre en inglés) | — |

Todo lo que quede vacío cae de vuelta al inglés, así que el juego es
jugable en cada punto. El guion (`dialogue.lua`) es un trabajo aparte: el
inglés de referencia está en `../es_ES-worksheet/` (fuera del mod, no se
sube a git). Rellená claves y se aplican en el siguiente arranque.

## Fuente

- Nombres (movimientos, objetos, tipos): datos de glosario de PokéAPI
  (locale `es`) y WikiDex/Pokéxperto. Son términos sueltos de referencia.
- Interfaz y mensajes de combate: traducción funcional propia.

## Fuente tipográfica

Usa la TTF *Plain Pixel* incluida en el motor (`--pixel-font`), que ya trae
tildes, ñ, ¿ y ¡ — no hace falta hoja de glifos.

## Selección de idioma

Actívalo en el **GESTOR DE MODS** (F10) o en la pestaña MODS del launcher.
Para español latino, activa además `es_419` (ver ese mod).

## Verificar

```sh
luajit mods/es_ES/tests/es_ES_test.lua
```
