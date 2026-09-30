# Extensión de Ríos Cruzados

Herramienta: `image_gen` integrado. Esta primera extensión es candidata; todavía no se ha montado ni validado su unión con el concepto aprobado. No está integrada en Flutter.

## upstream-01

Referencia: `../references/approved-concept.png`. Salida: `candidates/upstream-01.png`.

```text
Use case: stylized-concept / leftward environmental outpainting.
Asset type: one complete panoramic LANDSCAPE TILE to extend the approved SunDoku Ríos Cruzados map. Do not add gameplay UI.

Input image 1 is the approved river-world concept, 2172 x 724, and is BOTH the exact style reference and the RIGHT-HAND NEIGHBOR of the new tile. It shows river cascades at its left and a lake destination at its right. Create the NEXT landscape tile immediately TO ITS LEFT, upstream. Preserve the identical polished sculpted 3D family-game rendering, camera elevation, apparent scale, clear daylight with warm sun from the upper right, colors, golden path surface, chunky mossy rocks, willows and soft puffy cloud style. New terrain, NOT a copied or rearranged version of the whole reference.

Output exactly the same panoramic format as the supplied reference, 2172 x 724, 3:1, single continuous full-bleed rectangle. Crucial composition for assembly: reserve the RIGHTMOST 10% of the new tile for an exact visual repetition of the LEFTMOST 10% of the input neighbor at the same scale, height and pixel positions relative to the top. That repeated overlap is a registration strip, not a border or a miniature inset. The leftmost part of the reference contains tall rock/cascade uplands, conifers and willow greenery; reproduce that partial mountain/waterfall silhouette and matching golden path entry within the right overlap, with no vertical repositioning. The new 90% extends naturally to the LEFT of this repeated portion, without a visible junction. The edge matching matters more than extra detail.

Main landscape: upstream sunny river country with low grassy terraces, a broad branching clear turquoise stream, sculpted willow groves, original alder-like trees with broad oval jade foliage, reeds and cattails with rounded brown seed heads, creamy flowering riverbank shrubs, rounded aquatic leaves and restrained lilac irises. Blue mountains and calm bright sky in the distance. Distinct new landscape throughout the left and center. More open grassy clearings between groves than the reference, so the journey feels spacious.

The walkable golden dirt route must enter LEFT edge around y=0.60 of the canvas, weave gently through the lower-middle around y=.56 to .72 with broad long horizontal curves, cross ONE readable modest rounded timber footbridge over a stream in the left-middle, then lead rightward to join the actual golden path visible at the LEFT edge of the reference neighbor. The path in the right overlap must reproduce that neighbor path precisely. All bridge ends physically meet dry paths on both banks. Preserve a wide continuous unobstructed walkable route, with generous clear verge for future level medallions. No branching footpaths, no roads diving into water, no foreground foliage covering the route. Avoid large elevation swings. Do not paint number circles or regular empty pads. Keep vegetation scale the same as the original, not zoomed out tiny objects.

No new lake destination here; the lake remains in the right neighbor. This new stretch is part of the same healthy fully formed region, not under construction. No unlock states or restored/broken variants. No characters, buildings, signs, text, labels, numbers, badges, panels, UI, borders, grids or watermarks. No duplicated full map, montage, three-panel layout, stretching or mirrored vegetation. Match image 1's material and artwork style tightly.

Current deliverable scope: the user approved the complete environmental master and now asks for its extra-long continuation. This tile is complete full-bleed landscape concept artwork, INCLUDING sky and ground. For this master tile every pixel belongs to the requested panorama; render it fully painted and opaque. Transparent individual parallax layers will be extracted afterward. The standing project clauses below are included for future production exports and govern anything outside the requested artwork, not a request to erase the full master landscape:
Genuine transparent RGBA PNG background. Every pixel outside the requested foreground artwork must have zero alpha, including gaps between elements. No opaque background, no painted checkerboard, no scenery, no replacement backdrop, no wide halo. Preserve the foreground artwork and its clean antialiased edges.
Extract or generate only the requested individual reusable UI artwork, never a complete screen or a flattened modal. Keep modal, card, panel and button surfaces blank, with no text, lettering, captions, labels or variable values. All UI text will be rendered separately with Flutter Text widgets. Reuse existing yellow buttons, cards and panels; do not redraw them as part of this asset. Keep the artwork independent from layout so Flutter can center the content and place yellow action buttons in the bottom action area.
```
