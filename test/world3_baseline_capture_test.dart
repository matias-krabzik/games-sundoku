import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/controllers/first_experience_controller.dart';
import 'package:sundoku/controllers/notes_tutorial_controller.dart';
import 'package:sundoku/data/level_catalog.dart';
import 'package:sundoku/data/services/save_codec.dart';
import 'package:sundoku/screens/first_experience_screen.dart';
import 'package:sundoku/screens/notes_tutorial_screen.dart';
import 'package:sundoku/theme.dart';
import 'package:sundoku/widgets/sudoku_board.dart';
import 'package:sundoku/widgets/tutorial_journey.dart';
import 'package:sundoku/widgets/ui_surface_art.dart';

import 'support/world3_baseline.dart';
import 'tutorial_journey_widget_test.dart' as scene;

void main() {
  final directory = Platform.environment['W3_BASELINE_CAPTURE_DIR'];
  if (directory == null) return;

  setUpAll(() async {
    await (FontLoader(
      'Baloo2',
    )..addFont(rootBundle.load('assets/fonts/Baloo2-Variable.ttf'))).load();
  });

  const views = {
    'phone': Size(390, 844),
    'ipad': Size(834, 1210),
    'desktop': Size(1440, 900),
  };
  for (final view in views.entries) {
    for (final screen in [
      'world-1-game',
      'world-2-game',
      'world-3-game',
      'rules',
      'notes',
      'round-result',
      'level-result',
    ]) {
      testWidgets('reference ${view.key} $screen', (tester) async {
        scene.configure(tester);
        tester.view.physicalSize = view.value;
        final isGame = screen.endsWith('-game');
        final worldId = isGame ? screen.substring(0, 7) : 'world-3';
        final worldNumber = isGame ? int.parse(worldId.split('-').last) : 1;
        final level = isGame && worldId != 'world-3' ? 2 : 1;
        final fixture = screen == 'round-result'
            ? 'world-3-one-star'
            : screen == 'level-result'
            ? 'world-3-level-complete'
            : null;
        final save = fixture == null
            ? baselineSave(
                completedWorlds: isGame
                    ? worldNumber - 1
                    : screen == 'notes'
                    ? 1
                    : 0,
              )
            : const SaveCodec().decode(
                File('test/fixtures/world3-baseline/$fixture.json')
                    .readAsStringSync(),
              );
        final repo = await openBaselineRepository(save);
        final boundaryKey = GlobalKey();
        if (isGame) {
          if (worldId == 'world-2') {
            await repo.saveModule(NotesLesson.key, {
              'step': 7,
              'completed': true,
            });
          }
          if (level == 2) {
            await repo.recordDebugLights(mapLevelId(1, worldId: worldId), 3);
          }
          await repo.startGeneratedLevel(level, worldId: worldId);
        } else if (screen == 'rules') {
          await repo.saveModule(FirstExperienceController.moduleKey, {
            'step': 'rowRule',
            'cells': scene.center,
          });
        } else if (screen == 'notes') {
          await repo.saveModule(NotesLesson.key, {'step': 2});
        }
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundaryKey,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: buildSunDokuTheme(),
              home: screen == 'notes'
                  ? NotesTutorialScreen(
                      repository: repo,
                      onFinished: () async {},
                    )
                  : FirstExperienceScreen(
                      repository: repo,
                      worldId: screen == 'rules' ? 'world-1' : worldId,
                      levelNumber: level,
                      showDeveloperControls: false,
                    ),
            ),
          ),
        );
        await scene.settle(tester);
        await tester.runAsync(() async {
          final context = boundaryKey.currentContext!;
          final providers = <ImageProvider>{
            for (final surface in UiSurface.values)
              AssetImage(surface.spec.asset),
            for (final image in tester.widgetList<Image>(find.byType(Image)))
              image.image,
            const AssetImage('assets/images/home-background.png'),
            const AssetImage('assets/images/tutorial/notes-background.png'),
          };
          for (final provider in providers) {
            await precacheImage(provider, context).timeout(
              const Duration(seconds: 10),
              onTimeout: () =>
                  throw StateError('Image did not load: $provider'),
            );
          }
        });
        await scene.settle(tester);
        expect(tester.takeException(), isNull);
        if (isGame) {
          expect(find.byType(SudokuBoard), findsOneWidget);
          final number = tester.getRect(
            find.byKey(const ValueKey('intro-number-1')),
          );
          expect(number.top, greaterThan(tester.getRect(scene.board).bottom));
          expect(
            find.byKey(const ValueKey('game-unlimited-lives')),
            findsOneWidget,
          );
        }
        await tester.runAsync(() async {
          final boundary =
              boundaryKey.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          image.dispose();
          await Directory(directory).create(recursive: true);
          await File('$directory/${view.key}-$screen.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
        });
        if (isGame) {
          final flow = tester
              .widget<TutorialJourney>(find.byType(TutorialJourney))
              .flow;
          final target = flow.boardValues.indexOf(null);
          flow.selectGameCell(target);
          await flow.placeGameNumber(flow.puzzleDefinition!.solution[target]);
          expect(
            flow.boardValues[target],
            flow.puzzleDefinition!.solution[target],
          );
        }
        await tester.pumpWidget(const SizedBox());
        await scene.settle(tester);
        await repo.close();
      });
    }
  }
}
