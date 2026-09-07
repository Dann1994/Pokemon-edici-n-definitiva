# Evento secreto de Mew — Isla del Sur

Documento de diseño del usuario (post-game quest para el fork pokered-plus).
Filosofía: contenido "perdido" de Gen 1. Misterio → descubrimiento → culpa →
redención → legado → encuentro. Frases cortas, estilo Game Boy. La identidad
de **"F."** se deduce antes de confirmarse (F. = Sr. Fuji).

Cadena de lore que conecta: Mansión Pokémon · origen de Mewtwo · pasado de
Fuji · expedición a Sudamérica · Isla del Sur · cartel firmado "F." · Fuji y
Mew · Fuji abandona por culpa · el amor por los Pokémon como requisito del
Mapa Viejo.

---

## Flujo

```
Liga → capturar Mewtwo → Mewtwo en el equipo → Mansión Pokémon 3F
→ aparece un científico → reconoce a Mewtwo y HUYE → leer documentos
→ (expedición de F. / encuentro con Mew / F. se niega a capturarlo /
   entrega ADN / se crea Mewtwo / arrepentimiento / F. se retira con
   Pokémon maltratados) → pistas de que F. es Fuji
→ Pueblo Lavanda: hablar con Fuji → evasivo → menciona una isla sin mapa
→ pone la condición ("conocer a todos los Pokémon", sin decir Pokédex)
→ registrar los 150 de Kanto + Mewtwo en el equipo
→ volver con Fuji → reconoce a Mewtwo (sorpresa, no miedo) → revela que es F.
→ entrega el MAPA VIEJO
→ Ciudad Carmín: mostrar el mapa al marinero → viaje a la Isla del Sur
→ cartel firmado "F." → bosque (pistas de Mew) → estatua → interactuar
→ combate único contra Mew → captura
```

## Etapas y requisitos

**Etapa A — Descubrimiento.** Requisitos: Liga vencida · Mewtwo capturado ·
Mewtwo en el equipo. → aparece el científico + documentos en la Mansión 3F.

**Etapa B — Confianza de Fuji.** Requisitos: 150 de Kanto registrados ·
Mewtwo en el equipo · Etapa A ya activada. → Fuji entrega el Mapa Viejo.

---

## 1. Mansión Pokémon, 3er piso

- **Científico** (objeto nuevo, oculto hasta cumplir requisitos de Etapa A).
  Al hablarle con Mewtwo en el equipo: lo reconoce, entra en pánico, **huye**
  de la habitación (no combate). No explica el origen de Mewtwo.
  > "¿Q-qué...?" / "Ese Pokémon..." / "No puede ser." / "¡Mewtwo!" /
  > "¡¿Cómo lo has conseguido?!" / "¡No debería existir!" /
  > "¡Tengo que irme de aquí!"
- **Documentos** (varios textos breves, no uno gigante; todos firmados "— F.",
  nunca "Fuji"):

  **Doc 1 — INFORME DE EXPEDICIÓN — SUDAMÉRICA**
  > "La expedición fue organizada para investigar antiguas referencias a un
  > Pokémon que, según las leyendas, podía aprender cualquier movimiento." /
  > "Su nombre aparece repetido en numerosos registros antiguos." / "Mew." /
  > "No existían pruebas concluyentes de su existencia." / "— F."

  **Doc 2 — El descubrimiento** (entrada personal, no informe)
  > "Lo encontré." / "Durante semanas pensé que Mew no era más que una
  > leyenda." / "Me equivocaba." / "Mew existe." / "No se comportaba como la
  > criatura peligrosa que algunos esperaban." / "Era curioso." / "Se acercaba
  > cuando menos lo esperaba y desaparecía antes de que pudiéramos seguirlo." /
  > "Con el tiempo comenzó a acercarse a mí." / "Llegué a ganarme su
  > confianza." / "Nunca olvidaré la primera vez que se quedó a mi lado sin
  > intentar escapar." / "— F."
  Rasgos de Mew: curioso, juguetón, travieso, inteligente, majestuoso, no
  agresivo, se acerca por voluntad propia.

  **Doc 3 — La orden**
  > "La orden de mis superiores fue clara." / "Debíamos capturarlo y llevarlo
  > a Kanto." / "Me negué." / "Después de conocerlo, ya no podía verlo como un
  > espécimen." / "Les informé que la expedición había sido un fracaso." /
  > "Mentí." / "Dije que no habíamos encontrado nada." / "Lo único que entregué
  > fueron algunos restos de material genético encontrados durante la
  > investigación." / "No sabía entonces lo que harían con ellos." / "— F."

  **Doc 4 — El proyecto** (tono más oscuro)
  > "Meses después recibí noticias del proyecto." / "Habían utilizado el
  > material genético que entregué." / "Querían crear un Pokémon capaz de
  > superar a todos los demás." / "Entonces comprendí de dónde procedía
  > aquello." / "Habían utilizado el ADN de Mew." / "El proyecto tenía un
  > nombre." / "Mewtwo."

  **Doc 5 — La culpa**
  > "He visto lo que hemos creado." / "Una criatura nacida del deseo de superar
  > a la naturaleza." / "Aunque nunca quise esto, también soy responsable." /
  > "He cometido un pecado que no puedo borrar." / "No permitiré que vuelvan a
  > encontrar a Mew." / "Nunca revelaré dónde lo encontré." / "— F."

  **Doc 6 — La retirada** (pista definitiva sobre Fuji)
  > "He terminado." / "No volveré a trabajar en este proyecto." / "Me marcharé
  > a un lugar tranquilo." / "Lejos de laboratorios y de hombres que ven a los
  > Pokémon como herramientas." / "Me llevaré conmigo a los Pokémon que todavía
  > puedan ser salvados." / "Quizás pueda hacer por ellos algo de lo que no fui
  > capaz de hacer por Mew." / "No sé si algún día podré perdonarme." / "Pero
  > cuidaré de ellos mientras pueda." / "Tal vez sea la única forma que me queda
  > de expiar mi culpa." / "Si alguna vez vuelvo a ver a Mew, espero que pueda
  > perdonarme." / "— F."

## 2. Pueblo Lavanda — Sr. Fuji

**Primera conversación** (tras leer los documentos). Evasivo.
> Jugador: "¿Conoce a un investigador llamado F.?" — Fuji: "¿F...?" / "No sé de
> quién hablas." — (insistir) "Hay cosas del pasado que es mejor dejar atrás." —
> "¿Usted estuvo en Sudamérica?" — "Hace muchos años viajé a lugares muy
> lejanos." / "Pero eso pertenece al pasado."

**Menciona la isla** (tras insistir):
> "Existe una isla que no aparece en los mapas que conocen los entrenadores." /
> "Allí encontré algo que cambió mi vida." / "Desde entonces he intentado
> olvidar aquel lugar." — (¿Mew?) "No." / "De eso no puedo hablar." / "Hay
> cosas que un hombre debe aprender a dejar atrás."

**La condición** (termina sin dar el mapa):
> "Sólo confiaría ese lugar a alguien que comprendiera lo que yo no comprendí
> entonces." / "Alguien que no vea a los Pokémon como simples criaturas que
> coleccionar." / "Alguien cuyo deseo de conocerlos a todos nazca del respeto y
> no de la ambición." / "Si alguna vez conozco a una persona así..." / "Quizás
> pueda confiarle aquello que juré mantener oculto."

**Segunda conversación** (150 registrados + Mewtwo en el equipo). Reconoce a
Mewtwo con sorpresa, no miedo.
> "Mewtwo..." / "Así que finalmente te encontró." / "Durante tantos años me
> pregunté qué había sido de él." / "Los has conocido a todos." / "Uno por
> uno." / "Los has buscado en cada rincón de Kanto." / "Y aun así..." / "Has
> conseguido algo que nosotros nunca pudimos conseguir." / "Has conseguido que
> Mewtwo encuentre su propio camino."
(interpretación de Fuji al verlo viajar voluntariamente; NO afirmar que el
jugador lo "curó".)

**Revelación** (tranquila):
> "Ya no tiene sentido seguir ocultándolo." / "Sí." / "Yo soy F." / "Yo estuve
> allí." / "Yo encontré a Mew." / "Nunca revelé dónde estaba." / "Y jamás lo
> hice." / "Durante todos estos años guardé el secreto." / "No porque quisiera
> regresar." / "Sino porque tenía miedo de que alguien volviera a buscarlo."

**Entrega del MAPA VIEJO** (Key Item):
> "Durante todos estos años guardé este mapa." / "Ahora creo que puedo confiar
> en ti." / "Si decides ir, recuerda esto." / "No vayas a buscar un trofeo." /
> "Ve a conocer al Pokémon que una vez tuve el privilegio de conocer."

## 3. Mapa Viejo (Key Item)

Descripción: "Un mapa antiguo que señala una isla muy lejana." No permite
viajar directamente — el jugador descubre cómo usarlo (llevarlo al marinero).

## 4. Ciudad Carmín — marinero

Al mostrarle el Mapa Viejo:
> "¿Qué es esto?" / "Hace muchos años que no veía uno de estos." / "¿Quieres ir
> allí?" / "No sé qué encontrarás..." / "Pero si el viejo Fuji te entregó ese
> mapa, supongo que tendrá sus razones."
Permite viajar a la Isla del Sur. No menciona a Mew.

## 5. Isla del Sur (mapa nuevo)

Estética Gen 1, pequeña, remota, casi olvidada. Costa de entrada · bosque ·
zonas abiertas · vegetación · pequeñas ruinas · una estatua · caminos
sencillos · pocos/ningún NPC · encuentros salvajes opcionales · música
tranquila/misteriosa. NO una segunda región.

**Cartel de F.** (entrada del bosque, misma firma que los documentos):
> "A quien encuentre este lugar:" / "No intentes capturar aquello que vive
> aquí." / "Algunas cosas deben ser conocidas sin necesidad de ser poseídas." /
> "— F."

**Bosque:** corto y lineal. Pistas de que Mew está cerca (movimiento entre
árboles, sonidos, objetos que parecen movidos, sombras, sensación de ser
observado). No mostrar a Mew antes del encuentro.

**Estatua** (al final del bosque, tipo estatua de gimnasio, Pokémon pequeño
ambiguo — no identificable como Mew):
> 1ª interacción: "Es una estatua muy antigua." / "No reconoces al Pokémon que
> representa."
> 2ª interacción: "La estatua parece mirarte." — o — "..." / "Algo se mueve
> detrás de ti."
Luego: música + transición + encuentro único.

## 6. Encuentro con Mew

- `start_battle`/`static_battle` — Pokémon salvaje normal a efectos de
  combate/captura. Nivel de post-game (reto, pero no absurdamente > Mewtwo).
- Intro especial: "¡Mew apareció!" / opcional "¡Mew te observa con curiosidad!"
- **No** se entrega automáticamente. La captura es la recompensa final.
- Aparece una sola vez tras capturarse. Si es derrotado: según las
  convenciones de legendarios del proyecto (no crear sistema especial).

## Flags (conceptuales — usar el sistema existente, prefijo `MOD_`)

`MEW_EVENT_DISCOVERED` (documentos leídos) · `FUJI_MYSTERY_ACTIVE` (Fuji
reconoció la investigación) · `OLD_MAP_OBTAINED` · `SOUTH_ISLAND_UNLOCKED` ·
`MEW_ENCOUNTER_DEFEATED` (si hace falta distinguir) · `MEW_CAPTURED`.

## Reglas de implementación

1. **Analizar la arquitectura existente ANTES de codificar** (mapas,
   conexiones, NPCs, diálogos, scripts/eventos, flags, variables, key items,
   inventario, Pokédex, encuentros, combates, cambios permanentes del mundo).
2. **Reutilizar** los sistemas existentes; **no** crear sistemas paralelos.
3. Mantener el estilo/recursos coherentes con el proyecto.
4. No romper: Mansión Pokémon, NPCs/diálogos existentes, Pokédex, sistema de
   viajes, puerto de Carmín, encuentros salvajes, combates.
5. No hardcodear: para "los 150", buscar cómo el proyecto representa
   vistos/capturados/Pokédex y usar esa fuente de verdad.

## Lo que NO hacer

Entregar Mew directamente · Fuji cuenta todo de golpe · nombre "Fuji" en los
primeros documentos · Fuji villano · Mew como recompensa por completar la
Pokédex · isla llena de NPCs explicativos · isla gigante · diálogos modernos o
largos · sistemas nuevos sin revisar los existentes · el científico da info
que debería estar en los documentos.
