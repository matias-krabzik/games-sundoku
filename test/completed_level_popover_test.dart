import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/data/level_progress.dart';
import 'package:sundoku/domain/models/game_save.dart';
import 'package:sundoku/domain/models/game_session.dart';
import 'package:sundoku/screens/map_screen.dart';
import 'package:sundoku/widgets/completed_level_popover.dart';
import 'package:sundoku/widgets/map_level_button.dart';

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

void main() {
  setUpAll(() async {
    final font = FontLoader('Baloo2')
      ..addFont(rootBundle.load('assets/fonts/Baloo2-Variable.ttf'));
    await font.load();
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

    expect(find.text('MUNDO 1'), findsOneWidget);
    expect(find.text('Valle del Sol'), findsOneWidget);
    expect(find.text('Nivel 3'), findsOneWidget);
    expect(find.text('En progreso'), findsOneWidget);
    expect(find.text('1 de 3 rondas completadas'), findsOneWidget);
    expect(find.text('1  ✓ Completada'), findsOneWidget);
    expect(find.text('2  En curso'), findsOneWidget);
    expect(find.text('3  Pendiente'), findsOneWidget);
    expect(find.text('188'), findsOneWidget);
    expect(find.text('00:43'), findsOneWidget);
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
    expect(find.text('3 de 3 rondas completadas'), findsOneWidget);
    expect(find.text('750'), findsOneWidget);
    expect(find.text('02:10'), findsOneWidget);
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

    expect(find.text('Nivel 1'), findsOneWidget);
    expect(find.text('¡Lo hiciste muy bien!'), findsOneWidget);
    expect(find.text('Práctica completada'), findsOneWidget);
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
      tester
              .getRect(
                find.textContaining('Completaste las 3 rondas de práctica.'),
              )
              .top -
          tester.getRect(find.text('Práctica completada')).bottom,
      lessThan(40),
    );
    expect(
      tester.getRect(find.byKey(const ValueKey('level-summary'))).height,
      lessThanOrEqualTo(540),
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
      expect(tester.takeException(), isNull);
    }
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

    await tester.pumpWidget(
      MaterialApp(
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
    await tester.tap(find.byKey(const ValueKey('level-replay')));
    await settle(tester);

    expect(openings, 0);
    expect(replays, 1);
    expect(tester.takeException(), isNull);
  });
}
