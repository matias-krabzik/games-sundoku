# Correcciones de las uniones

Herramienta: `image_gen` integrado. Se conservan las versiones anteriores; `layout.json` selecciona las revisiones.

## 01-backdrop-v2

```text
Edit ONLY the sky lighting/color in this registered 2171x724 background layer. Remove the warm yellow/white solar glow from the RIGHT quarter and replace it with the same clear even blue daylight color as the LEFT quarter at each height. Keep EVERY cloud, mountain, distant tree and land feature at its exact existing position and size. Do not redraw or move geography. No sun disc, rays, lens flare or warm sky gradient toward either side. Keep natural blue vertical sky gradient, approximately same blue at left and right edges so this panorama joins another blue-sky tile. The FULL rectangular background plane itself is requested artwork and remains opaque; the clause below applies only outside this plane. No text/UI. Genuine transparent RGBA PNG background. Every pixel outside the requested foreground artwork must have zero alpha, including gaps between elements. No opaque background, no painted checkerboard, no scenery, no replacement backdrop, no wide halo. Preserve the foreground artwork and its clean antialiased edges.
Extract or generate only the requested individual reusable UI artwork, never a complete screen or a flattened modal. Keep modal, card, panel and button surfaces blank, with no text, lettering, captions, labels or variable values. All UI text will be rendered separately with Flutter Text widgets. Reuse existing yellow buttons, cards and panels; do not redraw them as part of this asset. Keep the artwork independent from layout so Flutter can center the content and place yellow action buttons in the bottom action area.
```

## 03-terrain-v2

```text
Correct ONLY the LEFTMOST 300 PIXELS of this registered 2172x724 transparent terrain layer. The rest from x300 to the far right must remain EXACTLY unchanged. Remove the tall conifer trees, large willow portion and tall flowering shrub mass that are cut off by the left edge. Rebuild that first 300px as a low open grassy riverbank with only low rounded shrubs and white flowers, and a few tiny distant green trees no taller than y285. Above these low silhouettes make TRUE transparent alpha. The aim is an OPEN JOINING EDGE, never a half tree cut vertically. At x300 blend naturally into the existing near trees and rocks. Preserve the exact golden path, its y position at the left entry, every path stone, and the stream and near bank below it. Do not add, move or redraw the bridge. Keep full original canvas, no trim or centering, no matte/checkerboard. Foreground bottom grass remains to the bottom edge. Preserve SunDoku colors and rendering; clean natural antialiased edges with NO neon green, yellow or magenta fringe. Genuine transparent RGBA PNG background. Every pixel outside the requested foreground artwork must have zero alpha, including gaps between elements. No opaque background, no painted checkerboard, no scenery, no replacement backdrop, no wide halo. Preserve the foreground artwork and its clean antialiased edges.
Extract or generate only the requested individual reusable UI artwork, never a complete screen or a flattened modal. Keep modal, card, panel and button surfaces blank, with no text, lettering, captions, labels or variable values. All UI text will be rendered separately with Flutter Text widgets. Reuse existing yellow buttons, cards and panels; do not redraw them as part of this asset. Keep the artwork independent from layout so Flutter can center the content and place yellow action buttons in the bottom action area.
```


## Revisión 3: plantas de unión y llegada del nivel 30

Las tres composiciones frontales repetían la misma planta de lirios. Se reemplazaron por tres tiras independientes y transparentes, con especies y siluetas distintas para las zonas 8–9, 16 y 23. Los parches de terreno existentes siguen resolviendo cada empalme con un solo trazado de camino, sin fundir dos senderos.

### Borde de ribera entre 8 y 9

Se generó una tira baja de césped, margaritas, piedras y juncos limitados a un extremo. El centro queda despejado para conservar legible el camino.

### Borde de cascada en 16

Se generó una tira distinta de helechos, flores pequeñas y piedras musgosas, con un solo grupo de juncos y huecos transparentes amplios.

### Orilla del lago en 23

Se generó una tercera tira con hojas de ribera, flores acuáticas pequeñas, nenúfares y piedras, sin lirios violetas ni juncos.

### Remate del nivel 30

Se editó `layers/04-terrain-v3.png` a partir de `04-terrain-v2.png`: se mantuvo el registro del lienzo y se cerró el sendero en un claro circular de la cima, sin que la ruta salga por el borde derecho. Se colocó el nivel 30 en ese claro.

En estos prompts se incluyeron las instrucciones obligatorias del proyecto:

> Genuine transparent RGBA PNG background. Every pixel outside the requested foreground artwork must have zero alpha, including gaps between elements. No opaque background, no painted checkerboard, no scenery, no replacement backdrop, no wide halo. Preserve the foreground artwork and its clean antialiased edges.

> Extract or generate only the requested individual reusable UI artwork, never a complete screen or a flattened modal. Keep modal, card, panel and button surfaces blank, with no text, lettering, captions, labels or variable values. All UI text will be rendered separately with Flutter Text widgets. Reuse existing yellow buttons, cards and panels; do not redraw them as part of this asset. Keep the artwork independent from layout so Flutter can center the content and place yellow action buttons in the bottom action area.


## Revisión 4: unión entre los niveles 8 y 9

Se retocaron solo los pinos lejanos y la franja inferior de césped. `layers/02-backdrop-seam-08-09.svg` mantiene íntegro el panel de fondo 02 y muestra la nueva referencia generada únicamente en los primeros 450 px locales, entre y=245–390, con un desplazamiento vertical de 12 px y bordes difuminados. Así el horizonte de pinos continúa a la altura del panel 01 sin cambiar las nubes, las montañas ni las partes restantes del mapa.

`layers/foreground-grass-08-09.png` es una banda independiente con alfa real. La composición la ubica en x=1790, y=524, a 600×200 px; sus píxeles visibles comienzan debajo del recorrido. `repairs/terrain-08-09.png` no se modificó: su SHA-256 continúa en `review/validation.json`.

### Prompt final: fondo de pinos

```text
Use case: precise-object-edit
Asset type: full-bleed far-background panel for the existing illustrated game map
Input images: Image 1 is the edit target, the 02-backdrop.png panel (2169×725). Image 2 is the adjacent 01-backdrop-v2.png panel and the exact style and horizon-height reference at its far-right edge.
Primary request: make the distant pine ridge at the LEFT edge of Image 1 continue naturally from Image 2. At the seam, the conifer tree tops must sit at the same low distant horizon as Image 2, around y=265–295 on this 725px-high canvas. Keep the tree-line low and gently undulating; no sudden tall triangular ridge or abrupt jump. Continue this same low forest line through the first 400 px, then blend into the existing Image 1 forest line.
Style/medium: exact existing bright polished 3D storybook game-map illustration.
Constraints: Change only the far-distant pines and the narrow strip of low green field directly below them in the first 400 px of Image 1. Do not vertically shift or redraw the sky, clouds, mountain peaks, nearer hills, trees, foreground, or the rest of the panel. Keep everything from x=400 to the right edge of Image 1 visually unchanged. The whole opaque landscape plane itself is the requested artwork; preserve the full-bleed landscape and its current composition. No text, icons, UI, road, or water.
Genuine transparent RGBA PNG background. Every pixel outside the requested foreground artwork must have zero alpha, including gaps between elements. No opaque background, no painted checkerboard, no scenery, no replacement backdrop, no wide halo. Preserve the foreground artwork and its clean antialiased edges.
Extract or generate only the requested individual reusable UI artwork, never a complete screen or a flattened modal. Keep modal, card, panel and button surfaces blank, with no text, lettering, captions, labels or variable values. All UI text will be rendered separately with Flutter Text widgets. Reuse existing yellow buttons, cards and panels; do not redraw them as part of this asset. Keep the artwork independent from layout so Flutter can center the content and place yellow action buttons in the bottom action area.
This is environmental background art, not a UI surface. Treat the landscape plane as the requested artwork, preserve its opacity, and do not apply UI-surface restrictions to the scenery.
```

### Prompt final: césped inferior

```text
Use case: stylized-concept
Asset type: transparent foreground grass strip to blend one local join in a colorful 3D storybook game map
Input images: Image 1 is the foreground vegetation style reference from the 8–9 junction. Image 2 is the local terrain reference for its grass colors and glossy, playful rendering.
Primary request: create one low, continuous band of lush front grass that will sit ONLY beneath the existing path at the 8–9 junction. It should visually soften a seam in the lower grass while matching the reference art.
Style/medium: polished colorful 3D storybook game illustration, rounded soft foliage, warm sunlight, crisp clean antialiased edges.
Composition/framing: very wide horizontal transparent cutout. Keep the main grass clumps and small white/yellow daisies confined to the bottom 25–35% of the image; leave the upper area transparent. Make it feel like a continuous grassy edge, with low varied tufts and softly interlocking silhouette tips. Suitable for a shallow placement directly under the existing gold route.
Color palette and materials: match the rich natural greens, lime highlights, tiny white and yellow meadow flowers, soft shadows, and high-contrast glossy finish in the two references.
Constraints: grass and tiny flowers only. No road or path, no stones, rocks, water, river, trees, bushes, cattails, tall stalks, hills, horizon, sky, lettering, objects, or scenery behind it. Keep the top half entirely transparent. This is a small localized patch and must not cover or alter the existing path. The artwork is intended to overlay the bottom foreground only.
Genuine transparent RGBA PNG background. Every pixel outside the requested foreground artwork must have zero alpha, including gaps between elements. No opaque background, no painted checkerboard, no scenery, no replacement backdrop, no wide halo. Preserve the foreground artwork and its clean antialiased edges.
Extract or generate only the requested individual reusable UI artwork, never a complete screen or a flattened modal. Keep modal, card, panel and button surfaces blank, with no text, lettering, captions, labels or variable values. All UI text will be rendered separately with Flutter Text widgets. Reuse existing yellow buttons, cards and panels; do not redraw them as part of this asset. Keep the artwork independent from layout so Flutter can center the content and place yellow action buttons in the bottom action area.
This is map foreground vegetation, not UI art. Follow the transparent cutout requirement and do not add any layout, labels, UI surfaces or UI controls.
```


## Revisión 5: fondo más abierto antes del nivel 16

Para suavizar el cambio de paisaje que aparece por encima del nivel 16, los pinos lejanos del final del tramo 02 se hacen progresivamente más bajos y escasos. `layers/02-backdrop-seams-08-09-16.svg` conserva la corrección previa 8–9 y añade `candidates/02-backdrop-transition-16-v1.png` únicamente sobre la banda distante en x=1569–2169, y=253–317 del panel; el fundido horizontal empieza en x=1569 y completa en x=1769. El resto del panel 02, el camino, el primer plano y los paneles 03–04 se mantienen sin cambios.

El candidato conserva el tamaño de 2169×725 px y es RGB opaco, porque la capa de fondo ocupa todo el rectángulo. El SVG final mantiene embebidas ambas correcciones; también se actualizaron `layers/assembled-backdrop.svg` y `panorama.svg`.

### Prompt final: fondo distante sobre el nivel 16

```text
Use case: precise-object-edit.
Asset type: the same full-bleed opaque background panel for the existing illustrated game map.
Input images: Image 1 is the exact 2169×725 target panel 02. Image 2 is a palette and storybook-style reference for the landscape that follows the upcoming junction.
Make one clearly visible, gradual reduction in distant trees BEFORE the junction above level 16: in Image 1's RIGHTMOST 600 pixels only, replace the currently dense layered conifer silhouette with ONE much lower, broken, sparse line of far-away pines. Remove about 60 percent of the conifer silhouettes in that region. Keep only separated small groups and broad gaps, with the pines becoming shorter and less frequent toward the right edge. Reveal the existing rolling green hill shapes behind the removed pines. The density should ease down smoothly, not stop abruptly. Keep a few small pines for continuity; do not make a bare empty field. The effect should read as the map naturally opening out before the next landscape change.
Match the exact colorful polished 3D storybook look and natural palette of the inputs.
Edit only the far-distance conifer silhouettes and their immediate low green bases inside x=1569–2169 and y=240–330. All sky, clouds, mountains, nearer landscape, and every pixel outside that narrow band must remain visually identical to Image 1. Preserve the original exact 2169×725 canvas, registration, composition and scale. Do not shift, crop, zoom, recolor the whole scene, or add any objects. No text, icons, UI, path, water, foreground, or new plants.
The full-bleed landscape plane itself is the requested artwork and remains opaque.
Genuine transparent RGBA PNG background. Every pixel outside the requested foreground artwork must have zero alpha, including gaps between elements. No opaque background, no painted checkerboard, no scenery, no replacement backdrop, no wide halo. Preserve the foreground artwork and its clean antialiased edges.
Extract or generate only the requested individual reusable UI artwork, never a complete screen or a flattened modal. Keep modal, card, panel and button surfaces blank, with no text, lettering, captions, labels or variable values. All UI text will be rendered separately with Flutter Text widgets. Reuse existing yellow buttons, cards and panels; do not redraw them as part of this asset. Keep the artwork independent from layout so Flutter can center the content and place yellow action buttons in the bottom action area.
This request concerns an opaque scenic landscape plane, not UI or a cutout. Keep the artwork as an opaque full-bleed landscape and interpret the transparency and reusable-UI requirements accordingly.
```
