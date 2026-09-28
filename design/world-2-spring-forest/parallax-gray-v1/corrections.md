# Correcciones seleccionadas

Herramienta integrada imagegen, modo edición.

## Terreno: completar respaldo inferior

Fuente: `exec-5bb8660b-7fe4-4c3b-9495-7e76808931c5.png`.
Seleccionada: `exec-8e7810fa-44c2-4073-a0d5-c89a064a773d.png` → `terrain.png`.

```text
Use case: precise-object-edit.
Input image 1 is the EDIT TARGET: an extracted terrain layer, 2172x724. Preserve ALL existing colored artwork, trees, path, bridge and complete dry creek exactly, with no movement, rescaling, redesign or repainting of existing visible details.
ONE REQUIRED CORRECTION: the lower corners were wrongly cut away into gray. FILL ALL GRAY BELOW THE PATH'S FRONT GRASS EDGE with continued gently rolling spring grass and earth down to the bottom canvas edge. This means every pixel of the bottom 35% is painted terrain or dry creek, edge to edge, with no gray wedges, no gray border and no holes. Extend the left grassy meadow from its current lower edge to the bottom left, and the right meadow to the bottom right. Continue the existing central dry creek to the bottom as needed. Do not add new large leaves, foreground ferns, decorative boulders or flowers to this hidden backing; those are another layer. Just simple matching grass and sandy earth. Never truncate the creek.
KEEP THE UPPER GRAY BACKGROUND behind the main trees and above the terrain ridge, including gray openings between branches. Every such upper removed area must be perfectly flat neutral #808080 with no gradient, texture, shadow or color cast. NO TRANSPARENCY; user explicitly requests opaque gray background for this intermediate.
All existing tree silhouettes, all exact bridge ropes and boards, path route, bank heights, colors, style and original 3:1 registration stay unchanged. No text or UI.
Project boilerplate FOR A FUTURE TRANSPARENT EXPORT ONLY; not for this requested gray-matte intermediate (latest user instruction takes precedence):
"Genuine transparent RGBA PNG background. Every pixel outside the requested foreground artwork must have zero alpha, including gaps between elements. No opaque background, no painted checkerboard, no scenery, no replacement backdrop, no wide halo. Preserve the foreground artwork and its clean antialiased edges."
"Extract or generate only the requested individual reusable UI artwork, never a complete screen or a flattened modal. Keep modal, card, panel and button surfaces blank, with no text, lettering, captions, labels or variable values. All UI text will be rendered separately with Flutter Text widgets. Reuse existing yellow buttons, cards and panels; do not redraw them as part of this asset. Keep the artwork independent from layout so Flutter can center the content and place yellow action buttons in the bottom action area."
For THIS deliverable: one environmental layer with a uniform opaque #808080 matte everywhere outside the specified layer, no UI, no text, no labels, no cut lines. Preserve artwork original registration.
```

## Montañas: altura del horizonte

Fuente: `exec-784fc537-b82d-4454-abc1-d259294c6e83.png`.
Seleccionada: `exec-467b33e1-19d3-4e45-a047-87d18bd0cf6f.png` → `mountains.png`.

```text
Use case: precise-object-edit.
Input image 1 is the EDIT TARGET: the mountain-only layer. Keep its shapes, blue colors, materials and panoramic 2172x724 canvas.
One correction: THE ENTIRE MOUNTAIN RANGE IS TOO LOW. Translate the complete mountain artwork vertically UP by about 105 pixels on this unchanged canvas, without horizontal movement, zooming, cropping or changing the ridge shape. The highest ridge summits must now sit at y=75–85 pixels (11% of canvas height), and valleys at y=130–160 pixels, NOT peaks around y=180. This elevated skyline is required so mountains remain visible above the separate forest, matching their height in the original source.
Keep fill continuing all the way down to bottom edge, extending the simple existing muted blue foothill fill where needed. Above the raised skyline keep only uniform neutral gray #808080. No gray below the mountain base. No clouds, green nearby trees, text or added details. Preserve width and x positions of all peaks. User explicitly requests an opaque PNG with gray matte, no transparency.
Project boilerplate FOR A FUTURE TRANSPARENT EXPORT ONLY; not for this requested gray-matte intermediate (latest user instruction takes precedence):
"Genuine transparent RGBA PNG background. Every pixel outside the requested foreground artwork must have zero alpha, including gaps between elements. No opaque background, no painted checkerboard, no scenery, no replacement backdrop, no wide halo. Preserve the foreground artwork and its clean antialiased edges."
"Extract or generate only the requested individual reusable UI artwork, never a complete screen or a flattened modal. Keep modal, card, panel and button surfaces blank, with no text, lettering, captions, labels or variable values. All UI text will be rendered separately with Flutter Text widgets. Reuse existing yellow buttons, cards and panels; do not redraw them as part of this asset. Keep the artwork independent from layout so Flutter can center the content and place yellow action buttons in the bottom action area."
For THIS deliverable: one environmental layer with a uniform opaque #808080 matte everywhere outside the specified layer, no UI, no text, no labels, no cut lines. Preserve artwork original registration.
```
