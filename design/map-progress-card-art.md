# Arte de la tarjeta flotante del mapa

Referencia: imagen adjunta de la tarjeta «Mundo 2 / Nivel 13» (622 × 317 px). El panel visible ocupa aproximadamente 475 × 203 px. Los textos, flechas azules y cifras son widgets; ningún recurso nuevo contiene etiquetas.

Los cinco PNG se generaron con la herramienta integrada ImageGen a partir de esa referencia. Se incorporaron como elementos independientes en `assets/images/map/`:

| Recurso | Pedido específico del prompt |
| --- | --- |
| `progress-card-panel.png` | Extraer solo el panel crema vacío, de proporción 475:203, con esquinas amplias, contorno fino cobrizo, bisel dorado, brillo interior blanco y sombra inferior. Quitar miniatura, textos, flechas, barra y tablero de cuadros. |
| `progress-card-round.png` | Extraer solo la superficie circular dorada de una flecha, con borde cobrizo y brillo; quitar el glifo azul para componerlo en Flutter. |
| `progress-card-track.png` | Extraer solo la pista crema vacía de proporción 364:29, con un contorno marrón fino. Sin relleno ni contador. |
| `progress-card-fill.png` | Extraer solo la pastilla de relleno amarillo y ámbar, apta para estirarse mediante nine-patch. Sin pista ni contador. |
| `world-2-thumbnail.png` | Extraer solo la miniatura cuadrada del monte azul nevado, bosque de pinos y marco dorado. Sin tarjeta ni rótulos. |

Todos los prompts incluyeron estos requisitos:

> Genuine transparent RGBA PNG background. Every pixel outside the requested foreground artwork must have zero alpha, including gaps between elements. No opaque background, no painted checkerboard, no scenery, no replacement backdrop, no wide halo. Preserve the foreground artwork and its clean antialiased edges.

> Extract or generate only the requested individual reusable UI artwork, never a complete screen or a flattened modal. Keep modal, card, panel and button surfaces blank, with no text, lettering, captions, labels or variable values. All UI text will be rendered separately with Flutter Text widgets. Reuse existing yellow buttons, cards and panels; do not redraw them as part of this asset. Keep the artwork independent from layout so Flutter can center the content and place yellow action buttons in the bottom action area.

El alfa se verificó en los PNG instalados: esquinas con alfa cero y siluetas transparentes fuera de cada elemento. Las superficies adaptables se registraron en `UiSurfaceCatalog`; la miniatura conserva su proporción y se recorta como ilustración independiente.
