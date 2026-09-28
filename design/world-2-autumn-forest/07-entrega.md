# Mundo 2 integrado · 24 de septiembre de 2026

## Qué se puede jugar

Bosque de Otoño tiene 21 juegos y tres rondas por juego. Sus 63 sudokus son contenido fijo versionado, con solución única, resolubles mediante números forzados y con al menos una deducción que permite descartar una de dos anotaciones. Los juegos posteriores se seleccionaron con más oportunidades de este tipo. Conservan la economía de dificultad fácil; la curva se debe ajustar después de probarla con jugadores.

El sol del valle abre el bosque. La primera visita enseña a usar el lápiz con un ejemplo independiente, sin reloj, puntos ni estrellas. El estado del tutorial se guarda después de cada acción. Durante el juego 1 el lápiz tiene permiso local de práctica; sus tres estrellas lo desbloquean permanentemente, también en el valle y en partidas rápidas ya iniciadas. Un aviso pendiente recuerda la recompensa si se vuelve al mapa después de ganarla. El cuaderno del mapa permite repasar las reglas o las anotaciones sin modificar la partida.

El selector de mundos reemplaza el mapa actual, sin acumular mapas en la navegación. Aventura vuelve al último mundo visitado que siga disponible. Cada mundo conserva sus IDs, títulos, progreso y recap. El juego 10 del bosque no finaliza el mundo; el 21 sí. No existe enlace a un mundo 3.

## Probar desde DEV

1. En el mapa del valle: **Preparar entrada al bosque**. Completa el valle, reinicia el bosque y entra en su tutorial. Es una modificación deliberada del progreso de desarrollo.
2. En el bosque: **Repetir entrada con lápiz** permite revisar el tutorial obligatorio.
3. **Completar mundo menos última ronda** deja dos rondas ganadas en el juego 21. Entra al juego y usa la opción DEV existente de completar el tablero menos una casilla para verificar su final real.
4. **Completar nivel al azar** sirve para avanzar al siguiente juego; hacerlo en el primer juego concede el lápiz como consecuencia de sus tres estrellas.
5. Reiniciar un nivel elimina su progreso y los niveles dependientes. Reiniciar el bosque conserva el valle y Partida rápida; reiniciar el valle también invalida el bosque dependiente.

Los controles DEV no se incluyen en las compilaciones de producción. El permiso de notas se comprueba también en el repositorio; activar la UI por sí sola no lo concede.

## Guardados

Se mantiene el esquema 1. Al abrir un guardado antiguo se agregan únicamente las definiciones de niveles ausentes y una revisión de contenido. Se conservan las definiciones existentes, sesiones, nombres de módulos del valle, puntuaciones, preferencias y campos desconocidos. Los tableros del bosque se registran al iniciar cada juego. El acceso a Partida rápida sigue dependiendo exclusivamente del valle.

## Arte y movimiento

Tres recursos RGBA independientes: arboleda, terreno y vegetación cercana. Se componen con el cielo, sendero, arroyo y puente dibujados en Flutter. Se reutilizan las superficies, botones y medallones de SunDoku; los números 1–21 del bosque son `Text`.

La cámara recorre un mundo de proporción 6:1. Las arboledas lejanas se mueven a 0,32×, las intermedias a 0,64×, el camino y sus nodos a 1× y el primer plano a 1,10×. El seguimiento vertical comparte desplazamiento entre el camino y los controles. Hay hojas flotantes y una inclinación suave mediante puntero o acelerómetro; se detienen al ocultar la escena y con movimiento reducido. Los sprites se reutilizan a distintas escalas y posiciones, sin espejar bordes. Esta composición sigue abierta a revisión artística; no pretende ser un panorama final pintado de una sola pieza.

Las texturas se decodifican una vez y se dibuja solo lo visible. La memoria teórica de los tres bitmaps decodificados ronda 14 MiB, sin contar superficies de UI, GPU ni cachés del sistema. El rendimiento en dispositivos físicos aún requiere perfilado.

Se conserva la música de mapa y sus licencias existentes. No se agregaron efectos externos. Sigue abierto el TODO de sustituir los sonidos del sol.

## Evidencia

Resultado de la verificación: 100 pruebas aprobadas en la ejecución conjunta. Tras el ajuste del progreso por mundo en la home, se repitieron las siete pruebas relevantes de navegación y desbloqueo, también aprobadas. Análisis estático sin incidencias en los archivos de esta entrega. Se efectuaron hot restart y hot reload en el simulador iPad conectado.

- Pruebas de contenido: las 63 soluciones, unicidad, resolución lógica y descarte de candidatos.
- Pruebas de guardado: migración, idempotencia, fallo de escritura, reanudación, permisos de práctica y desbloqueo, reinicios independientes.
- Pruebas de UI: texto y botón Siguiente, tamaños 320×568, 390×844, 844×390 y 1024×768, texto al 200 %, navegación desde el sol hasta el primer juego.
- Regresión de mapa, estrellas, recap, puntuación, partidas rápidas y tutorial original.
- [Captura del mapa](art/forest-map-tablet.png), [final del recorrido](art/forest-map-end.png), [tutorial en móvil](art/tutorial-mobile.png).
- [Previews del bosque](../../lib/previews/forest_world_preview.dart).

La revisión con niños, VoiceOver/TalkBack y el perfilado en móviles reales quedan como comprobaciones previas a publicación. Las pruebas automáticas no sustituyen esas verificaciones.
