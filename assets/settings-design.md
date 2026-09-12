# Settings modal

Implemented from the approved SunDoku settings concept. Language selection is omitted.

## Reusable art

- `images/settings/icons.png`: RGBA 4 × 2 atlas of navy gear, music, sound, vibration, info, check, close and chevron icons. `SettingsIcon` clips each cell independently at runtime, keeping the extracted artwork reusable.
- Panel, setting cards, gold confirmation button and circular close button now reuse the shared [nine-patch surfaces](ui-surfaces.md). Their labels and icons remain separate widgets.
- `images/settings/done-button.png`: historical extraction retained as a reference, no longer used or bundled. Confirmation actions reuse the home gold button.
- Toggle tracks and knobs remain resolution-independent Flutter drawing primitives.
- `fonts/Baloo2-Variable.ttf`: Baloo 2, locally bundled with `OFL-Baloo2.txt`. A raster concept cannot provide an installable font; Baloo 2 is the matching rounded typeface used for this implementation.
  Source: https://github.com/google/fonts/tree/main/ofl/baloo2

The original icon atlas and historical button were derived using the built-in image generation tool, then copied into the project. Real alpha channels were verified before use. No simulated checkerboard is included in the shipped assets.

### Icon extraction prompt

Extract and faithfully recreate the NAVY ICONS from this SunDoku settings UI reference as a production transparent PNG sprite atlas. Output exactly 2048x1024, a perfectly regular 4-column by 2-row invisible grid, eight equal 512x512 cells. Truly transparent alpha background, NO white/cream backdrop, NO checkerboard baked in, NO labels, NO grid lines, no shadows beyond tiny icon relief. Each icon is centered exactly in its own cell, maximum icon dimension 360 pixels, preserving substantial equal transparent padding. All icons match the reference's thick rounded dark navy #082A62, subtle blue bevel and tactile soft 3D highlights. Reading order left to right: TOP ROW gear with eight rounded teeth and transparent circular hole; single musical eighth-note; speaker with two rounded sound-wave arcs; phone with rounded rectangular outline and two zigzag vibration marks. BOTTOM ROW circled lowercase i info symbol; large thick rounded checkmark; thick rounded X close mark; thick rounded right chevron. Match the supplied reference icons very faithfully, extracted isolated assets. The gold buttons and cream cards must NOT be included, only eight clean navy icons on transparency. Orthographic front view, consistent crisp visual weight. Perfect regular grid layout is essential for slicing in game code.

Final alpha cleanup prompt:

Remove the entire background from this eight-icon atlas. Return a TRUE transparent PNG with real alpha channel. Every gray and white checkerboard square and all cloudy artifacts must be removed, not preserved and not replaced with another checkerboard. Only preserve the eight navy-blue icons. Holes inside gear, musical notes, phone, and information icon must be genuinely transparent as well. Preserve the identical 4-column 2-row composition, locations, navy color, sizes, crisp edges and icon shapes. This is a background-removal operation only. Actual transparent background alpha, no simulated transparency.

### Button extraction prompt

Extract the golden yellow pill-shaped 'Listo' button from the provided SunDoku settings reference as a clean production game UI asset. Remove the text and checkmark, leave its face entirely blank gold. Return only ONE horizontally wide rounded pill button matching its exact glossy juicy rounded yellow-gold 3D style, warm orange lower lip, narrow bright pale yellow edge rim, soft top-left specular highlights, smooth yellow face and softly raised edges. Straight-on orthographic view, no perspective. Width-to-height of the button approximately 4.8:1. Center it on a landscape canvas approximately 3:1 with transparent margins above and below. REAL alpha channel transparent PNG, not a white background or a checkerboard pattern. No text, no icon, no frame, no other UI. Preserve the reference button's material, silhouette and warm color. Include just a small soft shadow immediately underneath the button, no large cast shadow. The result will be resized as the functional animated confirmation button.

Final alpha cleanup prompt:

Remove the background. Keep only the gold button, isolated on genuine transparency. All gray background pixels must have zero alpha. Export RGBA PNG.

## Interaction and sound

- `JuicyPress`: immediate pointer-down squash, 85 ms compression and 150 ms spring release. The action happens after the release, with duplicate activations blocked. Canceled gestures do not activate. Keyboard activation and screen-reader semantics are supported.
- Settings route: 420 ms entrance with a small overshoot, 210 ms exit; honors reduced-motion preferences.
- Toggles: 260 ms spring, visible on/off position and state semantics. The repository persists sound, music and vibration together with the game's existing save. Failed writes restore the previous state and show a retry message.
- Original local marimba loop and UI pop are generated by `tool/generate_ui_audio.py`; no third-party audio samples. `audio/sunny-loop.wav` loops at low volume, `audio/soft-tap.wav` handles button feedback. Music starts after the first user interaction to respect browser autoplay, pauses in the background, and follows the saved setting on resume. Haptics depend on device support.

## Verification

Interactive preview declarations: `lib/previews/settings_preview.dart` (390 × 844 and 320 × 568).

Behavior tests: `test/settings_modal_test.dart`; existing home/navigation tests: `test/widget_test.dart`.
