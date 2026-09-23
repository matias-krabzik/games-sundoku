# Sol del arco — próximo mundo

El sol es un recurso independiente: `assets/images/map/gate-sun.png` (512 × 512, RGBA). Se quitó el sol pintado de `assets/images/map/layers/terrain.png` y se reconstruyó la madera que cubría; el panorama original `world-1-horizontal.png` sigue intacto.

## Recursos y transparencia

- `arch-source.png`: recorte original, x=1950, y=210, 380 × 300 del terreno de 2428 × 980.
- `arch-repair.png`: reparación con IA y alfa restaurado antes de componer.
- `arch-without-sun.png`: resultado del recorte integrado.
- `prompts.md`: los dos prompts utilizados con ImageGen integrado.
- `prepare-assets.cjs`: limpieza local de la transparencia y composición limitada a la zona del emblema. Los generados incluían un fondo de cuadros RGB; se retiró mediante una máscara de color y se verificó el canal alfa, incluidos los huecos entre rayos y debajo del arco. Solo se sustituyeron píxeles de la zona reparada; se preservaron el tamaño, el resto del terreno y sus márgenes.

## Integración

`MapWorldGate` conserva la proporción del sol y se coloca en el centro (1982, 179) del panorama sin márgenes de 2172 × 724. Comparte scroll y transformación de terreno con el arco. Su área táctil mínima es 48 px y se protege de las partículas del mapa.

Mientras falten rondas se muestra gris. Al volver al mapa tras completar las 30 rondas, espera a la última estrella y a que termine la transición de pantalla. La cámara se desplaza hacia el arco durante 600 ms. También al entrar desde la home, primero se comprueba que el scroll llegó al sol: entonces empiezan el encendido y el sonido. El encendido dura 1,1 segundos: todo el sol recupera su amarillo simultáneamente mediante una transición uniforme de saturación. Crece con un rebote elástico desde su centro, sobrepasa brevemente su tamaño final y se asienta un 18 % más grande que al inicio. No hay máscara radial ni foco que recorra el dibujo. El halo aparece gradualmente detrás del sol y al final salen ocho pequeñas chispas. Después queda una rotación de una vuelta cada 24 segundos, sin repetir sonidos.

La marca persistente `world1GateCelebrated` se escribe únicamente al terminar el encendido. Si se visita primero la home o se cierra el mapa durante la celebración, queda pendiente para la siguiente visita. Las animaciones se pausan y el audio se detiene al cubrir el mapa con otra ruta o enviar la app al fondo. Con movimiento reducido se sitúa la cámara directamente en el sol y se usa un encendido de 450 ms, sin crecimiento, giro ni chispas. Las opciones de desarrollo para reiniciar el mundo o preparar la última ronda también restablecen la celebración. Los efectos de Kenney son CC0 y están documentados en `design/audio/sound-effects-credits.md`.

`MapScreen.onNextWorld` queda opcional y sin conectar en la aplicación por decisión del usuario: no se abre ninguna ruta ni un modal provisional. Cuando exista el mundo 2, pasar su acción a ese callback habilitará la interacción tras completar el encendido.

El repaso final permite volver al mapa o ir al inicio. Las pruebas cubren la última ronda, el guardado entre aperturas, interrupciones, pausas, velocidad del giro, movimiento reducido, reinicio de progreso, ausencia de destino, scroll, cambio de tamaño y separación respecto a Ajustes.
