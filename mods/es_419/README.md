# Español (Latinoamérica)

Español latinoamericano para el fork pokered-plus. Es un **delta sobre
`es_ES`**: depende de él y sólo cambia lo que difiere en la traducción
latina de *Leyendas Pokémon: Z-A*.

## Qué cambia frente a es_ES

| Catálogo | Cambio |
|---|---|
| `lang/move_names.lua` | Los 165 movimientos con el nombre neutro/latino (p. ej. Placaje → Tacleada, Rayo → Atactrueno, Danza Espada → Danza de Espadas) |
| `lang/type_names.lua` | Lucha → **Pelea**, Bicho → **Insecto** |
| `lang/item_names.lua` | Poké Ball → Pokébola, Super Ball → Superbola, Ultra Ball → Ultrabola, Master Ball → Masterbola, Safari Ball → Safaribola |
| `lang/strings.lua` | «superefectivo» / «no muy efectivo», «pelear» |

Todo lo demás (objetos restantes, clases de entrenador, interfaz, guion)
lo aporta `es_ES`.

## Fuente

Nombres de la traducción latinoamericana usada desde *Leyendas Pokémon:
Z-A* (PokéAPI locale `es`, contrastado con la lista de diferencias
ES/LATAM de Pokéxperto). Glosario de referencia.

## Selección de idioma

Activa `es_419` en el **GESTOR DE MODS** (F10). Al depender de `es_ES`,
éste se activa solo. Con sólo `es_ES` activo tenés español de España.

## Verificar

`luajit mods/es_ES/tests/es_ES_test.lua` cubre ambos.
