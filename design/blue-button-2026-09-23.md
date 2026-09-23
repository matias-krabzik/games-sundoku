# Botón azul de SunDoku — 23-09-2026

Propuesta aprobada e integrada en `assets/images/home/blue-button.png`. Generación y edición con la herramienta integrada `image_gen`. Referencias: botón amarillo, botón azul anterior y superficies crema existentes.

El generador devolvió un RGB con cuadros pintados. Se extrajo localmente el fondo neutro, se reconstruyó el alfa de los bordes y se conservó la superficie del botón. PNG final RGBA de 2172×724, sin texto ni iconos. Recorte y nine-patch centralizados en `UiSurface.blueButton`. El texto sigue siendo Flutter Text, en azul oscuro para contrastar con la nueva superficie luminosa.

## Prompt de diseño

```text
Use case: style-transfer.
Asset type: ONE reusable blank blue secondary action button for the children's game SunDoku.
Input image 1 is the existing SunDoku yellow play button: PRIMARY STYLE reference for silhouette, soft sculpted rounded bevels and gentle light. Input image 2 is the rejected old blue button: redesign target; replace its heavy dark face and metallic frame. Input image 3 is existing cream SunDoku UI surfaces: reference for warm ivory edge treatment. Output ONLY one redesigned BLUE button, not a sheet of variations, not the reference assets.
Primary request: Reinvent the old blue button so it belongs to the same warm, cheerful illustrated children's game as the yellow play button. Make it feel friendly, soft, tactile and luminous, like carefully sculpted 3D animation artwork. A bright cornflower-to-sky blue cushion face, subtly darker medium blue along the lower edge, a fine warm ivory highlight across the upper rim, and ONE restrained rounded buttery-gold outer lip. Broad soft gradients with delicate painterly texture and rounded volume. Keep the edge soft and simple, not a metallic gold frame. Avoid navy-black heavy center, chrome, harsh glossy hard reflections, neon cyan, industrial bevels, multiple concentric bands, ornate trim, poker/casino style. Shape is a front-facing wide horizontal capsule, approximately 3.8:1 artwork aspect ratio, generous curved ends, slight lower thickness, no perspective skew. Big uninterrupted BLANK center for future Flutter text; no play triangle, icon, stars, sun, symbols or ornaments. Consistent straight horizontal middle edge segments so it can become a nine-patch. Center a single complete button with clean transparent margins, wide landscape image, tight visual framing. Do not include a drop shadow outside the silhouette or any atmospheric glow.
Extract or generate only the requested individual reusable UI artwork, never a complete screen or a flattened modal. Keep modal, card, panel and button surfaces blank, with no text, lettering, captions, labels or variable values. All UI text will be rendered separately with Flutter Text widgets. Reuse existing yellow buttons, cards and panels; do not redraw them as part of this asset. Keep the artwork independent from layout so Flutter can center the content and place yellow action buttons in the bottom action area.
Genuine transparent RGBA PNG background. Every pixel outside the requested foreground artwork must have zero alpha, including gaps between elements. No opaque background, no painted checkerboard, no scenery, no replacement backdrop, no wide halo. Preserve the foreground artwork and its clean antialiased edges.
```

## Prompt de limpieza

```text
Use case: background-extraction.
Edit the attached blue SunDoku button ONLY to fix its background. Preserve the exact button silhouette, position, size, blue face, creamy gold border, volume and highlights. Do not redesign the button. Remove the ENTIRE fake gray checkerboard outside its silhouette, including all smeared gray artifacts around the border. Keep the complete surface blank without text or icon. Produce one isolated button asset.
Genuine transparent RGBA PNG background. Every pixel outside the requested foreground artwork must have zero alpha, including gaps between elements. No opaque background, no painted checkerboard, no scenery, no replacement backdrop, no wide halo. Preserve the foreground artwork and its clean antialiased edges.
Extract or generate only the requested individual reusable UI artwork, never a complete screen or a flattened modal. Keep modal, card, panel and button surfaces blank, with no text, lettering, captions, labels or variable values. All UI text will be rendered separately with Flutter Text widgets. Reuse existing yellow buttons, cards and panels; do not redraw them as part of this asset. Keep the artwork independent from layout so Flutter can center the content and place yellow action buttons in the bottom action area.
Export fallback explicitly authorized by the user: IF your output format cannot emit an actual alpha channel, replace ALL outside pixels with the single perfectly uniform flat chroma color #FF00FF, with absolutely NO texture, NO checker pattern, NO shadow or glow on this chroma background. This is a temporary technical key for local alpha removal, not a decorative backdrop. Preserve clean antialiased foreground edges.
```
