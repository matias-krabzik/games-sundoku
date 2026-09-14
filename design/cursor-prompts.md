# Cursor de SunDoku

El usuario eligió la primera opción de la fila superior: flecha azul con borde
marfil y dorado. Generada con la herramienta integrada de imágenes. Los diseños
alternativos son solo referencias; el recurso final debe ser un PNG RGBA con
transparencia real y sin resplandor exterior.

## Prompt de extracción del cursor elegido

Use case: background-extraction.
EDIT THE ATTACHED COMPARISON IMAGE. Extract ONLY the very first cursor, the cobalt blue arrow in the TOP LEFT. The user has selected exactly this arrow. Preserve its exact shape, orientation, rich blue face, ivory inner rim, slim gold outer rim, and internal 3D highlights. Do not invent a new cursor. Remove the other five cursors entirely.
Deliver ONE isolated cursor centered on a compact square canvas, with small transparent padding. The arrow is the only opaque object, occupies about 85% of canvas height, and points upper left exactly as in the source. This must be a usable mouse cursor asset, with a clearly visible top-left tip.
CRITICAL CORRECTION: the source's black backdrop and broad yellow/blue lighting halos are NOT part of the art. REMOVE ALL black background AND all fuzzy glow AND all projected shadows. Do NOT reproduce a spotlight, vignette, dark rectangle or checkerboard. Output a PNG with real alpha zero everywhere outside the hard outlined arrow silhouette, including the notch. Only clean one-pixel antialiasing at its edge. Keep highlight shading inside the arrow. No text.
Genuine transparent RGBA PNG background. Every pixel outside the requested foreground artwork must have zero alpha, including gaps between elements. No opaque background, no painted checkerboard, no scenery, no replacement backdrop, no wide halo. Preserve the foreground artwork and its clean antialiased edges.
Extract or generate only the requested individual reusable UI artwork, never a complete screen or a flattened modal. Keep modal, card, panel and button surfaces blank, with no text, lettering, captions, labels or variable values. All UI text will be rendered separately with Flutter Text widgets. Reuse existing yellow buttons, cards and panels; do not redraw them as part of this asset. Keep the artwork independent from layout so Flutter can center the content and place yellow action buttons in the bottom action area.
