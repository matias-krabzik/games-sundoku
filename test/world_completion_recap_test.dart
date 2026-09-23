import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/data/repositories/game_repository.dart';
import 'package:sundoku/routes.dart';
import 'package:sundoku/screens/home_screen.dart';
import 'package:sundoku/widgets/tutorial_story.dart';

import 'tutorial_journey_widget_test.dart' as scene;

void main() {
  setUpAll(() async {
    await (FontLoader(
      'Baloo2',
    )..addFont(rootBundle.load('assets/fonts/Baloo2-Variable.ttf'))).load();
  });

  for (final name in [null, 'Luna', 'Jugador']) {
    testWidgets('world recap uses only an explicitly chosen name: $name', (
      tester,
    ) async {
      scene.configure(tester);
      final repo = GameRepository.memory();
      addTearDown(repo.dispose);
      if (name != null) await repo.setPlayerName(name);
      await repo.completeDebugWorldExceptLastPuzzle();
      await repo.completeDebugLevel(10);
      await scene.show(
        tester,
        repo,
        withParentRoute: true,
        levelNumber: 10,
        textScale: name == 'Luna' ? 1 : 2,
        routes: {AppRoutes.home: (_) => const HomeScreen()},
      );
      await scene.tap(tester, find.text('Abrir tutorial'));
      await scene.waitForAction(tester, scene.next);
      expect(find.text('Ver lo aprendido'), findsOneWidget);
      await scene.tap(tester, scene.next);
      final recap = find.byKey(const ValueKey('world-completion-recap'));
      expect(recap, findsOneWidget);
      if (name == 'Luna') await scene.capture(tester, 'world-completion-recap');
      final story = tester.widget<TutorialStory>(
        find.byKey(const ValueKey('world-recap-story')),
      );
      final text = story.lines.join(' ');
      expect(
        text,
        contains(name == null ? '¡Felicitaciones!' : '¡Felicitaciones, $name!'),
      );
      if (name == null) expect(text, isNot(contains('Jugador')));
      expect(text, contains('cada fila'));
      expect(text, contains('cada columna'));
      expect(text, contains('bloque de 3×3'));
      expect(text, contains('del 1 al 9 sin repetir'));
      expect(text, contains('¡No se cambian!'));
      expect(story.tip, contains('¡Desbloqueaste Partida rápida!'));
      expect(find.text('Ir al inicio'), findsOneWidget);
      expect(find.text('Volver al mapa'), findsOneWidget);
      for (final size in [
        const Size(320, 568),
        const Size(844, 390),
        const Size(1024, 1366),
      ]) {
        tester.view.physicalSize = size;
        await scene.settle(tester);
        expect(tester.takeException(), isNull);
        expect(
          find.byKey(const ValueKey('world-recap-done')).hitTestable(),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('world-recap-map')).hitTestable(),
          findsOneWidget,
        );
      }
      await scene.tap(tester, find.byKey(const ValueKey('world-recap-done')));
      expect(recap, findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Abrir tutorial'), findsNothing);
      expect(
        Navigator.of(tester.element(find.byType(HomeScreen))).canPop(),
        isFalse,
      );
      await tester.pumpWidget(const SizedBox());
      await scene.settle(tester);
    });
  }
}
