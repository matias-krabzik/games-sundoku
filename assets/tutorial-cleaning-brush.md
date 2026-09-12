# Pincel de limpieza del tutorial

Recurso integrado: `assets/images/tutorial/cleaning-brush.png`.

Es un pincel de mango azul brillante, aro dorado y cerdas crema, sin X ni flecha. Se dibuja proporcionalmente a 40 × 40 píxeles lógicos encima de la superficie circular nine-patch existente. No incluye el botón ni texto. El estado inactivo se representa con opacidad; la etiqueta accesible sigue siendo «Borrar número seleccionado».

Se utilizó la herramienta integrada ImageGen. Referencias de estilo: `assets/images/settings/icons.png` y `assets/images/map/icons.png`. La primera propuesta de tecla de borrado se descartó al recibir la indicación de usar únicamente un pincel.

## Transparencia comprobada

- PNG RGBA de 1254 × 1254.
- Alfa mínimo 0 y máximo 255; 64,76 % de píxeles con alfa 0.
- Las cuatro esquinas y el hueco del mango tienen alfa 0.
- Caja de contenido con alfa > 10: (109, 64, 1197, 1193).
- Se copió el PNG final sin modificar. Pillow solo leyó metadatos y alfa; no se editaron píxeles con scripts.
- Se revisó dentro del botón sobre el fondo del tutorial, tanto en una captura de Flutter como en el moto g75 conectado.

Salida final: `/Users/mati/.codex/generated_images/01a08d4e-0f91-7c01-83e4-845a09f8eefd/exec-b1e1d9bc-b128-40f5-a1b4-821a6e3287fb.png`.

## Prompts

### Diseño del pincel

```text
Use case: stylized-concept. Create ONE isolated CLEANING BRUSH icon for the SunDoku children's puzzle game. Supplied images are STYLE REFERENCES ONLY for the rounded glossy blue 3D toy materials. Subject: only a short-handled friendly small cleaning paintbrush, diagonally tilted with rounded cobalt-blue handle at upper right and broad soft ivory-cream bristles fanning gently toward lower left; a small shiny golden collar joins handle and bristles. Thick smooth inflated toy-like forms, high quality 3D illustration, soft upper-left specular highlights, dark navy lower bevels, simple instantly legible silhouette at 32 logical pixels. Square canvas, brush centered and filling about 85% of width and height, all bristles and handle fully visible, narrow genuine transparent margin. Crucial: just the physical cleaning brush. NO arrow, NO backspace silhouette, NO X/cross mark, NO delete key, NO additional symbol, NO circle/button base, NO paint smear, no dust, no surrounding sparkles, no floor or cast shadow. We will overlay this brush on the existing cream round button in Flutter. Genuine transparent RGBA PNG background. Every pixel outside the requested foreground artwork must have zero alpha, including gaps between elements. No opaque background, no painted checkerboard, no scenery, no replacement backdrop, no wide halo. Preserve the foreground artwork and its clean antialiased edges. Extract or generate only the requested individual reusable UI artwork, never a complete screen or a flattened modal. Keep modal, card, panel and button surfaces blank, with no text, lettering, captions, labels or variable values. All UI text will be rendered separately with Flutter Text widgets. Reuse existing yellow buttons, cards and panels; do not redraw them as part of this asset. Keep the artwork independent from layout so Flutter can center the content and place yellow action buttons in the bottom action area.
```

El resultado inicial (`exec-7b3d8618-c7dc-4e8b-adb7-32cdc2571bf9.png`) y dos intentos de limpieza devolvieron RGB con un patrón dibujado. Se descartaron para la integración. El pase final de extracción, con el siguiente prompt breve, produjo el RGBA verificado manteniendo el pincel original.

### Extracción final del fondo

```text
Remove the background from this image and make the background transparent. Preserve all the foreground artwork exactly.
```
