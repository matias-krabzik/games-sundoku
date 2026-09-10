# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Product vision

SunDoku is a children's game built around a Sun mascot ("Sol"). It is structured as
a **visual novel whose story is told between and through Sudoku puzzles** — the
narrative scenes are the connective tissue and the Sudoku matches are the main
interactive beats. Design decisions should favor young players: large touch
targets, forgiving input, minimal reading, generous hints, and expressive
character/animation feedback over dense UI.

## Current state

Early shell only. Flow: animated splash (`lib/screens/splash_screen.dart`) →
home (`home_screen.dart`: logo, Doku, "Jugar", settings, progress card) → **map**
(`map_screen.dart`) when "Jugar" is pressed. The home landscape has a restrained
gyroscope parallax effect. No Sudoku engine or story content yet.

The splash uses the original transparent `sundoku-logo.png` on the new
`splash-background.png`, then advances to home. The map uses the 3:1 panorama
`assets/images/world-1-horizontal.png`, with **10 levels** laid out left to right.
A horizontal `SingleChildScrollView` scales the artwork to fill the screen height.
Buttons use normalized image coordinates in `lib/data/level_node.dart` and match
the home's raised cream/gold controls. Drag horizontally or use the bottom arrows
to explore; arrows center the selected node and stop at levels 1 and 10. Rotation
re-centers that node. Tapping an available node still calls `showToast` with its
number; locked nodes explain that three points are needed in the previous level.
The selected available node has a shimmering gold halo and lens-like glints. When selection
changes, a light trail travels to the new node while the old glow fades out.
`lib/widgets/map_selection_light.dart` paints this in a viewport-sized isolated
layer, follows scrolling, retargets rapid selections, and respects reduced motion.
`LevelProgress` is owned by the app and shared by home and map for the current
session. Level 1 starts available with no score. Three performance points in
level N unlock N+1; points belong to the played level and are never a currency
paid into a locked level. Locked nodes have a dormant appearance and a padlock;
available nodes display their own three score sockets. `recordResult` preserves
the best score. Scoring criteria await the Sudoku screen; no disk persistence yet.

Debug-only DEV controls simulate one point, simulate a full three-point result,
or clear the selected level and later progress for replay. Each simulated point
flies into a socket before its score is recorded. On the third arrival the next
node warms up, loses its padlock, and receives the selection light as the camera
centers it. Reduced motion skips the travel. Leaving the map cancels an in-flight
point; already delivered points survive route changes. The home shows the same
unlocked count and latest available level.

Next: build a very simple Sudoku game screen, without the illustrated world theme,
as requested by the user. No Sudoku screen or engine has been implemented yet.

### Native launch screen

The operating system launch screen is separate from Flutter's `SplashScreen` and
appears before Dart can render. Android launch resources live under
`android/app/src/main/res`: API 31+ uses `values-v31/styles.xml` with the SunDoku
wordmark inside Android's mandatory splash icon safe area; older Android versions
use `drawable/launch_background.xml`. Both use `launch_sky` to bridge into the
Flutter splash. Keep all five density variants of `launch_logo*.png` in sync.

iOS uses `ios/Runner/Base.lproj/LaunchScreen.storyboard`, the generated SunDoku
images in `LaunchImage.imageset`, and the illustrated background in
`LaunchBackground.imageset`. The first Flutter frame keeps the logo visible and
grows it gently so the native-to-Flutter handoff does not flash.

Layout:
- `lib/main.dart` — entry point, runs `SunDokuApp`.
- `lib/app.dart` — `MaterialApp`, theme, named-route table.
- `lib/routes.dart` — route name constants (`AppRoutes`).
- `lib/theme.dart` — "Sol" palette, `sunSkyGradient`, `buildSunDokuTheme()`.
- `lib/data/` — static game data (level node positions).
- `lib/widgets/` — reusable widgets (`SunMark`/`SunLogo`, toast).
- `lib/screens/` — one file per screen.

Navigation is plain `Navigator` + named routes; revisit `go_router` when the story
flow (chapters gating on puzzle completion) takes shape. Settings values are
in-memory — add a persisted settings service before relying on them.

## Architecture direction

There is no code architecture to preserve yet. When building it out, keep two
concerns cleanly separated:

1. **Sudoku engine** — puzzle generation, board model, validation, solver, hint
   logic, difficulty tuning. Pure Dart, no Flutter imports, independently unit
   tested. This is the reusable core.
2. **Story / visual-novel layer** — an ordered sequence of "chapters" or "beats"
   where each beat is either a narrative scene (dialogue, character art,
   background) or a Sudoku challenge that gates progression. Story progress and
   puzzle completion need to be persisted so a child can stop and resume.

The UI shell sits on top of both: a scene player for narrative beats and a Sudoku
board screen for puzzle beats, with transitions/animations tying them together.

Pick and document a state-management and navigation approach before writing screens
(the `flutter-apply-architecture-best-practices` and `flutter-setup-declarative-routing`
skills cover the recommended layered UI/logic/data structure and `go_router`).

## Assets & content

Story text, character art, and puzzle sets will be content-heavy. Plan an
`assets/` layout early and register it in `pubspec.yaml`. Consider keeping story
scripts as structured data (JSON/YAML) rather than hard-coded Dart so chapters can
be authored and tweaked without recompiling. If the story is ever localized, set
up `flutter_localizations` + `intl` (see the `flutter-setup-localization` skill).

## Future animation pass

Plan a dedicated animation pass after the core game loop is in place. It should
cover Doku's idle and reaction animations, subtle environmental motion, button
feedback, and transitions between home, map, story scenes, and puzzles. Keep the
motion playful and calm for young players, and respect reduced-motion settings.
