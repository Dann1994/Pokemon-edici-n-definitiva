# pokered-plus — fork de gen1recomp

Fork personal del motor [gen1recomp](https://github.com/bryanthaboi/gen1recomp)
(Lua + LÖVE2D, licencia MIT) para construir una versión de Pokémon Red con
mejoras de calidad de vida, manteniendo el juego base jugable al 100%.

## Ramas y remotos

| | |
|---|---|
| `upstream` | `github.com/bryanthaboi/gen1recomp` — el proyecto original, solo lectura |
| `dev` | espejo local de `upstream/dev`, no se toca |
| `pokered-plus` | rama de trabajo, todos los cambios propios van aquí |

## Traer actualizaciones del upstream

```sh
git fetch upstream
git checkout dev && git merge --ff-only upstream/dev
git checkout pokered-plus && git merge dev
# resolver conflictos (más probables cuanto más se toque src/ del core)
```

## Estrategia de modificación (menor fricción primero)

1. **Config** — `src/battle/rulesets/*.lua`, movesets/tipos en el extractor.
   Sobrevive a los merges.
2. **API de mods** — `src/mods/`, hooks `Runtime.call`. Sobrevive a los merges.
3. **Editar el fuente** — sin límites, pero genera conflictos al mergear.
   Mantener los cambios pequeños y localizados.

## Datos generados

`data/generated/` y la cache en `%APPDATA%/LOVE/pokemon-love2d/` se regeneran
desde la ROM del jugador (`tools/build_data.py` / importador). Están en
`.gitignore`. Para cambiar datos de forma permanente: editar el extractor o
una capa de override al cargar, nunca el archivo generado.

## Lanzar

`Jugar Pokemon Red.bat` — abre Red directo. Requiere LÖVE 11.5 instalado y la
ROM ya importada.
