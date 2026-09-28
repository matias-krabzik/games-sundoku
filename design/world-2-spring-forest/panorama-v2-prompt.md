# Bosque primaveral · versión 2

Imagen: `spring-forest-master-v2.png`.

Edición con la herramienta integrada imagegen. Referencia de composición: `spring-forest-master-v1.png`. Referencia de estilo: `assets/images/world-1-horizontal.png`.

Conserva el bosque y el camino de la versión 1. Formas redondeadas y volumétricas próximas al primer mundo de SunDoku; cauce seco y puente colgante. No se modifica ni integra código del juego. Se conserva la versión 1.

Panorama maestro completo de 2172 × 724 px (3:1), opaco por pedido del usuario; aún no son capas separadas. Para los 20 niveles queda pendiente extender el recorrido y recortar las capas con transparencia real, sin estirar ni espejar. La comprobación visual confirma ausencia de agua y un puente de tablones suspendido sobre el cauce seco.

## Prompt final

```text
Use case: style-transfer.
Asset type: one complete horizontal environmental master illustration for SunDoku world 2, for later parallax layer extraction, not an app screenshot or UI.

INPUT ROLES:
Image 1 (spring-forest-master-v1.png) is the EDIT TARGET. Preserve its overall forest composition, continuous meandering left-to-right path, dense woodland setting, pink spring blossom accents, large trees, foreground ferns/flowers, long panoramic framing and camera.
Image 2 (world-1-horizontal.png) is STYLE REFERENCE ONLY. Match its charming polished dimensional casual-game rendering, SunDoku first-world materials, warm lighting, and sculpted rounded foliage. Do not copy its valley geography, water, sun arch, or layout.

REQUESTED EDIT:
Restyle Image 1 into a playful PopCap Games-like family-friendly forest belonging to the same illustrated world as Image 2. Bold readable rounded volumes; chunky expressive tree trunks with smooth curved roots, dense sculpted clusters of apple-green foliage, plump shrubs, smooth mossy rocks, simplified individually readable ferns and white daisies; clean warm soft shading, subtle ambient occlusion, soft highlights and a high-quality painted 3D casual-game feel. Deliberately less naturalistic tiny leaf detail than Image 1. Still a lush actual woodland, with tall trees and canopy, not an open meadow. Bright spring lime/emerald greens, restrained pink/lilac blossoms, pale golden dirt path, clear blue sky, fresh and inviting. No autumn oranges.

REPLACE THE WATER AND BRIDGE:
Remove ALL river water from Image 1, including the distant cascade, central stream and foreground stream. Replace the entire course with a clearly DRY rocky creek bed: sand, smooth rounded gray-beige river stones, a modest eroded earth ravine with grassy mossy banks. NO water, puddles, turquoise channel, waterfall or lake anywhere.
At the same central crossing, replace the low solid-railing bridge with a charming unmistakable HANGING SUSPENSION FOOTBRIDGE: slightly sagging wooden plank deck spanning bank to bank, curved thick rope handrails on both sides, spaced vertical rope hangers and sturdy wooden anchor posts at both ends. A modest visible drop beneath it reveals the dry riverbed, not a dark dangerous abyss. Bridge and path connect logically on both banks; readable side/three-quarter view; no rigid arched stone or timber bridge. Keep the forest lush and springlike around this localized dry riverbed.

COMPOSITION FOR LATER PARALLAX:
One uninterrupted panoramic scene at the same 3:1 aspect ratio, full bleed, no montage or borders, no stretching or mirrored repeated trees. Preserve the winding walkable route across the lower-middle with open breathing room for future level controls (do not draw them).
Four legible depth planes: airy blue sky, cooler softer distant forest/hills, warmer main trees/terrain/path/bridge, darker near ferns/flowers/rocks along the bottom edge. Clearly readable silhouette boundaries with limited fine crossing twigs; don't obscure the path with foreground plants. Keep natural variation and continuity across the entire width. All requested scene pixels should be painted and opaque for this complete master.

CURRENT DELIVERABLE EXCEPTION: the user explicitly requests a COMPLETE environmental image before cutting it later, so output the entire opaque landscape including sky and ground now, not isolated sprites or a transparent cutout. The following standing project instructions are recorded for FUTURE individual layer/UI extraction and do not override this explicit complete-master request:
"Genuine transparent RGBA PNG background. Every pixel outside the requested foreground artwork must have zero alpha, including gaps between elements. No opaque background, no painted checkerboard, no scenery, no replacement backdrop, no wide halo. Preserve the foreground artwork and its clean antialiased edges."
"Extract or generate only the requested individual reusable UI artwork, never a complete screen or a flattened modal. Keep modal, card, panel and button surfaces blank, with no text, lettering, captions, labels or variable values. All UI text will be rendered separately with Flutter Text widgets. Reuse existing yellow buttons, cards and panels; do not redraw them as part of this asset. Keep the artwork independent from layout so Flutter can center the content and place yellow action buttons in the bottom action area."

No text, captions, logos, numbers, buttons, HUD, characters, houses, crystals, mushrooms as fantasy landmarks, sun gates, cut guides or watermark. The sole deliverable is the revised complete spring woodland panorama.
```
