# Bosque primaveral · imagen maestra

Herramienta: ImageGen integrado. Entrega de arte, sin cambios en la aplicación.

El usuario pidió una imagen completa antes de recortarla. Por eso el máster incluye cielo y terreno opacos; la transparencia se aplicará a las capas extraídas. El archivo generado mide 2172 × 724 px (3:1), aunque el prompt solicitó una composición 6:1. No se estiró ni se duplicaron bordes para simular más longitud. La distribución definitiva de los 20 niveles deberá comprobarse al preparar los recortes y el encuadre.

Planos previstos: cielo y relieve muy lejano; bosque distante; árboles próximos y terreno con camino, puente y arroyo; vegetación del primer plano. Esta imagen todavía no contiene capas separadas ni fondos reconstruidos bajo los elementos que se recorten.

## Prompt utilizado

Create ONE complete ultra-wide horizontal SPRING FOREST panorama, a master illustration for a children's sudoku adventure map. Output a 6:1 panoramic composition, ideally 6144 pixels wide by 1024 high. This must look TWICE as long as a standard 3:1 landscape banner. Use the widest actual output canvas supported. Do not crop a normal short scene or stretch objects sideways: compose a genuinely extended journey with small-to-medium natural trees in correct proportions across a very long horizontal distance.

Style: premium welcoming SunDoku-like rounded 3D storybook illustration, beautifully sculpted leaf clusters, softly painted textures, gentle bright daylight, smooth organic rocks and tree roots. Spring colors: fresh green, emerald, lime, turquoise, pale blue, tiny white, pink and lilac flowers. NO autumn orange, russet, yellow canopies, brown leaf litter, or sunset cast.

The camera looks sideways across a long wooded landscape from a slightly elevated angle. This is a FOREST, with leafy tall deciduous trees and trunks occupying much of the middle distance, rather than a wide open mountain valley. Vary trees naturally along the entire journey. The woodland gets lighter and denser in different stretches.

A SINGLE CLEAR EARTHEN WALKING PATH travels continuously left to right throughout the ENTIRE image, staying between 55% and 72% of canvas height. It winds in several broad shallow curves, with room for TWENTY WELL-SPACED LEVEL LOCATIONS in the form of natural widened clearings. The route never forks, never spirals, never crosses itself, never disappears behind a tree, and never retreats into the far distance. Level locations are empty natural path areas: do NOT draw numbers, circles, badges or actual buttons. The entire journey should remain legible in a horizontal scrolling game.

Organically connect several distinct stretches: open green woodland entrance; flowering grove; deeper ferny woodland; a narrow turquoise brook with ONE low wooden footbridge around the middle; mossy roots and stones; a bright final green clearing among tall oaks. Natural continuous transitions, no repeated tree clones, no mirrored scenery, no abrupt seams. Do not put a giant framing tree over the left or right route; preserve lateral overscan for future parallax.

Design clear FOUR SEPARABLE DEPTH PLANES in this one full scene:
- Background: a narrow band of pale blue sky across the top, with just a few isolated fluffy clouds and modest far blue-green hills.
- Distance: cool muted blue-green woodland, simple connected treetop silhouettes easily traceable against sky, consistent mid-distance contrast.
- Main terrain: sharper green tree groups, fully readable trunks rooted behind or beside the main path, grass, earth path, bridge and stream banks. A distinct clean contour separates nearby terrain/tree groups from distant trees. Keep ALL walking surfaces and bridge on this plane.
- Foreground: low fern, broad-leaf plant, rock and spring flower clumps in the bottom 12–18%, separate dark green silhouettes, not touching or hiding the path, with enough underlying terrain visible to later reconstruct small hidden portions.

No visual cut lines or diagrams; make the natural silhouettes clear enough to tell where layer boundaries will be. Avoid tangled crossing branches, vines joining layers, motion blur, bloom, haze smearing contours, light rays crossing everything, heavy depth-of-field blur, shadows connecting distant and nearby planes. Perspective and light consistent across the full width. Sky and ground genuinely painted all the way to the edges. This is a COMPLETE ENVIRONMENTAL ART MASTER, not a screenshot, sprite sheet, collage, strip of panels or a UI design. Absolutely no text, symbols, characters, UI, numbers, watermark, panels or transparency checkerboard.

The user's current request explicitly requires the complete scenery master first, before extraction; the project cutout rules below are requirements for the later extracted foreground assets and do NOT remove the painted sky or background from this complete master:
Genuine transparent RGBA PNG background. Every pixel outside the requested foreground artwork must have zero alpha, including gaps between elements. No opaque background, no painted checkerboard, no scenery, no replacement backdrop, no wide halo. Preserve the foreground artwork and its clean antialiased edges.
Extract or generate only the requested individual reusable UI artwork, never a complete screen or a flattened modal. Keep modal, card, panel and button surfaces blank, with no text, lettering, captions, labels or variable values. All UI text will be rendered separately with Flutter Text widgets. Reuse existing yellow buttons, cards and panels; do not redraw them as part of this asset. Keep the artwork independent from layout so Flutter can center the content and place yellow action buttons in the bottom action area.
