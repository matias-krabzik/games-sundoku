# Tareas, dependencias y aceptación

Estado al 24/09/2026: T01–T09 y T11 integradas. Hay 63 rondas puntuables más el ejemplo adicional, lápiz protegido por progreso, navegación, tutorial y recap. T10 tiene composición y recursos RGBA en revisión; T12 tiene pruebas automáticas y DEV, con QA físico pendiente. T13 conserva la música y licencias existentes. Ver [entrega, evidencia y guía DEV](07-entrega.md).

## Orden de trabajo

| ID | Tarea | Depende de | Entregable revisable / condición de cierre |
| --- | --- | --- | --- |
| T01 | Identidad de mundos y actualización de catálogo | — | Catálogo del bosque definido y añadido a guardados antiguos de forma idempotente. Progreso del valle y partida rápida conservados. |
| T02 | Generalizar acceso a niveles y progreso | T01 | Abrir un nivel mediante worldId/levelId; títulos, rondas, último nivel y recap corresponden a su mundo. El tutorial antiguo solo se inicia en el valle. |
| T03 | Navegación entre mundos y mapa provisional | T02 | Sol del valle conectado, selector de mundos, último mundo visitado y 21 nodos con `Text`. Fondo sencillo y superficies actuales. |
| T04 | Entrada, guardado y render de notas | T02 | Lápiz con desbloqueo global o permiso local de práctica, miniaturas y lectura ampliada; añadir/quitar/borrar/reanudar sin afectar respuestas o puntuación. |
| T05 | Recompensa y disponibilidad del lápiz | T03, T04 | Se obtiene al completar las tres rondas del juego 1. Aviso de una sola vez, acceso posterior en aventura y partida rápida. |
| T06 | Producir tablero y guion didáctico | — | Tablero adicional fijo con A/B y secuencia validada; texto definitivo del paso 5. No necesita arte final. |
| T07 | Tutorial de entrada, práctica y agenda | T03, T04, T06 | Entrar al bosque enseña notas; «Practicar» inicia el juego 1 con permiso local. Conserva estado al salir y permite repaso aislado sin repetir la primera ejecución. |
| T08 | Curar las 63 rondas del recorrido | T06 | 63 definiciones puntuables más el ejemplo didáctico: 64 en total. Fichas y validación por objetivo; revisar los primeros juegos antes de completar el lote. |
| T09 | Composición y prototipo de capas del bosque | T03 | Recorrido de tres tramos probado con 21 nodos. Geometría y márgenes de parallax definidos. |
| T10 | Arte final, segmentación y ambiente básico | T09 | Capas con alfa real, uniones continuas, carga acotada, hojas/brisa y funcionamiento con movimiento reducido. |
| T11 | Integrar contenido y cierre del bosque | T07, T08, T10 | Progresión completa de 63 rondas, recap propio y regreso correcto al mapa/home. |
| T12 | Herramientas DEV y regresión completa | T11 | Estados reproducibles de prueba, compatibilidad de guardados, QA en tamaños y plataformas objetivo. |
| T13 | Ajuste final de audio y créditos | T11 | Música seleccionada y transiciones verificadas. Si se sustituyen los sonidos del sol, cerrar su TODO y actualizar fuentes/licencias. |

T06 puede prepararse mientras se generaliza el modelo; T08 y T09 también pueden avanzar de forma independiente una vez cumplidas sus dependencias. Las opciones DEV necesarias para probar cada entrega se incorporan desde T03–T07; T12 comprueba que el conjunto esté completo y que los reinicios sean coherentes.

## Hito funcional inicial (completado)

Objetivo: recorrer **valle → sol → bosque → tutorial de entrada → práctica en juego 1 → anuncio del desbloqueo permanente → juego 2**, con guardado y regreso a la home, usando arte provisional y los dos primeros juegos completos.

Para esta entrega hacen falta T01–T07, el ejemplo didáctico adicional y las seis rondas de los juegos 1 y 2. El mapa puede mostrar el recorrido previsto, pero las rondas no producidas quedan fuera del prototipo accesible. No publicar un mundo que permita entrar en juegos sin contenido.

T01 es el primer cambio concreto: incorporar el concepto de mundo y la actualización aditiva del catálogo, con pruebas de partidas existentes. No generar primero todas las imágenes ni duplicar la pantalla de juego.

## Matriz de aceptación

| Caso | Resultado esperado |
| --- | --- |
| A01 · Partida nueva | Valle disponible; bosque bloqueado; lápiz oculto. |
| A02 · Mundo 1 a 29/30 rondas | Bosque y partida rápida siguen bloqueados. |
| A03 · Completar 30/30 | Bosque y partida rápida disponibles. La revelación del sol respeta su secuencia actual. |
| A04 · Guardado antiguo con valle completo | Conserva progreso, desbloqueos, perfil, puntuaciones y gate celebrado. Bosque disponible sin repetir la recompensa antigua. |
| A05 · Reabrir tras actualizar catálogo | No duplica niveles ni sesiones; tampoco sobrescribe definiciones guardadas. |
| A06 · Fallar la escritura de actualización | Partida anterior intacta; no marca contenido incorporado; reintento posible. |
| A07 · Ir a home antes de entrar al bosque | Partida rápida sigue arriba. Aventura mantiene un destino coherente; el sol conserva su acceso. |
| A08 · Completar dos rondas de juego 1 del bosque | Lápiz disponible allí para practicar; sigue bloqueado en valle y partida rápida. |
| A09 · Ganar su tercera ronda y cerrar antes del aviso | Lápiz disponible en todos los modos al reabrir; aviso pendiente, tutorial ya terminado. |
| A10 · Acceso directo o llamada de notas bloqueada | Antes del desbloqueo solo permite notas en el tutorial autorizado y el juego 1 del bosque tras la lección. No permite saltar la enseñanza por una ruta directa. |
| A11 · Añadir 2, añadir 7, tocar 2 otra vez | Notas `{7}`, sin valor grande, error, premio ni consumo de ayuda. |
| A12 · Anotar sobre pista o respuesta escrita | Rechazado; conserva el número. |
| A13 · Escribir respuesta sobre notas | Valor guardado y notas vacías en la misma operación. |
| A14 · Nueve notas en casilla | Distribución estable 3 × 3, sin superposición; lectura ampliada y semántica correctas. |
| A15 · Toques rápidos / escritura fallida | No pierde toggles confirmados ni avanza el guion sin guardar; puede reintentar. |
| A16 · Pausar, rotar, cambiar de app y reabrir | Conserva notas, modo, selección y paso pertinente; no avanza tiempo o tutorial en segundo plano. |
| A17 · Primera explicación | Siguiente se ve bloqueado hasta terminar texto/animación/acción requerida. Salir y Ajustes siguen accesibles. |
| A18 · Guion de A y B | Los candidatos y la deducción justifican cada frase; colocar B elimina realmente el 7 como candidato de A. |
| A19 · Terminar tutorial | «Practicar» inicia el juego 1 con lápiz habilitado localmente. No traslada notas/valores del ejemplo ni concede puntos, estrellas o desbloqueo global. |
| A20 · Consultar agenda | La copia de repaso no altera la partida, puntos, estrellas ni estado del tutorial obligatorio. |
| A21 · Notas en partida rápida | Disponibles después del desbloqueo; se conservan en una partida rápida ya iniciada. Dificultades y acceso previos no cambian. |
| A22 · Juego 10 del bosque | No dispara el recap del valle ni termina el mundo. |
| A23 · Juego 21, dos rondas ganadas | Mundo todavía en progreso. |
| A24 · Completar 63/63 | Recap del bosque, nombre solo si fue elegido; botones con igual tamaño e iconos, regreso correcto. |
| A25 · Último juego / mundo 3 | No ofrece una navegación a contenido inexistente. |
| A26 · Mapas alternados varias veces | Sin pila de mapas duplicados; conserva destino de aventura y contexto de cada mundo. |
| A27 · Nodos 11–21 | Texto correcto y centrado, estrellas legibles, sin dependencia de PNG numéricos nuevos. |
| A28 · Scroll completo y tilt | Camino, nodos y sol alineados; capas con profundidad diferente; sin bordes vacíos ni costuras. |
| A29 · Movimiento reducido / sensor ausente | Experiencia completa y controles disponibles; sin animaciones obligatorias ni errores de sensor. |
| A30 · Reinicios DEV | Reinicio del bosque conserva valle y partida rápida; reinicio total gestiona dependencias sin progreso incoherente. |
| A31 · Primera entrada al bosque / salir a mitad | Tutorial visible antes del juego 1; retoma el paso al regresar. Tras completarlo no se abre automáticamente otra vez. |
| A32 · Salir de práctica hacia partida rápida | El permiso local no se filtra a otros modos. Al volver al juego 1 conserva sus notas. |

## Verificaciones por capa

- **Dominio/repositorio:** desbloqueos, IDs y prerrequisitos, reconciliación, notas y puntuación, atomicidad y reanudación. Reutilizar guardados de prueba del mundo 1.
- **Contenido:** solución única y secuencias didácticas de las 63 rondas; validación independiente del tablero guiado adicional.
- **Controladores:** modo lápiz, pausas, tutorial persistente, entradas guiadas sin reloj ni puntuación, cancelación al salir.
- **Widgets:** herramientas y estados, notas y semántica, textos escritos, agenda, doble dígito en medallones, recap del mundo correcto.
- **Flujos:** mundo 1 completo → home → bosque → tutorial → práctica del juego 1 → desbloqueo → salir → completar mundo; comprobar partida rápida antes y después de ganar el lápiz.
- **Arte y rendimiento:** revisión manual en app, imágenes sobre fondos de contraste, recorrido de bordes/uniones y perfilado en dispositivos físicos.

Casos de tamaño mínimos: 320 × 568, 390 × 844, 844 × 390, tablet vertical/horizontal y ventana de escritorio redimensionable. Probar texto normal y aumentado al 200 %, interacción táctil, puntero y lector de pantalla en las plataformas que lo soporten.

Ejecutar los análisis y pruebas apropiados al cambio, y volver a ejecutarlos cuando aparezcan nuevas modificaciones o fallos. Las specs no afirman que las verificaciones del bosque hayan pasado: el mundo aún no está implementado.

## Checklist de salida

- [ ] T01–T13 completadas o extras opcionales retirados explícitamente del alcance.
- [ ] El valle y sus guardados conservan el comportamiento aprobado.
- [ ] Las 63 rondas y el tablero didáctico adicional están presentes, versionados y validados.
- [ ] El tutorial utiliza una deducción real y no contiene textos pendientes.
- [ ] El lápiz no modifica respuestas accidentalmente ni cambia recompensas.
- [ ] Progreso y notas sobreviven a interrupciones y fallas de escritura.
- [ ] No hay números ni textos de interfaz incrustados en arte nuevo.
- [ ] Recortes, uniones, navegación y estados bloqueados revisados en app.
- [ ] Rendimiento y accesibilidad documentados en dispositivos de referencia.
- [ ] Audio definitivo y créditos revisados; TODO de sonidos del sol resuelto o registrado como pendiente aceptado.
