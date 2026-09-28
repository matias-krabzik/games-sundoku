# Recorrido y contenido de los 21 juegos

Estado: propuesta de contenido; los títulos son editables antes de producir el mapa final.

## Criterio didáctico

Todo el mundo utiliza sudoku clásico de 9 × 9 con bloques de 3 × 3. «Más grande» se refiere al recorrido. Las notas reducen la carga de recordar posibilidades; fuera del tutorial no se exige una cantidad de anotaciones para ganar.

Las técnicas objetivo son candidatos de una casilla, descarte por fila/columna/bloque y detección de un único lugar para un número. No introducir pares, cadenas o suposiciones necesarias para completar un tablero. La solución debe poder justificarse con lo enseñado.

Cada juego contiene tres rondas con una intención distinta: presentar o recuperar una idea, practicarla en otra posición y aplicarla con menos guía. La dificultad no aumenta simplemente quitando más números.

## Catálogo propuesto

| Juego | Nombre | Ronda 1 | Ronda 2 | Ronda 3 |
| --- | --- | --- | --- | --- |
| 1 | La entrada del bosque | Tras el tutorial de entrada, practicar anotando dos posibilidades. | Alternar notas y respuestas en otra zona. | Revisar una nota tras una deducción sencilla; al ganar se desbloquea el lápiz permanentemente. |
| 2 | Las primeras anotaciones | Usar el lápiz con autonomía en un tablero sencillo. | Anotar dos posibilidades sin guion completo. | Elegir otra casilla donde resulte útil anotarlas. |
| 3 | Bajo las hojas | Encontrar dos candidatos en una casilla. | Repetir en otra zona del tablero. | Usar notas en dos casillas y continuar con una deducción segura. |
| 4 | El sendero de tierra | Añadir una nota. | Quitar una nota que dejó de ser válida. | Convertir una posibilidad confirmada en respuesta. |
| 5 | El viejo tronco | Resolver casillas evidentes antes de anotar. | Elegir dónde conviene guardar posibilidades. | Repaso libre corto. |
| 6 | Hojas al viento | Colocar un número y revisar una nota de su fila. | Revisar dos casillas relacionadas. | Alternar respuesta y anotaciones. |
| 7 | La primera claridad | Descartar por fila. | Encontrar el único lugar de un número en una fila. | Combinar ambos razonamientos. |
| 8 | Junto al arroyo | Descartar por columna. | Detectar el único lugar en una columna. | Combinar columna y fila. |
| 9 | Las piedras redondas | Revisar candidatos de un bloque. | Encontrar un lugar único dentro de un bloque. | Combinar bloque y columna. |
| 10 | El puente de madera | Una casilla con tres candidatos. | Reducir de tres a dos tras un avance. | Llegar a uno y confirmar. |
| 11 | Entre los helechos | Llevar notas en dos zonas. | Resolver primero la zona que ofrece una pista clara. | Volver a las notas pendientes. |
| 12 | La curva del agua | Secuencia corta de descartes. | Una respuesta permite deducir otra. | Cadena breve de deducciones básicas, sin ensayo. |
| 13 | La orilla tranquila | Revisar notas después de resolver varias casillas. | Elegir entre fila, columna y bloque. | Repaso del tramo del arroyo. |
| 14 | Raíces del camino | Menos recordatorios y más elección propia. | Priorizar notas útiles. | Aplicar lo aprendido con otro patrón de pistas. |
| 15 | El sendero que sube | Empezar por una deducción directa. | Resolver una zona con ayuda de notas. | Completar combinando zonas. |
| 16 | Entre las copas | Conservar posibilidades mientras se explora otra parte. | Retomar una casilla pendiente. | Resolver varias casillas relacionadas. |
| 17 | La luz entre ramas | Revisar una fila y un bloque. | Revisar una columna y un bloque. | Distinguir lo confirmado de lo que sigue siendo posible. |
| 18 | Cerca de la cascada | Tablero mixto con decisiones de orden. | Otro patrón con el mismo nivel de lógica. | Aplicar notas con autonomía. |
| 19 | Los árboles antiguos | Recap práctico de candidatos. | Recap de descartes. | Recap de lugares únicos. |
| 20 | El gran claro | Preparación final, dificultad moderada. | Segundo repaso con distribución distinta. | Ronda algo más breve para llegar al cierre con buen ritmo. |
| 21 | El corazón del bosque | Integrar filas y columnas. | Integrar bloques y anotaciones. | Desafío final amable; recap del mundo. |

Tramos visuales: juegos 1–7, entrada del bosque; 8–14, arroyo; 15–21, gran claro. Hay transición de vegetación entre tramos; los nombres no obligan a producir un fondo independiente por juego.

## Producción de tableros

Propuesta inicial: un conjunto curado de **63 definiciones puntuables más un tablero didáctico: 64 definiciones**. El tutorial se presenta al entrar al mundo y no cuenta como una ronda del recorrido. Se pueden obtener mediante herramientas de generación durante desarrollo, pero la selección publicada queda congelada y versionada.

- El tutorial `tutorials/notes/v1/example` es una definición controlada con guion asociado, separada de las sesiones puntuables.
- Las 63 rondas se seleccionan por su recorrido lógico. Las tres primeras ofrecen práctica accesible después de la explicación. No basta con usar los presets difíciles de partida rápida.
- El generador actual de aventura retira hasta 38 números y acepta deducciones básicas; no clasifica oportunidades de anotación ni garantiza los objetivos de esta tabla. Se necesita un informe didáctico por tablero.
- La primera edición puede compartir los tableros entre jugadores. La variedad por jugador mediante transformaciones válidas queda para una mejora posterior; no debe retrasar la validación del tutorial.
- Materializar las tres definiciones del juego al iniciarlo, en la misma operación que prepara su sesión. Al reanudar se usan esas definiciones, no se regeneran.
- No cambiar una definición que ya esté guardada bajo el mismo identificador. Si hay correcciones posteriores, asignar una versión nueva para partidas aún no iniciadas y conservar las partidas existentes.

## Ficha de cada ronda

Cada registro de autoría necesita: ID, versión, estado inicial, solución, objetivo, dificultad de puntuación, secuencia de deducciones de referencia, casillas/etapas donde las notas ayudan, número máximo de candidatos en esas etapas y resultado de validación.

La cantidad de pistas y los tiempos de resolución son medidas de ajuste, no las únicas reglas de dificultad. Las franjas de duración se definirán con pruebas de juego; no se añaden límites de tiempo a la experiencia.

## Criterios de aceptación de contenido

1. Tablero válido y solución única, comprobada de forma independiente al proceso que lo produjo.
2. Resoluble con las deducciones permitidas y sin consultar la solución como «ayuda» del solver didáctico.
3. Las oportunidades prometidas en su ficha realmente aparecen en la secuencia de referencia.
4. Los juegos 1–4 permiten practicar con pocas notas; los siguientes amplían la cantidad de relaciones, sin presentar una pared de nueve candidatos por casilla al comenzar.
5. El último tramo combina herramientas conocidas y conserva ayudas y errores sin límite; no introduce una penalización nueva por sorpresa.
6. Ninguna ronda gana automáticamente por anotar; la victoria requiere valores completos y correctos.
7. Hay variedad de distribución de pistas y casillas objetivo entre rondas consecutivas; no se repite el mismo tablero con un título diferente.
8. El tablero adicional del tutorial pasa todos los requisitos de [02 · Tutorial](02-tutorial.md), incluidas interrupción y reanudación.

## Puntuación y repetición

Se conserva la puntuación actual de valores correctos, rachas y ayudas. Los tableros del bosque usarán inicialmente dificultad de puntuación `easy` para no cambiar la economía al enseñar una herramienta; ajustar multiplicadores es una decisión separada.

Completar cada sudoku concede una estrella. No se introduce repetición de niveles terminados para acumular recompensas: el mapa muestra su resumen y la práctica adicional queda en partida rápida. El repaso de la agenda es independiente y no concede premios.
