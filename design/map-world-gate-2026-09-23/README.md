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

Mientras falten rondas se muestra gris. Al completar las 30 rondas del mundo 1 se muestra dorado. `MapScreen.onNextWorld` queda opcional y sin conectar en la aplicación por decisión del usuario: no se abre ninguna ruta ni un modal provisional. Cuando exista el mundo 2, pasar su acción a ese callback habilitará la interacción tras completar el mundo 1.

Se conservó el flujo de felicitación y regreso a la home. Las pruebas cubren la última ronda, el reinicio de progreso, la ausencia de destino, el scroll, el cambio de tamaño y la separación respecto a Ajustes.
