# Iconos ilustrados del mapa — 7 de octubre de 2026

Generados con la herramienta integrada `image_gen`, usando el arte existente de SunDoku como referencia. Los PNG son RGBA independientes; no contienen botones ni textos. El sol, los botones, flechas, candados y estrellas se reutilizan del catálogo existente. Se descartó el ensayo de iconos de contorno.

Recursos finales: `assets/images/map/destination-mountain.png`, `destination-water.png`, `nav-home.png` y `nav-book.png`. Se conservan los archivos generados sin modificar su canal alfa; los márgenes transparentes se encuadran en `MapIcon`. UI y estados permanecen en Flutter.

## Verificación

- Los cuatro PNG son RGBA de 1254 × 1254, alfa entre 0 y 255 y esquinas completamente transparentes. Se revisaron sobre los botones crema y dorados en capturas reales de Flutter.
- 35 pruebas existentes pasan: navegación, bloqueos, estados de los destinos, selector, footer y acceso de la cima. Incluyen teléfono, tablet, escritorio, horizontal y texto ampliado.
- El análisis no presenta errores ni advertencias nuevas; mantiene cuatro observaciones de estilo previas en el movimiento ambiental y parallax.
- Capturas: `captures/illustrated-icons-mobile.png`, `captures/illustrated-icons-ipad.png` y `captures/illustrated-icons-map.png`.

## Prompts exactos

### mountain

Referencias: `/Users/mati/Projects/Games/SunDoku/sundoku/assets/images/home/icons.png`, `/Users/mati/Projects/Games/SunDoku/sundoku/assets/images/map/world-2-thumbnail.png`.

```text
Use case: stylized-concept. Derive ONE individual reusable foreground map-destination icon for SunDoku from the supplied STYLE REFERENCES, not an entire screen or atlas. First reference shows the approved soft sculpted 3D game UI materials; second shows the mountain destination's identity. Requested artwork: a compact recognizable mountain peak with a smaller secondary peak and ONE chunky rounded evergreen pine tucked in front at lower left, together one compact cutout emblem. Mountain is cool slate blue, warm ivory snowcap, pine is rich emerald green with small brown trunk. Sculpted toy-like volume, broad clean shapes, soft top-left highlights and warm shaded lower-right bevels, same quality and rounded visual language as reference 1. Readable at 36 pixels, few broad details, no tiny foliage, no realistic noise. Center artwork in square canvas, occupies about 82% width and height, balanced visual mass, entire silhouette visible. No circular medallion, no gold frame, no ground, no landscape, no clouds, no sky, no lettering. Transparent gaps between silhouette details. Extract or generate only the requested individual reusable UI artwork, never a complete screen or a flattened modal. Keep modal, card, panel and button surfaces blank, with no text, lettering, captions, labels or variable values. All UI text will be rendered separately with Flutter Text widgets. Reuse existing yellow buttons, cards and panels; do not redraw them as part of this asset. Keep the artwork independent from layout so Flutter can center the content and place yellow action buttons in the bottom action area.

Genuine transparent RGBA PNG background. Every pixel outside the requested foreground artwork must have zero alpha, including gaps between elements. No opaque background, no painted checkerboard, no scenery, no replacement backdrop, no wide halo. Preserve the foreground artwork and its clean antialiased edges.
```

### water

Referencias: `/Users/mati/Projects/Games/SunDoku/sundoku/assets/images/home/icons.png`.

```text
Use case: stylized-concept. Derive ONE individual reusable foreground map-destination icon for SunDoku from the supplied STYLE REFERENCE. Reference is material/style only, do not duplicate its objects. Requested artwork: a beautifully sculpted WATER emblem consisting of THREE broad gently curved parallel flowing water ribbons. Each ribbon has thick rounded ends and soft 3D rounded bevels, all form one coherent square icon with generous transparent channels between them. Rich blue and turquoise enamel with soft pale-cyan top-left highlights and dark navy-blue lower-right edges. A flowing river symbol, not ocean breaking waves, no splashes or droplets, no surface below. Same soft sculpted game-icon finish as the existing reference sun/play/profile icons. Frontal view, readable at 36 pixels, few broad details. Center the entire icon on a square canvas occupying about 82% width, 76% height, balanced silhouette. No circular medallion, no gold frame, no scenery, no landscape, no lettering. Extract or generate only the requested individual reusable UI artwork, never a complete screen or a flattened modal. Keep modal, card, panel and button surfaces blank, with no text, lettering, captions, labels or variable values. All UI text will be rendered separately with Flutter Text widgets. Reuse existing yellow buttons, cards and panels; do not redraw them as part of this asset. Keep the artwork independent from layout so Flutter can center the content and place yellow action buttons in the bottom action area.

Genuine transparent RGBA PNG background. Every pixel outside the requested foreground artwork must have zero alpha, including gaps between elements. No opaque background, no painted checkerboard, no scenery, no replacement backdrop, no wide halo. Preserve the foreground artwork and its clean antialiased edges.
```

### home

Referencias: `/Users/mati/Projects/Games/SunDoku/sundoku/assets/images/home/icons.png`.

```text
Use case: stylized-concept. Derive ONE individual reusable SunDoku navigation icon from the supplied STYLE REFERENCE. Requested artwork: a simple solid thick HOME/HOUSE symbol, broad rounded pitched roof, square house body with one centered open doorway cut completely through to transparency. No windows, no chimney, no ground or base. Deep navy blue enamel identical to the approved play triangle/profile icon in the reference, softly sculpted 3D bevels, small tasteful top-left cool highlights, darker lower-right edges. Bold unified silhouette, front view, readable at 24 pixels. Center the icon in a square canvas, occupy about 82% width and height. No outline style, no fine lines, no extra detail. Icon alone without round button or panel or frame. Extract or generate only the requested individual reusable UI artwork, never a complete screen or a flattened modal. Keep modal, card, panel and button surfaces blank, with no text, lettering, captions, labels or variable values. All UI text will be rendered separately with Flutter Text widgets. Reuse existing yellow buttons, cards and panels; do not redraw them as part of this asset. Keep the artwork independent from layout so Flutter can center the content and place yellow action buttons in the bottom action area.

Genuine transparent RGBA PNG background. Every pixel outside the requested foreground artwork must have zero alpha, including gaps between elements. No opaque background, no painted checkerboard, no scenery, no replacement backdrop, no wide halo. Preserve the foreground artwork and its clean antialiased edges.
```

### book

Referencias: `/Users/mati/Projects/Games/SunDoku/sundoku/assets/images/home/icons.png`.

```text
Use case: stylized-concept. Derive ONE individual reusable SunDoku navigation icon from the supplied STYLE REFERENCE. Requested artwork: an open BOOK symbol seen straight on, two broad symmetrical gently curved page halves, clearly recognizable center fold. Deep navy blue rounded thick cover and page silhouette, with TWO short broad warm ivory inset page lines on each half to suggest reading, not letters. Soft sculpted 3D rounded enamel finish EXACTLY like the reference's approved blue play triangle/profile icons, small tasteful cool highlights at upper-left, darker lower-right bevels. Match a chunky home icon in overall weight and scale. Minimal detail readable at 24 pixels, not a photoreal book. Center full artwork on a square canvas, occupies about 82% width and 74% height. No button, medallion, base, frame, text or labels. Extract or generate only the requested individual reusable UI artwork, never a complete screen or a flattened modal. Keep modal, card, panel and button surfaces blank, with no text, lettering, captions, labels or variable values. All UI text will be rendered separately with Flutter Text widgets. Reuse existing yellow buttons, cards and panels; do not redraw them as part of this asset. Keep the artwork independent from layout so Flutter can center the content and place yellow action buttons in the bottom action area.

Genuine transparent RGBA PNG background. Every pixel outside the requested foreground artwork must have zero alpha, including gaps between elements. No opaque background, no painted checkerboard, no scenery, no replacement backdrop, no wide halo. Preserve the foreground artwork and its clean antialiased edges.
```
