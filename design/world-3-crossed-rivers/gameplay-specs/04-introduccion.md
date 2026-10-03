# W3-04 · Introducción a tiempo, puntos y vidas

Depende de: [W3-03](03-partida-y-navegacion.md) y D06 cerrada.
Siguiente: [W3-05](05-resultado-animado.md).

## Entrada y estado

La primera entrada a las nuevas reglas del mundo 3 presenta una lección corta.
La ruta normal del santuario y las entradas alternativas (home, mapa, enlace
directo) deben respetar el mismo estado. No abrir una segunda instancia ni saltar
el control de desbloqueo del mundo por una URL directa.

Usar un estado persistido y versionado propio de esta introducción, independiente
de las reglas y anotaciones. Conservar paso al interrumpir. Completar o usar
«Saltar tutorial», según la navegación compartida, reconoce la lección sin dar
puntos, estrellas ni ventajas. No repetirla automáticamente después de reconocida.

Una sesión heredada en curso se reanuda con sus reglas anteriores: no interrumpirla
para imponer las nuevas. Presentar la introducción antes de su primera sesión con
las reglas nuevas. Un repaso desde el acceso de tutoriales existente usa una copia
aislada y no cambia partidas ni el estado de primera entrada pendiente.

## Guion de cuatro pasos

| Paso | Título propuesto | Demostración automática | Mensaje |
| --- | --- | --- | --- |
| 1 | Resuelve a tiempo | Resaltar la cuenta regresiva; mostrar avance y pausa. | «Completa el sudoku antes de que el reloj llegue a cero. El tiempo se detiene al pausar». |
| 2 | Alcanza la meta | Colocar un número correcto; animar puntos hacia el objetivo. | «Completa el sudoku a tiempo y alcanza los puntos de la meta para ganar tu estrella». |
| 3 | Cuida tus vidas | Mostrar tres corazones, una jugada errónea y dos restantes. | «Cada error cuesta una vida. Empiezas con 3; más adelante tendrás 2 y luego 1». |
| 4 | Enciende tu estrella | Tablero completo de demostración y contador cruzando el umbral. | «Al terminar contamos tus puntos. En el último nivel tendrás que resolverlo sin errores ni pistas». |

Los textos son guion de trabajo: ajustar longitud y lectura sin cambiar reglas.
Añadir la explicación de que las notas son libres y las pistas cuestan puntos en
el paso 2, reutilizando los iconos actuales. Indicar vidas renovadas por sudoku
en el paso 3. Mantener cada explicación breve; no crear otra lección extensa.

El ejemplo es didáctico, determinista y separado de la sesión real. No exigir
seleccionar casillas, escribir números, perder vidas o pedir pistas para avanzar.
Reutilizar el componente de resultado de W3-03 en modo demostración; W3-05 podrá
animarlo sin duplicar lógica ni escribir en el repositorio real.

## Composición obligatoria

Referencia: [formato compartido](../../first-experience/implementacion.md#formato-compartido-de-los-tutoriales).

- Progreso segmentado y `TutorialLessonTitle` arriba. Cada paso tiene su título.
- Tablero/demostración en el centro; `TutorialLessonCard` siempre debajo,
  también en horizontal. Ancho máximo compartido de 470 px.
- Títulos Baloo 2, azul `#082A62`, peso 800, 22 px (18 en modo de texto ampliado
  según el componente); explicación de 20 px, peso 800 e interlineado 1,3.
- `TutorialPresentation`, `TutorialStory` y `TutorialActivity` gestionan entrada,
  escritura, demostración y suspensión. No copiar una segunda implementación.
- Mantener la misma escena/tablero montada entre pasos compatibles. Reservar el
  espacio del texto; no reaparecer todo ni mover el tablero por cada explicación.
- Acciones amarillas abajo, dentro de SafeArea. «Siguiente» primero termina las
  animaciones pendientes; otra pulsación avanza. Si ya terminaron, una basta.
- Demostraciones automáticas; avanzar de explicación no requiere jugar. Conservar
  gestos/teclado del componente compartido y el mismo criterio de completar antes
  de avanzar. La última acción explícita abre el nivel o vuelve al repaso.
- No añadir Volver, Pausa ni Configuración en el encabezado de la lección.
- Usar un fondo ilustrado existente del mundo, cargado con el mismo tratamiento
  de los tutoriales actuales. Nunca dejar fondo vacío ni capturar el mapa con UI
  incrustada como nueva imagen.
- Movimiento reducido muestra estados finales legibles; no obliga a esperar.
  Segundo plano suspende escritura y demostración, sin saltarse pasos al volver.

## Pruebas y aceptación

| ID | Caso | Resultado |
| --- | --- | --- |
| T01 | Primera entrada normal o directa autorizada | Una sola introducción antes de jugar con reglas nuevas. |
| T02 | Pasar los cuatro pasos sin tocar el tablero | Flujo completo; no pide respuestas. |
| T03 | Siguiente durante entrada/escritura/demostración | Completa el paso actual; otra pulsación avanza. |
| T04 | Cambio entre pasos de la misma escena | Misma instancia de tablero, sin nueva entrada ni salto de layout. |
| T05 | Cerrar, reabrir, rotar o texto 200 % | Retoma paso y mantiene acciones accesibles. |
| T06 | Completar/saltar y volver a entrar | No se repite automáticamente; guardado fallido no marca reconocimiento. |
| T07 | Repaso con partida activa | No altera tablero, reloj, reglas, vidas, estrellas o puntos de la partida. |
| T08 | Movimiento reducido y lector de pantalla | Explicación completa y navegación equivalente, sin espera obligatoria. |
| T09 | Comparación con reglas y anotaciones | Misma tipografía, títulos, ancho, posición del texto y acciones. |
| T10 | Sesión heredada | Reanuda sin interrupción; nueva sesión recibe la enseñanza pendiente. |

Extender las pruebas compartidas solo para contratos comunes; crear cobertura de
la introducción del mundo 3 sin modificar el comportamiento de las otras lecciones.

## Cierre

- [ ] T01–T10 cubiertos; guion coincide con D06 y reglas finales.
- [ ] Capturas de cuatro pasos y video corto de Siguiente revisados.
- [ ] Fondo visible, sin controles extra ni recarga del tablero.
- [ ] Ninguna demostración otorga progreso real.
