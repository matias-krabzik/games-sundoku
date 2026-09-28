# Mundo 2 · Bosque de Otoño

Especificaciones para revisión · 24 de septiembre de 2026.

El segundo mundo ya está integrado: 21 juegos, tutorial de entrada, práctica y desbloqueo del lápiz, navegación y recap propios. La [entrega y guía de prueba](07-entrega.md) describe la implementación, capturas, controles DEV y verificaciones. Las specs originales se conservan como referencia de producto; la composición del bosque sigue disponible para revisión artística. Incluye también la [propuesta inicial de anotaciones](ui-proposal/README.md).

## Experiencia propuesta

Tras completar el Valle del Sol, el jugador puede cruzar su arco y entrar en un bosque natural de hojas ocres, arroyo y claros soleados. Al entrar por primera vez ve un tutorial para aprender a usar las anotaciones. Después practica con ellas durante las tres rondas del juego 1. Al terminarlo recibe el anuncio de que ya están desbloqueadas y puede utilizarlas cuando quiera.

El bosque tiene **21 juegos de 3 rondas: 63 sudokus**. Es la interpretación de «un primer nivel y luego unos veinte»: el juego 1 permite practicar con la herramienta y la desbloquea permanentemente; los juegos 2–21 desarrollan su uso. Se propone un tablero adicional para la enseñanza de entrada, sin puntos ni estrellas. El mapa crece; los tableros siguen siendo sudokus clásicos de 9 × 9.

## Lectura

| Documento | Qué define |
| --- | --- |
| [01 · Producto y anotaciones](01-producto.md) | Acceso al mundo, desbloqueos, navegación, controles y reglas de las notas. |
| [02 · Tutorial y textos](02-tutorial.md) | Pasos sobre el tablero, textos infantiles, reanudación y repaso. |
| [03 · Recorrido y sudokus](03-niveles.md) | Los 21 juegos, objetivos por ronda y criterios para seleccionar tableros. |
| [04 · Implementación y guardado](04-implementacion.md) | Cambios sobre el código actual, soporte de varios mundos y compatibilidad de partidas. |
| [05 · Arte, mapa y movimiento](05-arte.md) | Identidad visual, producción por capas, mapa largo, parallax y rendimiento. |
| [06 · Trabajo y aceptación](06-tareas-y-validacion.md) | Tareas en orden, dependencias, entregables y casos que deben verificarse. |

## Confirmado y propuesto

| Estado | Decisión |
| --- | --- |
| Solicitado | Mundo mayor que el primero; anotaciones desbloqueadas después del primer nivel; unos veinte niveles adicionales. |
| Solicitado | Tutorial de anotaciones al entrar en el mundo, uso durante el primer juego y anuncio del desbloqueo permanente al completarlo. |
| Dirección aceptada | Bosque de Otoño natural: entrada del bosque, arroyo y gran claro. |
| Base propuesta para dimensionar | 21 juegos, 3 rondas por juego, 63 tableros. La numeración visible empieza en 1 dentro de cada mundo. |
| Propuesta funcional | Anotaciones manuales, sin rellenado ni eliminación automática; disponibles también al volver al mundo 1 y en partida rápida tras desbloquearlas. |
| Propuesta didáctica | Tutorial de entrada con tablero de ejemplo separado; primera ejecución guiada y repasos posteriores libres. |
| Propuesta de contenido | Tableros seleccionados y validados antes de publicar, con solución única y deducciones enseñadas. |

El estado implementado y los ajustes pendientes de validación están registrados en [07 · Entrega](07-entrega.md). Se mantiene separado de la historia extensa archivada para la versión 2.0.

## Alcance

Incluye catálogo y navegación de dos mundos, mapa nuevo, lápiz, representación y persistencia de notas, tutorial de entrada, práctica en el juego 1, agenda de repaso, 63 rondas puntuables y un tablero didáctico adicional, recap del bosque, controles de desarrollo y verificaciones.

Quedan fuera una campaña narrativa extensa, nuevos personajes o jefes, vidas, compras, clasificaciones, notas automáticas, técnicas avanzadas de sudoku y un mundo 3. La historia completa archivada para la versión 2.0 no se reactiva con estas specs.

## Estado de implementación

T01–T09 y T11 están integradas. T10 cuenta con arte RGBA y ambiente funcional, pendientes de validación artística final. T12 incluye pruebas automatizadas y herramientas DEV; queda QA en dispositivos físicos. T13 reutiliza el audio licenciado existente y conserva el TODO de los sonidos del sol.

## Decisiones que revisar en el prototipo

- Si 63 rondas ofrecen suficiente variedad sin alargar demasiado el recorrido.
- Legibilidad de nueve notas pequeñas por casilla en teléfonos; la propuesta incluye lectura ampliada de la casilla seleccionada.
- Intensidad de la ayuda y dificultad de los últimos juegos, a partir de pruebas de juego.
- Aspecto final del lápiz y de la entrada al bosque.
- Selección de música y sonidos. Sigue pendiente [cambiar los sonidos del sol](../audio/sound-effects-credits.md).
