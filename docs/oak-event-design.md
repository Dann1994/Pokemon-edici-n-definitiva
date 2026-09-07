# Evento secreto del Profesor Oak — Cadena de pistas

> Diseño entregado por el usuario. Pendiente de implementar (BACKLOG §7.3).
> El equipo de Oak ya existe en los datos del juego original (contenido
> "cortado"); aquí se usa como entrenador + script de evento.

## Principio fundamental de las pistas

Ningún personaje da directamente la siguiente ubicación. Cada uno da una
pista que el jugador debe **interpretar**. El jugador debe sentir que sigue
una pequeña investigación, no una lista de objetivos en pantalla.

| Personaje | Pista | Se refiere a |
|---|---|---|
| Rival | "Su amigo el Pokémaníaco" | Bill |
| Bill | "El laboratorio más grande de todo Kanto" | Isla Canela |
| Científico | "Los combates más importantes" | Liga Pokémon (Meseta Añil) |
| Lance | "Trabajo de campo en alguna ruta cerca de Pueblo Paleta" | Ruta 1 |
| Oak | "Donde todo comenzó" | Su propio pasado como entrenador |

## Cadena completa

```
COMPLETAR POKÉDEX (150) + LIGA VENCIDA
        ↓
LABORATORIO DE OAK  → Oak no está; el RIVAL está dentro
        ↓  "donde todo comenzó" · "quizá visita a su amigo el Pokémaníaco"
CASA DE BILL
        ↓  "el laboratorio más grande de todo Kanto"
LABORATORIO DE ISLA CANELA  → un CIENTÍFICO
        ↓  "su pasado como entrenador" · "la emoción de los combates más importantes"
MESETA AÑIL  → LANCE fuera; LIGA CERRADA POR MANTENIMIENTO
        ↓  "no sé dónde está" · "trabajo de campo" · "alguna ruta cerca de Pueblo Paleta"
RUTA 1  → OAK
        ↓
REVELACIÓN: Oak fue campeón · el jugador como inspiración · EL DESAFÍO
        ↓
BATALLA CONTRA EL PROFESOR OAK
        ↓
CRÉDITOS  →  partida post-game normal; el mundo vuelve a su estado
```

## 1. Punto de partida — Laboratorio de Oak

**Condición:** Liga Pokémon vencida · Pokédex de Kanto completa (150) · más
cualquier requisito previo que determine el sistema de eventos del proyecto.

Al volver al laboratorio de Pueblo Paleta, **Oak no está**. El **rival** está
dentro y es quien inicia la búsqueda.

> "¡Ah, ahí estás!"
> "¿Ya viste tu Pokédex?"
> "El abuelo se enteró de que conseguiste registrar a los 150 Pokémon."
> "Está realmente impresionado."
> "Quería hablar contigo."
> "Pero cuando llegué, ya se había marchado."

El jugador pregunta dónde está.

> "No tengo idea."
> "Sólo me dijo que iba a estar..."
> "donde todo comenzó."
> "No sé qué quiso decir con eso."
> "Supongo que tendrá algo que ver con alguna de sus viejas historias."

(el rival piensa un momento)

> "Ahora que lo pienso..."
> "Quizá esté visitando a su amigo el Pokémaníaco."

Pista → Bill. No se menciona a Bill directamente.

## 2. Casa de Bill

Al preguntarle por Oak:

> "¿Oak?"
> "Sí, pasó por aquí hace poco."
> "Estuvimos hablando durante un buen rato."
> "Me preguntó algunas cosas sobre mis investigaciones."
> "Últimamente parece bastante interesado en revisar trabajos antiguos."

El jugador pregunta dónde fue. Bill no da una ubicación concreta:

> "Después de eso dijo que tenía que ir a revisar unos datos."
> "Si lo conozco, probablemente haya ido al laboratorio más grande de todo KANTO."

Opcional:

> "Allí tienen instalaciones que nosotros sólo podemos soñar con construir."

Pista → Laboratorio de Isla Canela. No se dice "Isla Canela".

## 3. Laboratorio de Isla Canela

Un **científico** reconoce al protagonista.

> "¡Oh! ¡Eres tú!"
> "El profesor OAK habla mucho de tus progresos."

El jugador pregunta por Oak.

> "Sí, vino hace poco."
> "Estuvo revisando algunos registros antiguos."

No sabe dónde está ahora. Introduce la pista de forma indirecta:

> "Últimamente el profesor parece estar pensando mucho en sus años de juventud."

(el jugador puede preguntar qué quiere decir)

> "¿Nunca te contó?"
> "Antes de convertirse en profesor, OAK era un entrenador bastante famoso."
> "Según los registros antiguos, llegó muy lejos."

(no confirmar todavía que fue campeón)

> "Me resulta extraño verlo interesado otra vez en esas cosas."
> "Siempre pensé que había dejado atrás los combates."

Pista definitiva:

> "Quizá simplemente esté buscando un poco de emoción."
> "Después de todo..."
> "si uno quiere volver a sentir lo que se siente en los combates más importantes..."
> "¿qué mejor lugar que donde se enfrentan los mejores entrenadores de KANTO?"

Pista → Liga Pokémon. No se dice "Ve a la Liga".

## 4. Meseta Añil

**Lance** está fuera de la entrada de la Liga. **La Liga está cerrada
temporalmente** — durante el evento el jugador NO puede acceder a la Liga.

> "¿Vienes a desafiar a la Liga?"
> "Me temo que tendrás que esperar."
> "La Liga POKéMON está cerrada temporalmente."
> "Estamos realizando algunos trabajos de mantenimiento."

El jugador pregunta por Oak.

> "¿El profesor OAK?"
> "No, no lo he visto."
> "Aunque conociéndolo..."
> "seguramente esté haciendo trabajo de campo."
> "Nunca fue de quedarse encerrado en un laboratorio cuando tenía algo interesante que investigar."
> "Si está trabajando en el campo, probablemente esté buscando POKéMON en alguna de las rutas."
> "Quizá deberías buscar cerca de PUEBLO PALETA."

Pista → Ruta 1.

## 5. Ruta 1 — "Donde todo comenzó"

El jugador vuelve a Pueblo Paleta y entra en Ruta 1. **Oak está allí**,
colocado en una zona de la ruta que normalmente no es un punto importante.

La frase "donde todo comenzó" adquiere ahora su verdadero significado: no era
sólo el viaje del jugador, sino el comienzo de la historia de Oak como
entrenador.

## 6. Encuentro con Oak

> "Ah..."
> "Has llegado."

(Oak se gira hacia el jugador)

> "Me preguntaba cuánto tardarías en encontrarme."

El jugador pregunta por qué lo hizo buscarlo por toda la región.

> "Supongo que necesitaba una última excusa para recorrer estos lugares."
> "Pero quería que llegaras hasta aquí por tus propios medios."
> "¿Recuerdas este camino?"
> "Aquí comienza el viaje de todo entrenador."
> "Y, aunque no lo creas..."
> "también comenzó el mío."

## 7. Revelación del pasado de Oak

> "Antes de convertirme en profesor..."
> "yo también fui entrenador."
> "Recorrí KANTO."
> "Combatí contra muchos entrenadores."
> "Y llegué hasta la Liga."

(pausa)

> "Incluso fui campeón."

(no orgulloso — nostálgico)

> "Pensé que alcanzar la cima sería el momento más importante de mi vida."
> "Y durante un tiempo lo fue."
> "Pero después comprendí que no quería seguir combatiendo sólo para demostrar que era el mejor."
> "Quería entender a los POKéMON."
> "Quería saber por qué evolucionaban."
> "Por qué confiaban en nosotros."
> "Qué los hacía diferentes."
> "Así que dejé atrás la vida de entrenador."

## 8. El jugador como inspiración

> "Entonces apareciste tú."
> "Te vi comenzar tu viaje."
> "Te vi enfrentarte a tu rival."
> "Te vi recorrer KANTO."
> "Y finalmente te vi conseguir algo que yo nunca hice."
> "Conociste a todos los POKéMON."
> "Los 150."

(Oak mira al jugador)

> "Durante mucho tiempo pensé que había elegido correctamente."
> "Investigador en lugar de entrenador."
> "Pero cuando vi tu viaje..."
> "recordé cuánto disfrutaba aquello."
> "La emoción."
> "La incertidumbre."
> "No saber quién sería el siguiente rival."
> "La sensación de poner a prueba a un POKéMON y confiar en él."

## 9. El desafío

> "No quiero volver a ser campeón."
> "Tampoco quiero demostrar que soy mejor que tú."
> "Sólo quiero recordar cómo se sentía."

(saca una Poké Ball)

> "Y creo que tú tienes la culpa."
> "Así que..."
> "¿Qué dices?"
> "¿Te gustaría combatir contra un viejo entrenador?"

→ Comienza el combate contra **Profesor Oak**.

## 10. Después del combate

Oak reacciona con alegría **independientemente del resultado** (el evento se
diseña para que el jugador gane).

Si el jugador pierde:

> "He perdido..."
> "¡Ja!"
> "Había olvidado lo bien que se siente esto."
> "Gracias."
> "De verdad."
> "Pensé que esa parte de mi vida había terminado."
> "Pero quizá simplemente la había dejado de lado."
> "No voy a abandonar mis investigaciones."
> "Pero quizá pueda permitirme algún combate de vez en cuando."
> "Gracias por recordármelo."

## 11. Final del evento

Después del combate:

1. Mostrar los créditos del juego.
2. Finalizar la secuencia de créditos.
3. Al cargar la partida, el jugador aparece en su habitación de Pueblo Paleta
   (comportamiento post-Liga normal).
4. Oak vuelve a su laboratorio.
5. La Liga Pokémon vuelve a estar abierta.
6. Lance vuelve a su comportamiento normal.
7. Los científicos de Isla Canela vuelven a sus diálogos normales.
8. Bill vuelve a sus diálogos normales.
9. El rival vuelve a sus diálogos normales.
10. El evento queda marcado como completado.

Diálogo permanente post-evento de Oak (opcional):

> "Creo que voy a entrenar un poco más."
> "No pienso abandonar mi investigación."
> "Pero después de tantos años..."
> "supongo que no hay nada malo en disfrutar de un buen combate de vez en cuando."

## Notas de implementación (a resolver al construirlo)

- Reutilizar el sistema de eventos/flags existente (prefijo `MOD_`), como en
  `mods/mew_event`. Nada de sistemas paralelos.
- Equipo de Oak: los datos del juego original tienen su party; localizar y
  reutilizar (`static_battle` / `trainer` + `save_end_battle_text`).
- "Liga cerrada": bloquear el warp de entrada a la sala de la Liga mientras
  el flag del evento esté activo; restaurar al terminar.
- Créditos: verbo/estado de créditos ya existe (Hall of Fame / ending);
  reutilizar el mismo camino que el post-Liga.
- NPCs temporales (rival en el lab, Lance fuera, Oak en Ruta 1): objetos
  nuevos ocultos por flag vía `maps:patch`, patrón del científico de la
  Mansión en `mods/mew_event`.
