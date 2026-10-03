# W3-03 · Partida y navegación

Depende de: [W3-02](02-estado-y-guardado.md). Siguiente: [W3-04](04-introduccion.md).

## Objetivo

Integrar un flujo completo con resultado estático antes de añadir la animación.
La partida debe poder ganarse, fallarse, reintentarse y reanudarse usando el
resultado persistente, incluso con las animaciones desactivadas.

## Recorrido

1. Mundo 2 completo → santuario actual → mundo 3. Mantener los prerrequisitos y
   la transición existentes; W3-04 agregará la primera explicación en este acceso.
2. Mapa → resumen de nivel actual, con vidas, meta y límite de tiempo de la próxima ronda.
   En el 30 indicar «Sin errores ni pistas» antes de Jugar.
3. Ronda → resolver, agotar vidas o tiempo → resultado confirmado.
4. Aprobación en ronda 1/2 → Continuar → próxima ronda con vidas renovadas.
5. Aprobación en ronda 3 → resumen de nivel actual → navegación existente.
6. Fallo → motivo y Reintentar → misma ronda, con vidas renovadas.
7. Salir por la navegación existente y regresar → restaurar partida o resultado
   pendiente; no crear un nuevo intento automáticamente.

No duplicar rutas ni añadir un segundo resumen global sobre el actual. El último
nivel no puede ofrecer un nivel 31 ni un mundo inexistente. Los botones del mapa
reflejan estrellas confirmadas y desbloquean solo con tres rondas aprobadas.
La tercera estrella debe mostrarse en el resultado de ronda antes del resumen de
nivel; comprobar las dos presentaciones para evitar celebraciones superpuestas.

## Barra de estado y controles

Extender `GameplayStatusBar` con datos del intento, conservando su modo de vidas
infinitas para los modos anteriores. Mostrar vidas restantes/iniciales con el
corazón actual, puntaje actual/objetivo y tiempo restante. Reutilizar feedback de puntos y
errores; la pérdida de vida debe ser visible y comprensible sin depender del color.

La meta visible es la de la ronda actual. El reloj muestra cuenta regresiva para
intentos nuevos del mundo 3; los anteriores conservan su reloj actual. No hay
bonus de rapidez. Alcanzar la meta no promete la estrella: todavía hay que resolver
el tablero antes de cero y con vidas. Detener reloj y entrada al vencer; mostrar
«Se acabó el tiempo» con Reintentar. Pausa/segundo plano no descuentan tiempo.

En el nivel 30 la ayuda conserva su lugar, deshabilitada con explicación accesible;
no desplazar los números. Las notas permanecen disponibles según el desbloqueo
existente. Bloquear entradas mientras se confirma una operación terminal y durante
el resultado. Pausa/configuración siguen funcionando en la partida según el flujo
actual; no pueden reanudar un intento ya terminado.

## Contrato visual y responsive

- Reutilizar `UiSurface`/`UiSurfaceArt`, `IllustratedActionButton`, corazones y
  estrellas existentes. Todos los textos son `Text`; no generar una pantalla
  plana, nuevos paneles o iconos sin necesidad.
- Conservar Baloo 2, azul de texto, crema, dorados, proporciones y nine-patch.
- Números siempre debajo del tablero. Herramientas en su fila actual.
- Barra de estado cerca del tablero, con la altura y el espaciado actuales;
  evitar que vuelva a quedar pegada al encabezado superior.
- Volver y Configuración en extremos de pantalla con 16 px de margen.
- Usar `GameLayout`: tablero máximo 430 px en pequeño y 540 px en grande;
  números hasta 54 px, borrado hasta 52 px. Conservar márgenes laterales amplios.
- Partida sin desplazamiento de pantalla, también en horizontal. Dimensionar
  desde `LayoutBuilder` y `SafeArea`; no usar detección fija de «iPad» o de SO.
- Mantener estado, selección, notas y reloj al rotar/redimensionar. No recrear el
  tablero porque cambia un corazón o se actualiza el contador.
- En tutorial y modales puede desplazarse el contenido central si hace falta,
  dejando acciones visibles. El nuevo resultado adapta su contenido como el
  resumen actual; no envolver toda la partida en un scroll para resolverlo.
- Texto ampliado, lector de pantalla, teclado y puntero deben seguir operativos.

## Pruebas y aceptación

| ID | Caso | Resultado |
| --- | --- | --- |
| F01 | Abrir nivel nuevo | Condiciones visibles y correctas antes de jugar. |
| F02 | Perder una vida y seguir | Corazones, tablero y puntaje sincronizados; sin recreación del tablero. |
| F03 | Agotar vidas | Reloj detenido, tablero bloqueado y Reintentar; no celebración de victoria. |
| F04 | Resolver con puntos insuficientes | Resultado de fallo, no siguiente ronda/nivel. |
| F05 | Ganar rondas 1, 2 y 3 | Una estrella cada vez, vidas renovadas, resumen final una vez. |
| F06 | Nivel 30 | Ayuda deshabilitada y notas disponibles; condición perfecta visible. |
| F07 | Salir/volver, rotar, redimensionar, pausar | Conserva estado y no reinicia vidas ni objetivo. |
| F08 | Mundo 2 → santuario → mundo 3 | Puerta y ruta existentes conservadas. |
| F09 | Última ronda del nivel 30 | Cierre actual del mundo, sin navegación a contenido inexistente. |
| F10 | Mundos 1/2 y rápida | Mismos controles, premios, tutoriales y navegación que la referencia. |
| F11 | Cuenta regresiva, pausa y vencimiento | Descuenta solo tiempo activo; a cero bloquea tablero y muestra fallo/reintento. |

Ampliar pruebas existentes de `generated_game_widget_test`,
`desktop_game_layout_test`, controladores, desbloqueos y resúmenes. La matriz de
tamaños y las comparaciones visuales obligatorias están en W3-06.

## Cierre

- [ ] F01–F11 pasan con resultado estático y animaciones reducidas.
- [ ] No cambia el tamaño o la posición del tablero sin justificación de espacio.
- [ ] Sin scroll de partida, desbordes ni acciones fuera de SafeArea.
- [ ] Capturas comparativas de teléfono, iPad y escritorio revisadas.
