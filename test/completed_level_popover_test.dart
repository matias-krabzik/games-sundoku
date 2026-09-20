import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/data/level_progress.dart';
import 'package:sundoku/data/level_catalog.dart';
import 'package:sundoku/data/repositories/game_repository.dart';
import 'package:sundoku/domain/models/game_save.dart';
import 'package:sundoku/domain/models/game_session.dart';
import 'package:sundoku/screens/map_screen.dart';
import 'package:sundoku/widgets/completed_level_popover.dart';
import 'package:sundoku/widgets/map_level_button.dart';
import 'package:sundoku/widgets/map_art.dart';
import 'package:sundoku/widgets/ui_surface_art.dart';

Future<void> captureSummary(
  WidgetTester tester,
  GlobalKey key,
  String name,
) async {
  final directory = Platform.environment['SUMMARY_CAPTURE_DIR'];
  if (directory == null) return;
  await tester.runAsync(() async {
    for (final asset in {
      for (final surface in UiSurface.values) surface.spec.asset,
      'assets/images/world-1-horizontal.png',
      'assets/images/map/icons.png',
      'assets/images/home/icons.png',
      'assets/images/map/marker-gold.png',
      'assets/images/map/marker-ivory.png',
      'assets/images/map/score-sun.png',
    }) {
      await precacheImage(AssetImage(asset), key.currentContext!);
    }
  });
  await settle(tester);
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    await Directory(directory).create(recursive: true);
    await File('$directory/$name.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
  });
}

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

PuzzleProgress round({
  required String id,
  required PlayStatus status,
  required int points,
  required int elapsedMs,
}) => PuzzleProgress(
  puzzleId: id,
  cells: const [],
  status: status,
  points: points,
  elapsedMs: elapsedMs,
  completedAt: status == PlayStatus.completed ? DateTime.utc(2026, 1, 1) : null,
);

GameSession resumableSession() => GameSession(
  id: 'attempt-3',
  playerId: 'player',
  levelId: 'map-1-level-3',
  puzzles: [
    round(
      id: 'round-1',
      status: PlayStatus.completed,
      points: 135,
      elapsedMs: 36000,
    ),
    round(
      id: 'round-2',
      status: PlayStatus.paused,
      points: 53,
      elapsedMs: 7000,
    ),
    round(id: 'round-3', status: PlayStatus.pending, points: 0, elapsedMs: 0),
  ],
  status: PlayStatus.paused,
  startedAt: DateTime.utc(2026, 1, 1),
  updatedAt: DateTime.utc(2026, 1, 1),
);

Widget summary({
  required bool complete,
  required VoidCallback onContinue,
  required VoidCallback onOk,
  bool practice = false,
}) => MaterialApp(
  home: Scaffold(
    backgroundColor: const Color(0xFF55B8F3),
    body: SafeArea(
      minimum: const EdgeInsets.all(12),
      child: Center(
        child: LevelSummaryCard(
          level: practice ? 1 : 3,
          lights: complete ? 3 : 1,
          session: complete ? null : resumableSession(),
          record: complete
              ? LevelRecord(
                  bestLights: 3,
                  bestPoints: 750,
                  bestElapsedMs: 130000,
                )
              : LevelRecord(bestLights: 1),
          onContinue: onContinue,
          onOk: onOk,
        ),
      ),
    ),
  ),
);

Widget newLevelSummary({
  required VoidCallback onPlay,
  required VoidCallback onOk,
  int level = 2,
}) => MaterialApp(
  home: Scaffold(
    backgroundColor: const Color(0xFF55B8F3),
    body: SafeArea(
      minimum: const EdgeInsets.all(12),
      child: Center(
        child: LevelSummaryCard(
          level: level,
          lights: 0,
          session: null,
          record: LevelRecord(),
          onContinue: onPlay,
          onOk: onOk,
        ),
      ),
    ),
  ),
);

void main() {
  setUpAll(() async {
    final font = FontLoader('Baloo2')
      ..addFont(rootBundle.load('assets/fonts/Baloo2-Variable.ttf'));
    await font.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });

  testWidgets('in-progress summary shows saved rounds and continues', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var continuations = 0;

    await tester.pumpWidget(
      summary(complete: false, onContinue: () => continuations++, onOk: () {}),
    );
    await settle(tester);

    expect(find.text('VALLE DEL SOL'), findsOneWidget);
    expect(find.text('Nivel 3'), findsOneWidget);
    expect(find.text('¡Vamos por las 3 estrellas!'), findsOneWidget);
    expect(find.text('1 de 3 rondas completas'), findsOneWidget);
    for (var index = 1; index <= 3; index++) {
      final card = find.byKey(ValueKey('level-summary-round-$index'));
      expect(
        find.descendant(of: card, matching: find.text('Ronda $index')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<MapIcon>(
              find.descendant(of: card, matching: find.byType(MapIcon)),
            )
            .glyph,
        index == 1 ? MapGlyph.goldStar : MapGlyph.emptyStar,
      );
    }
    expect(find.text('Completada'), findsOneWidget);
    expect(find.text('En juego'), findsOneWidget);
    expect(find.text('Por jugar'), findsOneWidget);
    expect(find.text('135 puntos · 00:36'), findsOneWidget);
    expect(find.text('53 puntos · 00:07'), findsOneWidget);
    expect(find.text('Puntos: 188'), findsOneWidget);
    expect(find.text('Tiempo: 00:43'), findsOneWidget);
    expect(find.text('Volver al mapa'), findsNothing);
    final ok = find.byKey(const ValueKey('level-summary-ok'));
    expect(ok.hitTestable(), findsOneWidget);
    expect(find.byIcon(Icons.close), findsNothing);
    final continueButton = find.byKey(const ValueKey('level-summary-continue'));
    expect(continueButton.hitTestable(), findsOneWidget);
    expect(tester.getRect(continueButton).width, lessThan(250));
    expect(
      tester.getRect(continueButton).center.dy,
      closeTo(tester.getRect(ok).center.dy, 1),
    );
    expect(
      tester
          .getRect(find.byKey(const ValueKey('level-summary-ok-frame')))
          .height,
      greaterThan(tester.getRect(ok).height),
    );
    await tester.tap(continueButton);
    await settle(tester);
    expect(continuations, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('new level summary only offers play and Ok', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var plays = 0;
    var closes = 0;

    await tester.pumpWidget(
      newLevelSummary(onPlay: () => plays++, onOk: () => closes++),
    );
    await settle(tester);

    expect(find.text('En progreso'), findsOneWidget);
    expect(find.text('0 de 3 rondas completadas'), findsNothing);
    expect(find.text('Tiempo'), findsNothing);
    expect(find.text('Todo está listo para comenzar.'), findsNothing);
    expect(
      find.byKey(const ValueKey('level-summary-play')).hitTestable(),
      findsOneWidget,
    );
    expect(find.text('Jugar'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('level-summary-ok')).hitTestable(),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('level-summary-play')));
    await settle(tester);
    expect(plays, 1);
    await tester.tap(find.byKey(const ValueKey('level-summary-ok')));
    await settle(tester);
    expect(closes, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('completed summary uses a small cream Ok at bottom right', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var closes = 0;

    await tester.pumpWidget(
      summary(complete: true, onContinue: () {}, onOk: () => closes++),
    );
    await settle(tester);

    expect(find.text('Nivel 3'), findsOneWidget);
    expect(find.text('¡Completado!'), findsOneWidget);
    expect(find.text('3 de 3 rondas completas'), findsOneWidget);
    expect(find.text('Puntos: 750'), findsOneWidget);
    expect(find.text('Tiempo: 02:10'), findsOneWidget);
    expect(find.text('¡Ganaste las 3 estrellas!'), findsOneWidget);
    expect(find.byKey(const ValueKey('level-summary-continue')), findsNothing);
    expect(find.byIcon(Icons.close), findsNothing);
    final card = tester.getRect(find.byKey(const ValueKey('level-summary')));
    final ok = find.byKey(const ValueKey('level-summary-ok'));
    expect(ok.hitTestable(), findsOneWidget);
    expect(tester.getRect(ok).center.dx, greaterThan(card.center.dx));
    expect(tester.getRect(ok).width, lessThan(100));
    await tester.tap(ok);
    await settle(tester);
    expect(closes, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('completed practice keeps its message and replay action', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var replays = 0;
    var closes = 0;

    await tester.pumpWidget(
      summary(
        complete: true,
        practice: true,
        onContinue: () => replays++,
        onOk: () => closes++,
      ),
    );
    await settle(tester);

    expect(find.text('¡Lo hiciste muy bien!'), findsOneWidget);
    expect(find.text('VALLE DEL SOL'), findsOneWidget);
    expect(find.text('Nivel 1'), findsOneWidget);
    expect(find.text('Práctica completada'), findsNothing);
    expect(find.text('3 de 3 rondas completas'), findsNothing);
    expect(find.textContaining('Puntos:'), findsNothing);
    expect(find.textContaining('Tiempo:'), findsNothing);
    expect(find.byKey(const ValueKey('level-summary-round-1')), findsNothing);
    expect(
      find.textContaining('Completaste las 3 rondas de práctica.'),
      findsOneWidget,
    );
    final replay = find.byKey(const ValueKey('level-replay'));
    final ok = find.byKey(const ValueKey('level-summary-ok'));
    expect(replay.hitTestable(), findsOneWidget);
    expect(ok.hitTestable(), findsOneWidget);
    expect(tester.getRect(replay).right, lessThan(tester.getRect(ok).left));
    expect(
      tester.getRect(replay).center.dy,
      closeTo(tester.getRect(ok).center.dy, 1),
    );
    final replayText = tester.widget<Text>(
      find.descendant(of: replay, matching: find.text('Volver a jugar')),
    );
    final okText = tester.widget<Text>(
      find.descendant(of: ok, matching: find.text('Ok')),
    );
    expect(replayText.style!.fontSize, okText.style!.fontSize);
    expect(replayText.style!.fontSize, 20);
    expect(
      tester.getRect(find.byKey(const ValueKey('level-summary'))).height,
      lessThanOrEqualTo(500),
    );
    await tester.tap(replay);
    await settle(tester);
    expect(replays, 1);
    expect(closes, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('summary stays usable in a short landscape window', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(844, 390);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      summary(complete: false, onContinue: () {}, onOk: () {}),
    );
    await settle(tester);

    expect(
      find.byKey(const ValueKey('level-summary-continue')).hitTestable(),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('level-summary-ok')).hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('practice summary responds to small screens and enlarged text', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    for (final size in [const Size(320, 568), const Size(844, 390)]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        summary(complete: true, practice: true, onContinue: () {}, onOk: () {}),
      );
      await settle(tester);

      final card = tester.getRect(find.byKey(const ValueKey('level-summary')));
      expect(card.left, greaterThanOrEqualTo(0));
      expect(card.top, greaterThanOrEqualTo(0));
      expect(card.right, lessThanOrEqualTo(size.width));
      expect(card.bottom, lessThanOrEqualTo(size.height));
      expect(
        find.byKey(const ValueKey('level-replay')).hitTestable(),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('level-summary-ok')).hitTestable(),
        findsOneWidget,
      );
      final replay = find.byKey(const ValueKey('level-replay'));
      final beforeScroll = tester.getRect(replay);
      final viewport = tester.getRect(
        find.byKey(const ValueKey('level-summary-scroll')),
      );
      expect(viewport.bottom, lessThanOrEqualTo(beforeScroll.top));
      await tester.ensureVisible(
        find.textContaining('Puedes volver a jugar cuando quieras.'),
      );
      await settle(tester);
      expect(tester.getRect(replay), beforeScroll);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('rounds scroll without moving or covering Continue and Ok', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    var continuations = 0;
    var closes = 0;

    for (final size in [const Size(320, 568), const Size(844, 390)]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        summary(
          complete: false,
          onContinue: () => continuations++,
          onOk: () => closes++,
        ),
      );
      await settle(tester);
      final action = find.byKey(const ValueKey('level-summary-continue'));
      final ok = find.byKey(const ValueKey('level-summary-ok'));
      final actionRect = tester.getRect(action);
      final viewport = tester.getRect(
        find.byKey(const ValueKey('level-summary-scroll')),
      );
      expect(viewport.bottom, lessThanOrEqualTo(actionRect.top));
      expect(actionRect.right, lessThan(tester.getRect(ok).left));
      expect(actionRect.center.dy, closeTo(tester.getRect(ok).center.dy, 1));
      expect(action.hitTestable(), findsOneWidget);
      expect(ok.hitTestable(), findsOneWidget);

      await tester.ensureVisible(find.text('Tiempo: 00:43'));
      await settle(tester);
      expect(find.text('Tiempo: 00:43').hitTestable(), findsOneWidget);
      expect(tester.getRect(action), actionRect);
      await tester.tap(action);
      await settle(tester);
      await tester.tap(ok);
      await settle(tester);
      expect(tester.takeException(), isNull);
    }
    expect(continuations, 2);
    expect(closes, 2);
  });

  testWidgets('completed level 1 replays practice from its special summary', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final progress = LevelProgress();
    addTearDown(progress.dispose);
    await progress.recordResult(1, 3);
    var openings = 0;
    var replays = 0;
    final captureKey = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            RepaintBoundary(key: captureKey, child: child!),
        home: MapScreen(
          progress: progress,
          showDeveloperControls: false,
          onOpenIntroduction: () => openings++,
          onReplayIntroduction: () async => replays++,
        ),
      ),
    );
    await settle(tester);
    tester
        .widgetList<MapLevelButton>(find.byType(MapLevelButton))
        .singleWhere((button) => button.level == 1)
        .onTap();
    await settle(tester);
    expect(find.text('¡Lo hiciste muy bien!'), findsOneWidget);
    for (final (name, size) in [
      ('ipad', const Size(834, 1210)),
      ('mobile', const Size(390, 844)),
    ]) {
      tester.view.physicalSize = size;
      await settle(tester);
      await captureSummary(tester, captureKey, 'practice-summary-$name');
      expect(
        find.byKey(const ValueKey('level-replay')).hitTestable(),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('level-summary-ok')).hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    }
    await tester.tap(find.byKey(const ValueKey('level-replay')));
    await settle(tester);

    expect(openings, 0);
    expect(replays, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'new and unfinished practice omit round results and keep their action',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var plays = 0;
      var continuations = 0;
      for (final started in [false, true]) {
        await tester.pumpWidget(
          started
              ? summary(
                  complete: false,
                  practice: true,
                  onContinue: () => continuations++,
                  onOk: () {},
                )
              : newLevelSummary(level: 1, onPlay: () => plays++, onOk: () {}),
        );
        await settle(tester);
        expect(find.text('VALLE DEL SOL'), findsOneWidget);
        expect(find.text('Nivel 1'), findsOneWidget);
        expect(find.textContaining('rondas completas'), findsNothing);
        expect(find.textContaining('Puntos:'), findsNothing);
        expect(find.textContaining('Tiempo:'), findsNothing);
        expect(
          find.byKey(const ValueKey('level-summary-round-1')),
          findsNothing,
        );
        final action = find.byKey(
          ValueKey(started ? 'level-summary-continue' : 'level-summary-play'),
        );
        expect(action.hitTestable(), findsOneWidget);
        await tester.tap(action);
        await settle(tester);
        expect(tester.takeException(), isNull);
      }
      expect(plays, 1);
      expect(continuations, 1);
    },
  );

  for (final (name, size) in [
    ('ipad', const Size(834, 1210)),
    ('mobile', const Size(390, 844)),
  ]) {
    testWidgets('map summary keeps saved progress and both actions on $name', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = GameRepository.memory();
      await repository.recordDebugLights(mapLevelId(1), 3);
      final session = await repository.startGeneratedLevel(2);
      await repository.addElapsed(
        session.id,
        session.puzzles.first.puzzleId,
        2000,
      );
      final progress = LevelProgress(repository: repository);
      final captureKey = GlobalKey();
      final opened = <int>[];
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) =>
              RepaintBoundary(key: captureKey, child: child!),
          home: MapScreen(
            progress: progress,
            showDeveloperControls: false,
            onOpenLevel: (level) async => opened.add(level),
          ),
        ),
      );
      await settle(tester);
      void openSummary() => tester
          .widgetList<MapLevelButton>(find.byType(MapLevelButton))
          .singleWhere((button) => button.level == 2)
          .onTap();
      openSummary();
      await settle(tester);
      expect(find.text('0 de 3 rondas completas'), findsOneWidget);
      expect(find.text('0 puntos · 00:02'), findsOneWidget);
      expect(find.text('Por jugar'), findsNWidgets(2));
      expect(find.text('Ronda 3').hitTestable(), findsOneWidget);
      expect(find.text('Volver al mapa'), findsNothing);
      await captureSummary(tester, captureKey, 'level-summary-$name');

      final ok = find.byKey(const ValueKey('level-summary-ok'));
      final action = find.byKey(const ValueKey('level-summary-continue'));
      expect(action.hitTestable(), findsOneWidget);
      expect(ok.hitTestable(), findsOneWidget);
      expect(
        tester.getRect(action).center.dy,
        closeTo(tester.getRect(ok).center.dy, 1),
      );
      await tester.tap(ok);
      await settle(tester);
      expect(find.byKey(const ValueKey('level-summary')), findsNothing);
      expect(opened, isEmpty);
      expect(progress.sessionFor(2)!.elapsedMs, 2000);
      expect(progress.sessionFor(2)!.points, 0);

      openSummary();
      await settle(tester);
      await tester.tap(action);
      await settle(tester);
      expect(opened, [2]);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await settle(tester);
      progress.dispose();
      await repository.close();
    });
  }
}
