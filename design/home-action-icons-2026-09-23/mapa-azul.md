# Mapa azul simplificado — 23-09-2026

Versión actual de `assets/images/home/adventure-map.png`, generada con la herramienta integrada `image_gen` a partir del mapa anterior y del rayo aprobado. Copia de diseño: `adventure-map-blue.png`. El mapa crema anterior se conserva como referencia histórica en `adventure-map.png` de esta carpeta.

Se eliminaron ruta, marcador y colores secundarios. El recurso se compone exclusivamente de la silueta de un mapa plegado azul, con el volumen y el acabado del rayo. El resultado inicial era RGB con cuadros pintados; se extrajo localmente ese fondo neutro conservando los bordes suavizados. PNG final RGBA de 1254×1254, con fondo realmente transparente. El texto «¡Elige la dificultad y sigue jugando!» se eliminó de la home.

## Prompt

```text
Use case: style-transfer.
Edit target: input image 1, SunDoku's folded map icon.
Material/style reference ONLY: input image 2, the approved blue lightning-bolt icon. Do not include any lightning bolt in the output.
Primary request: simplify the map into a clean monochrome NAVY BLUE icon in exactly the same sculpted, softly glossy material as the lightning bolt.
Preserve the general recognizable silhouette of an open three-panel accordion-fold map, centered and fully visible, rounded outer corners. Make its entire front and edges the same rich navy and royal-blue material as the bolt. Use only TWO simple broad fold creases to define the three panels, subtle molded thickness, smooth rounded bevels, soft upper-left blue highlights, darker blue lower-right edges. The silhouette and these two folds are all the detail needed. REMOVE the entire path, location pin, land shape, cream paper, gold details and contrasting outline/frame. No marks or symbols on the panels. Not a book, not a chest, not a flag, not a pin: a simple open folded map glyph with three broad connected facets and a zigzag top and bottom silhouette. Instantly legible at a small 34px button-icon size. Frontal view, compact approximately 1.15:1 silhouette, not an angled perspective scene. Tactile SunDoku 3D children's game style, same softness, navy color, modest blue highlights and visual weight as the bolt. Square canvas with clean margins. One isolated map icon only. No text, no other objects, no glow, no ground shadow.
Extract or generate only the requested individual reusable UI artwork, never a complete screen or a flattened modal. Keep modal, card, panel and button surfaces blank, with no text, lettering, captions, labels or variable values. All UI text will be rendered separately with Flutter Text widgets. Reuse existing yellow buttons, cards and panels; do not redraw them as part of this asset. Keep the artwork independent from layout so Flutter can center the content and place yellow action buttons in the bottom action area.
Genuine transparent RGBA PNG background. Every pixel outside the requested foreground artwork must have zero alpha, including gaps between elements. No opaque background, no painted checkerboard, no scenery, no replacement backdrop, no wide halo. Preserve the foreground artwork and its clean antialiased edges.
Technical export fallback authorized by the user: if true alpha cannot be encoded and the tool emits RGB, use a SINGLE perfectly uniform #FF00FF chroma-key background for later local removal, with no texture, checkerboard, reflections or gradient. Never include magenta in the artwork itself.
```
