# Capas de Ríos Cruzados — prompts

Generadas con `image_gen` integrado. Los fondos son opacos; terreno y primer plano usan alfa real.

## 01-backdrop

```text
Use case: background-extraction. Extract and reconstruct ONE BACKDROP parallax layer from the input SunDoku master, preserving its canvas registration and distant perspective.
Keep ONLY the bright blue sky, soft white clouds, distant atmospheric blue mountain ridges and tiny distant tree/grass line. Remove ALL large or medium trees, nearby shrubs, flowers, bridge, golden path, rocks, foreground vegetation and nearby water. Reconstruct the sky and distant hills behind those removed objects naturally. Maintain the far horizon at its original y position, around y250, not centered or raised. Extend soft low-detail distant green land continuously downward from the horizon to the bottom edge, as hidden backing behind the separate terrain. No new foreground objects. No water, path, bridges, near trees or big rocky cascade mountain.
This is a full-bleed opaque background plane and should fill the entire rectangle. Match original lighting, color and SunDoku sculpted illustration style, softer in the distance. Keep original native width and height, never crop, trim, shift, zoom, stretch or frame. No text, controls, number markers, UI, labels or watermarks.
The requested individual reusable artwork is the background plane itself, which fills all pixels of the rectangle. The following required transparency clause applies outside that requested plane, of which this full rectangle has none; it must not produce blank holes in the sky/backing.
Genuine transparent RGBA PNG background. Every pixel outside the requested foreground artwork must have zero alpha, including gaps between elements. No opaque background, no painted checkerboard, no scenery, no replacement backdrop, no wide halo. Preserve the foreground artwork and its clean antialiased edges.
Extract or generate only the requested individual reusable UI artwork, never a complete screen or a flattened modal. Keep modal, card, panel and button surfaces blank, with no text, lettering, captions, labels or variable values. All UI text will be rendered separately with Flutter Text widgets. Reuse existing yellow buttons, cards and panels; do not redraw them as part of this asset. Keep the artwork independent from layout so Flutter can center the content and place yellow action buttons in the bottom action area.
Native registered canvas: 2172x724. Reconstruct the sky behind the tall left woodland trees.
```

## 01-terrain

```text
Use case: background-extraction.
Extract the TERRAIN / MAIN SCENE parallax layer from the supplied exact SunDoku panorama.
KEEP at their original size and exact x/y positions: all large nearby trees, shrubs behind and beside the path, the full golden path, grassy banks, all rivers and stones and water plants belonging to the landscape. Keep landscape pixels extending solidly to the BOTTOM and BOTH SIDE edges. Remove the sky, clouds, distant blue mountains and tiny distant treeline, revealing genuine alpha above and between the main-scene silhouettes.
Also REMOVE only the very nearest oversized leaves, irises, reeds, daisies and boulders that form the bottom decorative foreground border, reconstructing natural grass/earth/water behind them to the bottom edge. Do not remove middle-ground shrubs beside the path.
Canvas MUST remain exactly 2172x724. Do not crop, trim, shift, enlarge, zoom, stretch or reposition any retained element. This is a registered reusable landscape layer, NOT a floating island or centered asset. Top/holes are transparent; ground/water remains solid to the bottom. Keep the original approved rendering and colors.

Return an actual RGBA PNG whose absent sky pixels and gaps have alpha=0. A checkerboard is not artwork and MUST NOT be painted. No solid gray/white/black matte. No drawn grid. Preserve delicate antialiased vegetation edges.
Genuine transparent RGBA PNG background. Every pixel outside the requested foreground artwork must have zero alpha, including gaps between elements. No opaque background, no painted checkerboard, no scenery, no replacement backdrop, no wide halo. Preserve the foreground artwork and its clean antialiased edges.
Extract or generate only the requested individual reusable UI artwork, never a complete screen or a flattened modal. Keep modal, card, panel and button surfaces blank, with no text, lettering, captions, labels or variable values. All UI text will be rendered separately with Flutter Text widgets. Reuse existing yellow buttons, cards and panels; do not redraw them as part of this asset. Keep the artwork independent from layout so Flutter can center the content and place yellow action buttons in the bottom action area.
The requested individual reusable artwork here is the registered terrain layer. No UI, text, numbers, controls, border or watermark.
```

## 01-foreground

```text
Use case: background-extraction.
Extract ONLY the very closest FOREGROUND vegetation border from this exact SunDoku map panorama: the oversized sculpted reeds/cattails, irises, daisies, rounded leaves, nearest low shrubs and nearest decorative boulders touching the lower edge. Preserve the same x/y positions, apparent size, silhouettes and colors as in the original. Keep just those nearest decorations, mainly within the bottom quarter; do NOT include middle-ground shrubs, trees, tree trunks, bridges, the golden path, grass terrain, water, lily pads floating in water, hills, sky or clouds.
Everything above and BETWEEN the extracted plant/rock silhouettes must be genuine alpha=0. Keep individual plant gaps transparent. NO rectangular strip of grass or water behind plants. No shadows painted on an opaque ground. All retained objects must stay registered to the original full panoramic canvas, not centered, rearranged or enlarged. Keep the full original image width/height. Never crop or trim the large empty top. Near objects may touch original bottom/side edges exactly as in the reference.
This is one reusable registered foreground parallax layer, not a whole game screen. Render true RGBA PNG, no painted checkerboard, no solid black/gray/white matte.
Genuine transparent RGBA PNG background. Every pixel outside the requested foreground artwork must have zero alpha, including gaps between elements. No opaque background, no painted checkerboard, no scenery, no replacement backdrop, no wide halo. Preserve the foreground artwork and its clean antialiased edges.
Extract or generate only the requested individual reusable UI artwork, never a complete screen or a flattened modal. Keep modal, card, panel and button surfaces blank, with no text, lettering, captions, labels or variable values. All UI text will be rendered separately with Flutter Text widgets. Reuse existing yellow buttons, cards and panels; do not redraw them as part of this asset. Keep the artwork independent from layout so Flutter can center the content and place yellow action buttons in the bottom action area.
No text, numbers, UI, frames or watermarks.
Original canvas 2172x724. Retain the prominent near-bottom-left purple irises, cattails and low leafy plants, plus the near bottom-edge rocks/leaves spread across the width. Do not keep the tall woodland trees or tall willow.
```

## 02-backdrop

```text
Use case: background-extraction. Extract and reconstruct ONE BACKDROP parallax layer from the input SunDoku master, preserving its canvas registration and distant perspective.
Keep ONLY the bright blue sky, soft white clouds, distant atmospheric blue mountain ridges and tiny distant tree/grass line. Remove ALL large or medium trees, nearby shrubs, flowers, bridge, golden path, rocks, foreground vegetation and nearby water. Reconstruct the sky and distant hills behind those removed objects naturally. Maintain the far horizon at its original y position, around y250, not centered or raised. Extend soft low-detail distant green land continuously downward from the horizon to the bottom edge, as hidden backing behind the separate terrain. No new foreground objects. No water, path, bridges, near trees or big rocky cascade mountain.
This is a full-bleed opaque background plane and should fill the entire rectangle. Match original lighting, color and SunDoku sculpted illustration style, softer in the distance. Keep original native width and height, never crop, trim, shift, zoom, stretch or frame. No text, controls, number markers, UI, labels or watermarks.
The requested individual reusable artwork is the background plane itself, which fills all pixels of the rectangle. The following required transparency clause applies outside that requested plane, of which this full rectangle has none; it must not produce blank holes in the sky/backing.
Genuine transparent RGBA PNG background. Every pixel outside the requested foreground artwork must have zero alpha, including gaps between elements. No opaque background, no painted checkerboard, no scenery, no replacement backdrop, no wide halo. Preserve the foreground artwork and its clean antialiased edges.
Extract or generate only the requested individual reusable UI artwork, never a complete screen or a flattened modal. Keep modal, card, panel and button surfaces blank, with no text, lettering, captions, labels or variable values. All UI text will be rendered separately with Flutter Text widgets. Reuse existing yellow buttons, cards and panels; do not redraw them as part of this asset. Keep the artwork independent from layout so Flutter can center the content and place yellow action buttons in the bottom action area.
Native registered canvas: 2170x725. Reconstruct the unobstructed distant horizon behind removed near trees and rocky cascade structures. The far horizon must be continuous.
```

## 02-terrain

```text
Use case: background-extraction.
Extract the TERRAIN / MAIN SCENE parallax layer from the supplied exact SunDoku panorama.
KEEP at their original size and exact x/y positions: all large nearby trees, shrubs behind and beside the path, the full golden path, grassy banks, all rivers and stones and water plants belonging to the landscape. Keep landscape pixels extending solidly to the BOTTOM and BOTH SIDE edges. Remove the sky, clouds, distant blue mountains and tiny distant treeline, revealing genuine alpha above and between the main-scene silhouettes.
Also REMOVE only the very nearest oversized leaves, irises, reeds, daisies and boulders that form the bottom decorative foreground border, reconstructing natural grass/earth/water behind them to the bottom edge. Do not remove middle-ground shrubs beside the path.
Canvas MUST remain exactly 2170x725. Do not crop, trim, shift, enlarge, zoom, stretch or reposition any retained element. This is a registered reusable landscape layer, NOT a floating island or centered asset. Top/holes are transparent; ground/water remains solid to the bottom. Keep the original approved rendering and colors.

Return an actual RGBA PNG whose absent sky pixels and gaps have alpha=0. A checkerboard is not artwork and MUST NOT be painted. No solid gray/white/black matte. No drawn grid. Preserve delicate antialiased vegetation edges.
Genuine transparent RGBA PNG background. Every pixel outside the requested foreground artwork must have zero alpha, including gaps between elements. No opaque background, no painted checkerboard, no scenery, no replacement backdrop, no wide halo. Preserve the foreground artwork and its clean antialiased edges.
Extract or generate only the requested individual reusable UI artwork, never a complete screen or a flattened modal. Keep modal, card, panel and button surfaces blank, with no text, lettering, captions, labels or variable values. All UI text will be rendered separately with Flutter Text widgets. Reuse existing yellow buttons, cards and panels; do not redraw them as part of this asset. Keep the artwork independent from layout so Flutter can center the content and place yellow action buttons in the bottom action area.
The requested individual reusable artwork here is the registered terrain layer. No UI, text, numbers, controls, border or watermark.
Specific preservation rule: Preserve the stone bridge and its complete stream/banks in THIS layer. The large calm lake is part of terrain, not transparent. Keep the nearer opposite lake shore and nearby islands. Remove only far blue mountains/tiny distant forest and sky.
```

## 03-backdrop

```text
Use case: background-extraction. Extract and reconstruct ONE BACKDROP parallax layer from the input SunDoku master, preserving its canvas registration and distant perspective.
Keep ONLY the bright blue sky, soft white clouds, distant atmospheric blue mountain ridges and tiny distant tree/grass line. Remove ALL large or medium trees, nearby shrubs, flowers, bridge, golden path, rocks, foreground vegetation and nearby water. Reconstruct the sky and distant hills behind those removed objects naturally. Maintain the far horizon at its original y position, around y250, not centered or raised. Extend soft low-detail distant green land continuously downward from the horizon to the bottom edge, as hidden backing behind the separate terrain. No new foreground objects. No water, path, bridges, near trees or big rocky cascade mountain.
This is a full-bleed opaque background plane and should fill the entire rectangle. Match original lighting, color and SunDoku sculpted illustration style, softer in the distance. Keep original native width and height, never crop, trim, shift, zoom, stretch or frame. No text, controls, number markers, UI, labels or watermarks.
The requested individual reusable artwork is the background plane itself, which fills all pixels of the rectangle. The following required transparency clause applies outside that requested plane, of which this full rectangle has none; it must not produce blank holes in the sky/backing.
Genuine transparent RGBA PNG background. Every pixel outside the requested foreground artwork must have zero alpha, including gaps between elements. No opaque background, no painted checkerboard, no scenery, no replacement backdrop, no wide halo. Preserve the foreground artwork and its clean antialiased edges.
Extract or generate only the requested individual reusable UI artwork, never a complete screen or a flattened modal. Keep modal, card, panel and button surfaces blank, with no text, lettering, captions, labels or variable values. All UI text will be rendered separately with Flutter Text widgets. Reuse existing yellow buttons, cards and panels; do not redraw them as part of this asset. Keep the artwork independent from layout so Flutter can center the content and place yellow action buttons in the bottom action area.
Native registered canvas: 2171x724. Reconstruct the unobstructed distant horizon behind removed near trees and rocky cascade structures. The far horizon must be continuous.
```

## 03-terrain

```text
Use case: background-extraction.
Extract the TERRAIN / MAIN SCENE parallax layer from the supplied exact SunDoku panorama.
KEEP at their original size and exact x/y positions: all large nearby trees, shrubs behind and beside the path, the full golden path, grassy banks, all rivers and stones and water plants belonging to the landscape. Keep landscape pixels extending solidly to the BOTTOM and BOTH SIDE edges. Remove the sky, clouds, distant blue mountains and tiny distant treeline, revealing genuine alpha above and between the main-scene silhouettes.
Also REMOVE only the very nearest oversized leaves, irises, reeds, daisies and boulders that form the bottom decorative foreground border, reconstructing natural grass/earth/water behind them to the bottom edge. Do not remove middle-ground shrubs beside the path.
Canvas MUST remain exactly 2171x724. Do not crop, trim, shift, enlarge, zoom, stretch or reposition any retained element. This is a registered reusable landscape layer, NOT a floating island or centered asset. Top/holes are transparent; ground/water remains solid to the bottom. Keep the original approved rendering and colors.

Return an actual RGBA PNG whose absent sky pixels and gaps have alpha=0. A checkerboard is not artwork and MUST NOT be painted. No solid gray/white/black matte. No drawn grid. Preserve delicate antialiased vegetation edges.
Genuine transparent RGBA PNG background. Every pixel outside the requested foreground artwork must have zero alpha, including gaps between elements. No opaque background, no painted checkerboard, no scenery, no replacement backdrop, no wide halo. Preserve the foreground artwork and its clean antialiased edges.
Extract or generate only the requested individual reusable UI artwork, never a complete screen or a flattened modal. Keep modal, card, panel and button surfaces blank, with no text, lettering, captions, labels or variable values. All UI text will be rendered separately with Flutter Text widgets. Reuse existing yellow buttons, cards and panels; do not redraw them as part of this asset. Keep the artwork independent from layout so Flutter can center the content and place yellow action buttons in the bottom action area.
The requested individual reusable artwork here is the registered terrain layer. No UI, text, numbers, controls, border or watermark.
Specific preservation rule: Keep the entire tall rocky cascade mountain at the far right and all its pine trees IN THIS layer, together with the complete golden path, timber bridges, streams and near foliage. Remove only far blue distant mountain ridges and sky; do not cut out any real river water.
```

## 04-backdrop

```text
Use case: background-extraction. Extract and reconstruct ONE BACKDROP parallax layer from the input SunDoku master, preserving its canvas registration and distant perspective.
Keep ONLY the bright blue sky, soft white clouds, distant atmospheric blue mountain ridges and tiny distant tree/grass line. Remove ALL large or medium trees, nearby shrubs, flowers, bridge, golden path, rocks, foreground vegetation and nearby water. Reconstruct the sky and distant hills behind those removed objects naturally. Maintain the far horizon at its original y position, around y250, not centered or raised. Extend soft low-detail distant green land continuously downward from the horizon to the bottom edge, as hidden backing behind the separate terrain. No new foreground objects. No water, path, bridges, near trees or big rocky cascade mountain.
This is a full-bleed opaque background plane and should fill the entire rectangle. Match original lighting, color and SunDoku sculpted illustration style, softer in the distance. Keep original native width and height, never crop, trim, shift, zoom, stretch or frame. No text, controls, number markers, UI, labels or watermarks.
The requested individual reusable artwork is the background plane itself, which fills all pixels of the rectangle. The following required transparency clause applies outside that requested plane, of which this full rectangle has none; it must not produce blank holes in the sky/backing.
Genuine transparent RGBA PNG background. Every pixel outside the requested foreground artwork must have zero alpha, including gaps between elements. No opaque background, no painted checkerboard, no scenery, no replacement backdrop, no wide halo. Preserve the foreground artwork and its clean antialiased edges.
Extract or generate only the requested individual reusable UI artwork, never a complete screen or a flattened modal. Keep modal, card, panel and button surfaces blank, with no text, lettering, captions, labels or variable values. All UI text will be rendered separately with Flutter Text widgets. Reuse existing yellow buttons, cards and panels; do not redraw them as part of this asset. Keep the artwork independent from layout so Flutter can center the content and place yellow action buttons in the bottom action area.
Native registered canvas: 2172x724. Remove the whole near left waterfall mountain and right destination cliff, reconstructing ONLY the distant far blue ridges/sky behind. Those near features belong to terrain.
```

## 04-terrain

```text
Use case: background-extraction.
Extract the TERRAIN / MAIN SCENE parallax layer from the supplied exact SunDoku panorama.
KEEP at their original size and exact x/y positions: all large nearby trees, shrubs behind and beside the path, the full golden path, grassy banks, all rivers and stones and water plants belonging to the landscape. Keep landscape pixels extending solidly to the BOTTOM and BOTH SIDE edges. Remove the sky, clouds, distant blue mountains and tiny distant treeline, revealing genuine alpha above and between the main-scene silhouettes.
Also REMOVE only the very nearest oversized leaves, irises, reeds, daisies and boulders that form the bottom decorative foreground border, reconstructing natural grass/earth/water behind them to the bottom edge. Do not remove middle-ground shrubs beside the path.
Canvas MUST remain exactly 2172x724. Do not crop, trim, shift, enlarge, zoom, stretch or reposition any retained element. This is a registered reusable landscape layer, NOT a floating island or centered asset. Top/holes are transparent; ground/water remains solid to the bottom. Keep the original approved rendering and colors.

Return an actual RGBA PNG whose absent sky pixels and gaps have alpha=0. A checkerboard is not artwork and MUST NOT be painted. No solid gray/white/black matte. No drawn grid. Preserve delicate antialiased vegetation edges.
Genuine transparent RGBA PNG background. Every pixel outside the requested foreground artwork must have zero alpha, including gaps between elements. No opaque background, no painted checkerboard, no scenery, no replacement backdrop, no wide halo. Preserve the foreground artwork and its clean antialiased edges.
Extract or generate only the requested individual reusable UI artwork, never a complete screen or a flattened modal. Keep modal, card, panel and button surfaces blank, with no text, lettering, captions, labels or variable values. All UI text will be rendered separately with Flutter Text widgets. Reuse existing yellow buttons, cards and panels; do not redraw them as part of this asset. Keep the artwork independent from layout so Flutter can center the content and place yellow action buttons in the bottom action area.
The requested individual reusable artwork here is the registered terrain layer. No UI, text, numbers, controls, border or watermark.
Keep all bridges, real river and lake water, islands, near opposite shore, the entire left rocky waterfall mountain and the right climbing destination cliff IN the terrain layer. Remove only sky, far blue ridges and tiny distant forest. Preserve the path and bridge positions exactly.
```

## 02-foreground

```text
Use case: background-extraction.
Extract ONLY the very closest FOREGROUND vegetation border from this exact SunDoku map panorama: the oversized sculpted reeds/cattails, irises, daisies, rounded leaves, nearest low shrubs and nearest decorative boulders touching the lower edge. Preserve the same x/y positions, apparent size, silhouettes and colors as in the original. Keep just those nearest decorations, mainly within the bottom quarter; do NOT include middle-ground shrubs, trees, tree trunks, bridges, the golden path, grass terrain, water, lily pads floating in water, hills, sky or clouds.
Everything above and BETWEEN the extracted plant/rock silhouettes must be genuine alpha=0. Keep individual plant gaps transparent. NO rectangular strip of grass or water behind plants. No shadows painted on an opaque ground. All retained objects must stay registered to the original full panoramic canvas, not centered, rearranged or enlarged. Keep the full original image width/height. Never crop or trim the large empty top. Near objects may touch original bottom/side edges exactly as in the reference.
This is one reusable registered foreground parallax layer, not a whole game screen. Render true RGBA PNG, no painted checkerboard, no solid black/gray/white matte.
Genuine transparent RGBA PNG background. Every pixel outside the requested foreground artwork must have zero alpha, including gaps between elements. No opaque background, no painted checkerboard, no scenery, no replacement backdrop, no wide halo. Preserve the foreground artwork and its clean antialiased edges.
Extract or generate only the requested individual reusable UI artwork, never a complete screen or a flattened modal. Keep modal, card, panel and button surfaces blank, with no text, lettering, captions, labels or variable values. All UI text will be rendered separately with Flutter Text widgets. Reuse existing yellow buttons, cards and panels; do not redraw them as part of this asset. Keep the artwork independent from layout so Flutter can center the content and place yellow action buttons in the bottom action area.
No text, numbers, UI, frames or watermarks.
Keep the registered 2170x725 canvas. Extract only the near bottom decorative border plants and boulders. Do not keep islands or banks inside the scene. Keep large transparent openings where there is water between the nearest plants.
```

## 03-foreground

```text
Use case: background-extraction.
Extract ONLY the very closest FOREGROUND vegetation border from this exact SunDoku map panorama: the oversized sculpted reeds/cattails, irises, daisies, rounded leaves, nearest low shrubs and nearest decorative boulders touching the lower edge. Preserve the same x/y positions, apparent size, silhouettes and colors as in the original. Keep just those nearest decorations, mainly within the bottom quarter; do NOT include middle-ground shrubs, trees, tree trunks, bridges, the golden path, grass terrain, water, lily pads floating in water, hills, sky or clouds.
Everything above and BETWEEN the extracted plant/rock silhouettes must be genuine alpha=0. Keep individual plant gaps transparent. NO rectangular strip of grass or water behind plants. No shadows painted on an opaque ground. All retained objects must stay registered to the original full panoramic canvas, not centered, rearranged or enlarged. Keep the full original image width/height. Never crop or trim the large empty top. Near objects may touch original bottom/side edges exactly as in the reference.
This is one reusable registered foreground parallax layer, not a whole game screen. Render true RGBA PNG, no painted checkerboard, no solid black/gray/white matte.
Genuine transparent RGBA PNG background. Every pixel outside the requested foreground artwork must have zero alpha, including gaps between elements. No opaque background, no painted checkerboard, no scenery, no replacement backdrop, no wide halo. Preserve the foreground artwork and its clean antialiased edges.
Extract or generate only the requested individual reusable UI artwork, never a complete screen or a flattened modal. Keep modal, card, panel and button surfaces blank, with no text, lettering, captions, labels or variable values. All UI text will be rendered separately with Flutter Text widgets. Reuse existing yellow buttons, cards and panels; do not redraw them as part of this asset. Keep the artwork independent from layout so Flutter can center the content and place yellow action buttons in the bottom action area.
No text, numbers, UI, frames or watermarks.
Keep the registered 2171x724 canvas. Extract only the near bottom decorative border plants and boulders. Do not keep islands or banks inside the scene. Keep large transparent openings where there is water between the nearest plants.
```

## 04-foreground

```text
Use case: background-extraction.
Extract ONLY the very closest FOREGROUND vegetation border from this exact SunDoku map panorama: the oversized sculpted reeds/cattails, irises, daisies, rounded leaves, nearest low shrubs and nearest decorative boulders touching the lower edge. Preserve the same x/y positions, apparent size, silhouettes and colors as in the original. Keep just those nearest decorations, mainly within the bottom quarter; do NOT include middle-ground shrubs, trees, tree trunks, bridges, the golden path, grass terrain, water, lily pads floating in water, hills, sky or clouds.
Everything above and BETWEEN the extracted plant/rock silhouettes must be genuine alpha=0. Keep individual plant gaps transparent. NO rectangular strip of grass or water behind plants. No shadows painted on an opaque ground. All retained objects must stay registered to the original full panoramic canvas, not centered, rearranged or enlarged. Keep the full original image width/height. Never crop or trim the large empty top. Near objects may touch original bottom/side edges exactly as in the reference.
This is one reusable registered foreground parallax layer, not a whole game screen. Render true RGBA PNG, no painted checkerboard, no solid black/gray/white matte.
Genuine transparent RGBA PNG background. Every pixel outside the requested foreground artwork must have zero alpha, including gaps between elements. No opaque background, no painted checkerboard, no scenery, no replacement backdrop, no wide halo. Preserve the foreground artwork and its clean antialiased edges.
Extract or generate only the requested individual reusable UI artwork, never a complete screen or a flattened modal. Keep modal, card, panel and button surfaces blank, with no text, lettering, captions, labels or variable values. All UI text will be rendered separately with Flutter Text widgets. Reuse existing yellow buttons, cards and panels; do not redraw them as part of this asset. Keep the artwork independent from layout so Flutter can center the content and place yellow action buttons in the bottom action area.
No text, numbers, UI, frames or watermarks.
Original canvas 2172x724. Keep only the largest very closest border vegetation and decorative stones in bottom-left and bottom-right and the lowest edge. Exclude the river-bank rocks in the midground, exclude all floating water lilies, keep transparent openings over open water. Do not include either cliff, trees or bridges.
```

