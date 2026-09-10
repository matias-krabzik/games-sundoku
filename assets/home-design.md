# Home screen artwork

The built-in image generation tool extracted/recreated the illustrated UI elements from the approved SunDoku home concept. Text remains live Flutter text using the existing Baloo 2 font; the status uses the real catalog count (10), not the example value 13 in the concept.

## Assets

- `images/home/play-button.png`: exec-d1120272-2fb5-479f-af7f-e1978537b6b4.png.
- `images/home/status-panel.png`: exec-9ed93cd5-9700-47ec-93a8-97cc44609bc0.png.
- `images/home/icons.png`: exec-a668de60-500b-4bbe-8f60-8bb25002f9e6.png.
- `images/home/header-surfaces.png`: exec-469f02f6-1554-403e-bb36-09e3e884f195.png.
- `images/home/progress.png`: exec-cfaab5ac-0e8d-468b-a114-df8626bf6fa9.png.

All five shipped PNGs were inspected as RGBA, with nonconstant alpha and completely transparent corners. Header background removal removed a baked checkerboard. The progress atlas includes translucent glow outside the bar; runtime regions isolate the bar. HomeArt and HomeIcon clip source regions at runtime without resampling or altering the source PNGs. The settings gear reuses the existing transparent settings atlas.

Profile and settings share a 54 px top row. Profile shows the chosen saved name, or Jugador; opening it allows editing and persistence via GameRepository.setPlayerName. Buttons reuse JuicyPress, feedback and accessible labels.

## Verification

- Flutter analysis: no issues found.
- Existing settings tests and updated home/navigation tests pass; five new profile tests cover default and chosen names, reactive updates, persisted edits, empty-name fallback, and failed-write retry.
- Rendered and inspected the actual Flutter widgets at 390 × 844, 320 × 568, and 844 × 390 with Baloo 2 loaded and all image assets decoded. No overflow; profile and settings are aligned. Long names and 2× text scaling are covered by the home test.
- Development server restarted with the final assets and layout.

## Prompts

### play-button

Use case: background-extraction. Input image is the exact SunDoku home-screen reference. Extract/recreate its golden Jugar button as ONE blank production UI asset. Preserve the rounded golden-yellow pill silhouette, bright creamy rim, polished softly sculpted 3D face, orange lower lip and subtle shadow. Remove all text and play icon. Front-on orthographic view, width:height 3.2:1. Center on 1536x1024 canvas with substantial empty margins. REAL TRANSPARENT ALPHA PNG background, every pixel outside the button and its small soft contact shadow is fully transparent. No checkerboard, no solid background, no words, no icons, no scenery. Match the reference faithfully.

### status-panel

Use case: background-extraction. Input image is the exact SunDoku home-screen reference. Extract/recreate only its bottom warm ivory status card as ONE blank production UI panel, width:height approximately 3.1:1. Preserve its rounded corners, creamy white upper rim, warm ivory face, golden beige lower bevel and subtle contact shadow. Remove all text, icons, progress bar and dividers so its face is completely blank. Orthographic front-on view. Center on landscape 1536x1024 canvas with empty margins. REAL TRANSPARENT ALPHA PNG background, zero opacity outside panel and small shadow. No checkerboard, no solid background, no scenery, no text.

### icons

Use case: background-extraction. Input image is the exact SunDoku home-screen reference. Create a production transparent PNG sprite atlas with exactly FOUR isolated UI icons, in a precise 2x2 grid on a square 1024x1024 canvas, equal 512x512 cells. Top left: reference's golden sun status icon (round glossy gold sun with eight small thick rounded gold rays, no face). Top right: reference's world icon (two rounded green hills, a winding cream path and two rounded trees). Bottom left: reference's navy rounded triangular play icon pointing right. Bottom right: a matching navy user profile icon (simple circular head and round shoulder bust, no face). Each icon centered in its cell and contained in middle 75% of cell. Exact polished soft 3D style, navy #082A62, warm sculpted highlights. REAL TRANSPARENT ALPHA BACKGROUND, every area between icons fully transparent. No checkerboard, no card, no buttons, no text, no labels, no extra icons.

### header-surfaces

Use case: background-extraction. Input image is exact SunDoku home-screen reference. Create a production transparent PNG atlas of exactly TWO cream button surfaces, vertically stacked in two equal rows on square 1024x1024 canvas. TOP ROW: extract the reference's top-right settings button but remove the gear; one blank circular ivory button 360x360 centered at (512,256). BOTTOM ROW: matching blank rounded ivory pill profile button width 850 height 300 centered at (512,768). Same warm white upper edge, soft ivory face, pale gold lower bevel, restrained soft contact shadow, soft polished 3D material as reference settings button. Orthographic straight-on. REAL TRANSPARENT ALPHA PNG background; all space outside the buttons and small contact shadows must be zero opacity. No checkerboard, no scenery, no text, no icons, no labels.

Cleanup: Remove the entire gray-and-white checkerboard background from this two-button image. Keep only both cream buttons, at the same exact positions, sizes and shapes. TRUE transparent PNG with a real alpha channel; every background pixel must be alpha zero. No replacement background, no checkerboard, no cloudy residue. Preserve both button surfaces fully opaque, smooth accurate antialiased edges. This is ONLY a background removal operation.

### progress

Use case: background-extraction. Input image is exact SunDoku home-screen reference. Extract the progress bar's materials as TWO separate isolated production game UI assets arranged in two equal rows on a landscape 1536x1024 transparent PNG atlas. TOP ROW: one EMPTY horizontal pill shaped recessed warm beige progress track, width 1250 pixels height 90 pixels, centered at (768,256), cream fine rim and softly shaded inset. BOTTOM ROW: one FULL golden-yellow progress fill pill, width 1250 pixels height 90 pixels, centered at (768,768), glossy yellow face, pale yellow thin top rim, orange lower edge, rounded end caps, matching original gold fill precisely. Both straight-on orthographic, identical dimensions. REAL TRANSPARENT ALPHA PNG background outside each slender pill, zero opacity. No solid background, no checkerboard, no text, no panels, no other elements.

Cleanup: Remove the entire cloudy glowing backdrop from this two-progress-bars image. Keep only the actual two solid pill shaped bars at exactly the same positions and sizes. Remove ALL wide halos, glow, cloudy areas and shadows outside their crisp silhouettes. TRUE transparent PNG real alpha, every background pixel must be alpha zero. Both pill shaped bars must remain solid and opaque, clean smooth antialiased edges. No backdrop, no checkerboard, no black, no glow, no shadows. Background removal only, do not change shapes.

Final progress alpha cleanup: Remove the background. Keep only the two pill bars, isolated on genuine transparency. All gray and white checkerboard background pixels must have zero alpha. Export RGBA PNG. No checkerboard. Do not replace background. Real transparency.
