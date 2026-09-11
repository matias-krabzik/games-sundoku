# Illustrated map UI

Built-in image generation extracted/recreated the approved map indicators as reusable RGBA PNG artwork. The world background `images/world-1-horizontal.png` and level path coordinates remain unchanged. The existing HomeArt cream panels, round cream buttons, sun emblem, progress textures and Baloo 2 typeface are reused. Existing transparent navy number images remain separate so all ten levels display current state.

## Assets

- `images/map/marker-gold.png`: exec-edac02dd-9480-4225-9c79-ca12bec28db0.png.
- `images/map/marker-ivory.png`: exec-8fa0bece-6cf0-49a9-ba64-bf13bc3bcdbb.png.
- `images/map/icons.png`: exec-daad3dd1-8148-44c3-9e35-aa34fa655673.png.

The marker images combine a blank medallion and blank navy crest. Gold and ivory variants are cropped to a common runtime geometry. The icon atlas contains earned/unearned stars, back arrow, chevron, lock and gold round button. Each source is RGBA with alpha 0–255; no simulated checkerboard remains. PNGs are preserved as generated; source regions are clipped at runtime in MapIcon and MapMarkerArt.

Active or completed unlocked levels use gold. Other available levels use ivory. Locked levels use subdued ivory with a lock. Stars reflect zero through three earned points individually; the award animation and selection light use the same geometry. The selection halo is softer and does not wash out the number. Previous/next/back controls use JuicyPress, sound/haptic feedback and accessible labels. DEV controls remain debug-only and can be suppressed for visual preview via showDeveloperControls:false.

## Prompts

### marker-gold

Use case: background-extraction. Input image is the approved SunDoku map UI. Extract and faithfully recreate EXACTLY the large selected level-1 indicator as a single isolated reusable game asset: the beautiful thick glossy gold round medallion, pale cream golden rim, raised yellow face, orange lower bevel, together with the short curved navy-blue ribbon/crest attached directly behind its upper portion, gold piping and gold curled ribbon ends. Preserve its exact proportions, front-on/slightly dimensional view, sculpted materials and lighting. REMOVE ONLY the number 1 and the three stars, leaving a perfectly blank gold circle face and perfectly blank navy ribbon. Do not leave star-shaped holes, placeholders, sockets or embossed star shapes. Keep the ribbon and medallion connected like the original. On a square 1024x1024 canvas, center the entire complete indicator with 10 percent empty margins. TRUE transparent RGBA PNG background, completely transparent outside the object and its tiny soft contact shadow. No scenery, no ground plane, no cloudy backdrop, no glow, no checkerboard, no text, no extra objects. Fidelity to the reference indicator is critical.

### marker-ivory

Use case: background-extraction. Input image is the approved SunDoku map UI. Extract/recreate EXACTLY the available level-2 indicator (cream circular medallion + navy crest) as ONE complete isolated reusable game asset; reconstruct the right portion cropped by the reference edge. Match the design, shape and proportions of the fully visible level-1 indicator, but use the IVORY cream/pale golden medallion face and rim from level 2. A short curved navy-blue ribbon/crest directly behind upper circle, gold piping and curled gold ends, thick creamy circular rim, softly sculpted ivory face and warm pale golden lower bevel. REMOVE the number 2 and ALL three stars: perfectly blank ivory circle face and perfectly blank navy ribbon, no star-shaped holes or placeholders. Front-on/slightly dimensional view like reference. Square 1024x1024 canvas, complete connected indicator centered with 10 percent empty margins. REAL TRANSPARENT RGBA PNG background, completely transparent outside object and tiny contact shadow. No scenery, no ground, no cloudy backdrop, no checkerboard, no glow, no text. Match original exactly.

### icons

Use case: background-extraction. Input image is the approved SunDoku map UI. Create a production PNG atlas of exactly SIX separate UI elements on a square 1536x1536 canvas in a perfectly regular 3-column by 2-row grid, each invisible cell512x768. TOP ROW, left to right: 1) extract one five-pointed GOLD STAR from level-1 crest, glossy gold yellow center, rounded points, narrow orange-gold edge and sculpted cream highlights, exact original shape; 2) extract one unearned SILVER/IVORY star from level-2 crest, identical shape and size to gold star, warm silver cream face and subdued gray bevel; 3) extract navy LEFT BACK ARROW from the upper-left navigation, thick rounded 3D navy blue. BOTTOM ROW left to right: 4) extract navy RIGHT CHEVRON from bottom next button, thick rounded 3D navy; 5) a simple tiny navy CLOSED PADLOCK with rounded soft 3D same material; 6) extract bottom-right golden CIRCULAR BUTTON but REMOVE the chevron so its face is blank gold with cream rim, orange lower bevel. Everything exact style of input. Center each element in its cell, all contained inside a centered 360x360 square in each cell. Do not include ribbons or medallions, except the one explicitly requested circle in last cell. REAL TRANSPARENT RGBA PNG background, zero alpha between and outside icons, no checkerboard, no scenery, no solid background, no cloudy residues, no text, no labels. Carefully match reference.

### Geometry-preserving ivory variant

Edit this exact indicator. Change ONLY the circular medallion's yellow face and yellow ring into warm ivory cream like the reference's available level-2 marker, with pale champagne-gold bevel. Preserve the identical shape, exact geometry, size, position and navy-blue gold-trimmed ribbon. Keep number and stars absent. Remove the gray checkerboard backdrop completely. Genuine transparent RGBA PNG with alpha zero everywhere outside the indicator. No checkerboard or background. Use precisely same canvas and coordinates.

### Alpha cleanup

Remove the background. Keep only the existing foreground artwork, isolated on genuine transparency. All gray and white checkerboard background pixels must have zero alpha, including the gaps around and inside the icons. Preserve shapes, positions, sizes and opaque original colors exactly. Export RGBA PNG with real alpha. No checkerboard. No new background. No glow.

## Verification

- `flutter analyze`: no issues.
- `flutter test test/widget_test.dart test/level_unlock_test.dart`: 12 tests passed, including navigation, unlock state, rotation, large text and developer-control visibility.
- Flutter-rendered captures inspected at 390×844, 320×568 and 844×390: no layout exceptions, clipped controls or opaque asset backgrounds. Capture progress is an in-memory fixture with level 1 at 3/3 and developer controls hidden; saved player progress is untouched.
- Original background SHA-256 remains `f3d19e0b2db08fd6d694fd35f9b76356b448f3d9efe8f1978e74ad32b224bd9f`.
- Review captures: `/Users/mati/.codex/visualizations/2026/09/10/01a08d4e-0f91-7c01-83e4-845a09f8eefd/map-phone.png`, `map-compact.png` and `map-landscape.png`.
