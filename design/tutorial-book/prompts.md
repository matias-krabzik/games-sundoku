# Libro de Solara: arte de producción

Herramienta integrada `image_gen`, modo edición con `transparent_background: true`.
Referencia aprobada: `exec-d6be724f-4ba3-4824-a768-1fc1c302f145.png`.
Se extrae únicamente la superficie vacía del libro; la ilustración de cada mundo, el sol, el lápiz, las estrellas y las flechas reutilizan arte existente. Todos los textos y cuadrículas se componen en Flutter.

## Prompt de la superficie

```text
Use case: background-extraction.
Edit target: the approved El libro de Solara concept (input image).
Requested asset: ONLY its blank single-page physical book surface, extracted for a reusable Flutter UI background.
Preserve the illustrated cobalt blue leather cover and left spine, slim raised golden bands, one small gold sun medallion on the spine, gilt corner protectors, the warm ivory single page with fine gold inset perimeter border, the layered ivory paper edges at right and bottom, the small curled LOWER-RIGHT paper corner and attached blue-and-gold bottom bookmark. EXACTLY ONE visible page, frontal, fully visible with generous transparent margin. Keep the book's cheerful SunDoku soft sculpted finish and ivory/gold/cobalt palette. Keep the spine about 9% of the book width and the right cover narrow so real text has room. No perspective tilt.
REMOVE ALL typography, all letters and numbers, chapter heading, all interior scenery and puzzle illustration, all content, all divider flourishes and top sun decoration, all arrows, round navigation buttons and links. The page interior must be continuous blank warm off-white paper, lightly textured and luminous, with no dark patches. Keep the fine gold perimeter only at its edges. Leave a large uninterrupted central rectangular area suitable for nine-patch expansion. Preserve the corner protectors and layered paper silhouette; do not make a two-page spread.
Remove every outer glow, gradient backdrop, scenery and contact shadow outside the physical book silhouette. No floating detached objects or surrounding UI.
Extract or generate only the requested individual reusable UI artwork, never a complete screen or a flattened modal. Keep modal, card, panel and button surfaces blank, with no text, lettering, captions, labels or variable values. All UI text will be rendered separately with Flutter Text widgets. Reuse existing yellow buttons, cards and panels; do not redraw them as part of this asset. Keep the artwork independent from layout so Flutter can center the content and place yellow action buttons in the bottom action area.

Genuine transparent RGBA PNG background. Every pixel outside the requested foreground artwork must have zero alpha, including gaps between elements. No opaque background, no painted checkerboard, no scenery, no replacement backdrop, no wide halo. Preserve the foreground artwork and its clean antialiased edges.
```
