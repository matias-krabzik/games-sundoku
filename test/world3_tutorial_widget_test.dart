import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/app.dart';
import 'package:sundoku/controllers/first_experience_controller.dart';
import 'package:sundoku/routes.dart';
import 'package:sundoku/data/repositories/game_repository.dart';
import 'package:sundoku/data/services/save_store.dart';
import 'package:sundoku/data/services/game_feedback.dart';
import 'package:sundoku/domain/tutorial/challenge_lesson.dart';
import 'package:sundoku/screens/challenge_tutorial_screen.dart';
import 'package:sundoku/screens/first_experience_screen.dart';
import 'package:sundoku/theme.dart';
import 'package:sundoku/widgets/challenge_award.dart';
import 'package:sundoku/widgets/sudoku_board.dart';
import 'package:sundoku/widgets/tutorial_lesson_card.dart';
import 'package:sundoku/widgets/tutorial_story.dart';
import 'package:sundoku/widgets/tutorial_presentation.dart';

import 'support/challenge_repository.dart';
import 'data/game_repository_test.dart' show FailingStore;

import 'package:sundoku/screens/map_screen.dart';

import 'tutorial_journey_widget_test.dart' as scene;
import 'widgets/notes_tutorial_demo_test.dart' show frames;

final next = find.byKey(const ValueKey('challenge-lesson-next'));
final board = find.byKey(const ValueKey('challenge-lesson-board'));
final boundaryKey = GlobalKey();
Future<void> show(
  WidgetTester tester,
  GameRepository repo, {
  double scale = 1,
  bool replay = false,
  Future<void> Function()? finished,
}) => tester.pumpWidget(
  RepaintBoundary(
    key: boundaryKey,
    child: MaterialApp(
      theme: buildSunDokuTheme(),
      debugShowCheckedModeBanner: false,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: ChallengeTutorialScreen(
        repository: repo,
        replay: replay,
        onFinished: finished ?? () async {},
      ),
    ),
  ),
);
Future<void> press(WidgetTester tester) async {
  await tester.tap(next);
  await frames(tester, 400);
  expect(tester.takeException(), isNull);
}

Future<void> capture(WidgetTester tester, String name) async {
  final dir = Platform.environment['W3_LESSON_CAPTURE_DIR'];
  if (dir == null) return;
  await tester.runAsync(() async {
    for (final img in tester.widgetList<Image>(find.byType(Image))) {
      await precacheImage(img.image, boundaryKey.currentContext!);
    }
  });
  await tester.pump();
  await tester.runAsync(() async {
    final image =
        await (boundaryKey.currentContext!.findRenderObject()
                as RenderRepaintBoundary)
            .toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('$dir/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUpAll(() async {
    await (FontLoader(
      'Baloo2',
    )..addFont(rootBundle.load('assets/fonts/Baloo2-Variable.ttf'))).load();
  });
  for (final view in {
    'phone': const Size(390, 844),
    'ipad': const Size(834, 1210),
    'ipad-landscape': const Size(1210, 834),
    'desktop': const Size(1440, 900),
  }.entries) {
    testWidgets(
      '${view.key}: four automatic examples, shared format, stable board and explicit finish',
      (tester) async {
        scene.configure(tester);
        tester.view.physicalSize = view.value;
        final repo = await challengeRepository(MemorySaveStore());
        var finished = 0;
        await show(
          tester,
          repo,
          finished: () async {
            finished++;
          },
        );
        await frames(tester, 500);
        final state = tester.state(board);
        final rect = tester.getRect(board);
        for (var step = 0; step < 4; step++) {
          await frames(tester, 500);
          expect(find.text(ChallengeLesson.titles[step]), findsOneWidget);
          expect(tester.state(board), same(state));
          expect(tester.getRect(board), rect);
          expect(tester.widget<SudokuBoard>(board).onSelect, isNull);
          expect(find.byKey(const ValueKey('game-settings')), findsNothing);
          expect(find.byKey(const ValueKey('game-pause')), findsNothing);
          final textRect = tester.getRect(find.byType(TutorialLessonCard));
          expect(textRect.top, greaterThan(rect.bottom));
          expect(textRect.width, lessThanOrEqualTo(470));
          expect(
            find.descendant(
              of: find.byType(TutorialLessonCard),
              matching: find.byType(ChallengeTutorialSummary),
            ),
            findsOneWidget,
          );
          expect(
            find.descendant(
              of: find.byType(TutorialLessonCard),
              matching: find.byType(TutorialStoryDivider),
            ),
            findsOneWidget,
          );
          final summaryRect = tester.getRect(
            find.byType(ChallengeTutorialSummary),
          );
          expect(textRect.contains(summaryRect.topLeft), true);
          expect(textRect.contains(summaryRect.bottomRight), true);
          if (step == 3) {
            expect(
              tester.widget<ChallengeAward>(find.byType(ChallengeAward)).stars,
              1,
            );
          }
          await capture(tester, '${view.key}-step-${step + 1}');
          await press(tester);
        }
        expect(finished, 1);
        expect(repo.challengeTutorialCompleted, true);
        expect(repo.state.sessions, isEmpty);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await repo.close();
      },
    );
  }
  testWidgets(
    'next finishes pending animations; background freezes demo; replay preserves real attempt',
    (tester) async {
      scene.configure(tester, reduced: false);
      final repo = await challengeRepository(MemorySaveStore());
      await repo.startGeneratedLevel(1, worldId: 'world-3');
      final saved = repo.state.toJson();
      await show(tester, repo, replay: true);
      await tester.pump();
      await press(tester);
      expect(find.text(ChallengeLesson.titles[0]), findsOneWidget);
      expect(
        tester
            .state<TutorialPresentationState>(find.byType(TutorialPresentation))
            .demonstration
            .isCompleted,
        true,
      );
      await press(tester);
      expect(find.text(ChallengeLesson.titles[1]), findsOneWidget);
      await frames(tester, 400);
      final presentation = tester.state<TutorialPresentationState>(
        find.byType(TutorialPresentation),
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      final progress = presentation.demonstration.value;
      await frames(tester, 15000);
      expect(presentation.demonstration.value, progress);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await frames(tester, 9000);
      expect(presentation.demonstration.isCompleted, true);
      expect(find.text(ChallengeLesson.titles[1]), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('challenge-lesson-skip')));
      await frames(tester, 500);
      expect(repo.state.toJson(), saved);
      await tester.pumpWidget(const SizedBox());
      await repo.close();
    },
  );
  testWidgets(
    'resize at 200 percent retains board and makes actions reachable',
    (tester) async {
      scene.configure(tester);
      final repo = await challengeRepository(MemorySaveStore());
      await show(tester, repo, scale: 2);
      await frames(tester, 500);
      final state = tester.state(board);
      for (final size in [
        const Size(320, 568),
        const Size(568, 320),
        const Size(844, 390),
        const Size(768, 1024),
        const Size(834, 1210),
        const Size(1210, 834),
        const Size(1440, 900),
      ]) {
        tester.view.physicalSize = size;
        await frames(tester, 500);
        expect(tester.takeException(), isNull, reason: '$size');
        expect(tester.state(board), same(state));
        expect(next.hitTestable(), findsOneWidget);
        expect(
          find.byKey(const ValueKey('challenge-lesson-skip')).hitTestable(),
          findsOneWidget,
        );
      }
      await tester.pumpWidget(const SizedBox());
      await repo.close();
    },
  );
  testWidgets(
    'direct game entry teaches once then shows ready without changing session',
    (tester) async {
      scene.configure(tester);
      final repo = await challengeRepository(MemorySaveStore());
      final session = await repo.startGeneratedLevel(1, worldId: 'world-3');
      await tester.pumpWidget(
        MaterialApp(
          theme: buildSunDokuTheme(),
          home: FirstExperienceScreen(
            repository: repo,
            worldId: 'world-3',
            showDeveloperControls: false,
          ),
        ),
      );
      await frames(tester, 500);
      expect(find.byType(ChallengeTutorialScreen), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('challenge-lesson-skip')));
      await frames(tester, 500);
      expect(find.byType(ChallengeTutorialScreen), findsNothing);
      expect(find.byKey(const ValueKey('challenge-ready')), findsOneWidget);
      expect(repo.state.sessions[session.id]!.elapsedMs, 0);
      expect(repo.state.sessions[session.id]!.lights, 0);
      await tester.pumpWidget(const SizedBox());
      await repo.close();
    },
  );
  testWidgets(
    'authorized deep link opens one introduction; locked link cannot unlock world',
    (tester) async {
      scene.configure(tester);
      final repo = await challengeRepository(MemorySaveStore());
      await tester.pumpWidget(
        SunDokuApp(repository: repo, feedback: const GameFeedback()),
      );
      await frames(tester, 4000);
      final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
      nav.pushNamed(AppRoutes.challengeIntroduction);
      await frames(tester, 3000);
      expect(find.byType(ChallengeTutorialScreen), findsOneWidget);
      expect(repo.state.sessions, isEmpty);
      await tester.tap(find.byKey(const ValueKey('challenge-lesson-skip')));
      await frames(tester, 3000);
      expect(find.byKey(const ValueKey('challenge-ready')), findsOneWidget);
      expect(repo.state.sessions.length, 1);
      await tester.pumpWidget(const SizedBox());
      await repo.close();
      final locked = GameRepository.memory();
      await tester.pumpWidget(
        SunDokuApp(repository: locked, feedback: const GameFeedback()),
      );
      await frames(tester, 4000);
      tester
          .state<NavigatorState>(find.byType(Navigator).first)
          .pushNamed(AppRoutes.challengeIntroduction);
      await frames(tester, 3000);
      expect(find.byType(ChallengeTutorialScreen), findsNothing);
      expect(locked.isWorldUnlocked('world-3'), false);
      await tester.pumpWidget(const SizedBox());
      await locked.close();
    },
  );

  testWidgets(
    'legacy attempt enters without lesson; next challenge is taught',
    (tester) async {
      scene.configure(tester);
      final raw = jsonDecode(
        File('test/fixtures/world3-baseline/world-3-in-progress.json')
            .readAsStringSync(),
      ) as Map<String, dynamic>;
      raw['revision'] = 0;
      final store = MemorySaveStore();
      await store.write(jsonEncode(raw), expectedRevision: -1);
      final repo = await GameRepository.open(
        store,
        enableWorld3Challenges: true,
      );
      final session = repo.state.sessions.values.single;
      expect(repo.needsChallengeTutorial(1), false);
      Future<void> open(int level) => tester.pumpWidget(
        MaterialApp(
          theme: buildSunDokuTheme(),
          home: FirstExperienceScreen(
            key: ValueKey(level),
            repository: repo,
            worldId: 'world-3',
            levelNumber: level,
            showDeveloperControls: false,
          ),
        ),
      );
      await open(1);
      await frames(tester, 800);
      expect(find.byType(ChallengeTutorialScreen), findsNothing);
      await tester.pumpWidget(const SizedBox());
      final puzzle = repo.state.puzzles[session.puzzles.last.puzzleId]!;
      for (var i = 0; i < 81; i++) {
        if (puzzle.initial[i] == null) {
          await repo.setCell(session.id, puzzle.id, i, puzzle.solution[i]);
        }
      }
      await repo.startGeneratedLevel(2, worldId: 'world-3');
      expect(repo.needsChallengeTutorial(2), true);
      await open(2);
      await frames(tester, 500);
      expect(find.byType(ChallengeTutorialScreen), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await repo.close();
    },
  );
  testWidgets('save failure remains visible and retry recognizes lesson', (
    tester,
  ) async {
    scene.configure(tester);
    final store = FailingStore();
    final repo = await challengeRepository(store);
    var finished = 0;
    await show(
      tester,
      repo,
      finished: () async {
        finished++;
      },
    );
    await frames(tester, 500);
    store.failNext = true;
    await tester.tap(find.byKey(const ValueKey('challenge-lesson-skip')));
    await frames(tester, 500);
    expect(
      find.text('No pudimos guardar. Toca de nuevo para reintentar.'),
      findsOneWidget,
    );
    expect(finished, 0);
    expect(repo.challengeTutorialCompleted, false);
    await tester.tap(find.byKey(const ValueKey('challenge-lesson-skip')));
    await frames(tester, 500);
    expect(finished, 1);
    expect(repo.challengeTutorialCompleted, true);
    await tester.pumpWidget(const SizedBox());
    await repo.close();
  });
  testWidgets(
    'screen reader sees final explanation and advances without waiting',
    (tester) async {
      scene.configure(tester, reduced: false);
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(accessibleNavigation: true);
      final semantics = tester.ensureSemantics();
      final repo = await challengeRepository(MemorySaveStore());
      await show(tester, repo);
      await frames(tester, 500);
      expect(find.text(ChallengeLesson.texts[0]), findsOneWidget);
      expect(
        tester
            .state<TutorialPresentationState>(find.byType(TutorialPresentation))
            .demonstration
            .isCompleted,
        true,
      );
      await press(tester);
      expect(find.text(ChallengeLesson.titles[1]), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      semantics.dispose();
      await repo.close();
    },
  );
  for (final entry in ['home', 'summit']) {
    testWidgets(
      '$entry enters once; notebook replay is isolated and fits small landscape',
      (tester) async {
        scene.configure(tester);
        final repo = await challengeRepository(MemorySaveStore());
        await repo.markQuickPlayCelebrated();
        await repo.markWorldGateCelebrated(worldId: 'world-2');
        await repo.saveModule('homeWelcome', {'namePromptShown': true});
        await repo.saveModule(FirstExperienceController.moduleKey, {
          'homeIntroductionShown': true,
        });
        await repo.visitWorld(entry == 'home' ? 'world-3' : 'world-2');
        await tester.pumpWidget(
          SunDokuApp(repository: repo, feedback: const GameFeedback()),
        );
        await frames(tester, 4000);
        await tester.tap(find.byKey(const ValueKey('home-play')));
        await frames(tester, 2000);
        await tester.ensureVisible(
          find.byKey(
            ValueKey('choose-${entry == 'home' ? 'world-3' : 'world-2'}'),
          ),
        );
        await tester.tap(
          find.byKey(
            ValueKey('choose-${entry == 'home' ? 'world-3' : 'world-2'}'),
          ),
        );
        await frames(tester, 4000);
        if (entry == 'summit') {
          await tester.tap(find.byKey(const ValueKey('map-world-gate')));
          await frames(tester, 4000);
        }
        expect(find.byType(ChallengeTutorialScreen), findsOneWidget);
        expect(repo.state.sessions, isEmpty);
        await tester.tap(find.byKey(const ValueKey('challenge-lesson-skip')));
        await frames(tester, 2000);
        expect(find.byKey(const ValueKey('challenge-ready')), findsOneWidget);
        final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
        nav.pop();
        await frames(tester, 2000);
        final saved = repo.state.toJson();
        tester.view.physicalSize = const Size(568, 320);
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        tester.widget<MapScreen>(find.byType(MapScreen)).onViewTutorial!();
        await frames(tester, 500);
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text('Los desafíos'));
        await tester.tap(find.text('Los desafíos'));
        await frames(tester, 1000);
        expect(
          tester
              .widget<ChallengeTutorialScreen>(
                find.byType(ChallengeTutorialScreen),
              )
              .replay,
          true,
        );
        await tester.tap(find.byKey(const ValueKey('challenge-lesson-skip')));
        await frames(tester, 1000);
        expect(repo.state.toJson(), saved);
        await tester.pumpWidget(const SizedBox());
        await repo.close();
      },
    );
  }
  testWidgets(
    'record next finishing first step then advancing with automatic demonstration',
    (tester) async {
      if (Platform.environment['W3_LESSON_CAPTURE_DIR'] == null) return;
      scene.configure(tester, reduced: false);
      final repo = await challengeRepository(MemorySaveStore());
      await show(tester, repo, replay: true);
      await capture(tester, 'motion/frame-000');
      for (var frame = 1; frame < 51; frame++) {
        if (frame == 8 || frame == 16) await tester.tap(next);
        await frames(tester, 200);
        await capture(
          tester,
          'motion/frame-${frame.toString().padLeft(3, '0')}',
        );
      }
      expect(find.text(ChallengeLesson.titles[1]), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await repo.close();
    },
  );
}
