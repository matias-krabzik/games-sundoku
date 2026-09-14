import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sundoku/app.dart';
import 'package:sundoku/data/repositories/game_repository.dart';
import 'package:sundoku/data/services/game_feedback.dart';
import 'package:sundoku/data/services/save_store.dart';
import 'package:sundoku/screens/profile_screen.dart';

class _FailingStore extends MemorySaveStore {
  bool fail = false;

  @override
  Future<void> write(String data, {required int expectedRevision}) async {
    if (fail) throw StateError('Disk write failed');
    await super.write(data, expectedRevision: expectedRevision);
  }
}

final _profileButton = find.byKey(const ValueKey('home-profile'));
final _nameField = find.byKey(const ValueKey('profile-name'));
final _saveButton = find.byKey(const ValueKey('profile-save'));

Future<void> _boot(
  WidgetTester tester,
  GameRepository repository, {
  bool disposeRepository = true,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    if (disposeRepository) repository.dispose();
  });
  await tester.pumpWidget(
    SunDokuApp(repository: repository, feedback: const GameFeedback()),
  );
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpAndSettle();
}

Finder _profileName(String name) =>
    find.descendant(of: _profileButton, matching: find.text(name));

Future<void> _openProfile(WidgetTester tester) async {
  if (find.byType(ProfileScreen).evaluate().isNotEmpty) return;
  await tester.tap(_profileButton);
  await tester.pumpAndSettle();
  expect(find.byType(ProfileScreen), findsOneWidget);
}

Future<void> _save(WidgetTester tester) async {
  await tester.ensureVisible(_saveButton);
  await tester.tap(_saveButton);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'first home automatically asks for a name and hides level status',
    (tester) async {
      final repository = GameRepository.memory();
      await _boot(tester, repository);

      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('home-game-status')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('profile-close')));
      await tester.pumpAndSettle();
      expect(_profileButton.hitTestable(), findsOneWidget);
      expect(_profileName('Jugador'), findsOneWidget);
      await _openProfile(tester);
      expect(tester.widget<TextField>(_nameField).controller!.text, isEmpty);
      expect(find.text('Tu perfil'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'dismissed welcome stays dismissed after restart and status follows Play',
    (tester) async {
      final store = MemorySaveStore();
      final repository = await GameRepository.open(store);
      await _boot(tester, repository, disposeRepository: false);
      await tester.tap(find.byKey(const ValueKey('profile-close')));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      await repository.close();
      final reopened = await GameRepository.open(store);
      await _boot(tester, reopened);
      expect(find.byType(ProfileScreen), findsNothing);
      expect(find.byKey(const ValueKey('home-game-status')), findsNothing);
      expect(reopened.state.player.nameChosen, isFalse);
      await tester.tap(find.byKey(const ValueKey('home-play')));
      await tester.pumpAndSettle();
      final navigator = tester.state<NavigatorState>(
        find.byType(Navigator).first,
      );
      navigator.popUntil((route) => route.isFirst);
      await tester.pumpAndSettle();
      expect(find.byType(ProfileScreen), findsNothing);
      expect(find.byKey(const ValueKey('home-game-status')), findsOneWidget);
    },
  );

  testWidgets('chosen player name renders and updates reactively on home', (
    tester,
  ) async {
    final repository = GameRepository.memory();
    await repository.setPlayerName('Martina');
    await _boot(tester, repository);

    expect(_profileName('Martina'), findsOneWidget);
    await repository.setPlayerName('Nicolás');
    await tester.pumpAndSettle();
    expect(_profileName('Nicolás'), findsOneWidget);
    expect(_profileName('Martina'), findsNothing);
    await _openProfile(tester);
    expect(tester.widget<TextField>(_nameField).controller!.text, 'Nicolás');
    expect(tester.takeException(), isNull);
  });

  testWidgets('editing and saving a name updates home and persists it', (
    tester,
  ) async {
    final store = MemorySaveStore();
    final repository = await GameRepository.open(store);
    await _boot(tester, repository, disposeRepository: false);
    await _openProfile(tester);

    await tester.enterText(_nameField, '  Sofía  ');
    await _save(tester);

    expect(find.byType(ProfileScreen), findsNothing);
    expect(_profileName('Sofía'), findsOneWidget);
    expect(repository.state.player.nameChosen, isTrue);
    await tester.pumpWidget(const SizedBox());
    await repository.close();
    final reopened = await GameRepository.open(store);
    expect(reopened.state.player.name, 'Sofía');
    expect(reopened.state.player.nameChosen, isTrue);
    await reopened.close();
    expect(tester.takeException(), isNull);
  });

  testWidgets('clearing a chosen name restores Jugador', (tester) async {
    final repository = GameRepository.memory();
    await repository.setPlayerName('Martina');
    await _boot(tester, repository);
    await _openProfile(tester);

    await tester.enterText(_nameField, '   ');
    await _save(tester);

    expect(find.byType(ProfileScreen), findsNothing);
    expect(_profileName('Jugador'), findsOneWidget);
    expect(repository.state.player.name, 'Jugador');
    expect(repository.state.player.nameChosen, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed name save stays open and can be retried', (tester) async {
    final store = _FailingStore();
    final repository = await GameRepository.open(store);
    await _boot(tester, repository);
    await _openProfile(tester);
    store.fail = true;

    await tester.enterText(_nameField, 'Lucía');
    await _save(tester);

    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.textContaining('No pudimos guardar tu nombre'), findsOneWidget);
    expect(tester.widget<TextField>(_nameField).controller!.text, 'Lucía');
    expect(repository.state.player.name, 'Jugador');
    expect(repository.state.player.nameChosen, isFalse);
    store.fail = false;
    await _save(tester);

    expect(find.byType(ProfileScreen), findsNothing);
    expect(_profileName('Lucía'), findsOneWidget);
    expect(repository.state.player.nameChosen, isTrue);
    expect(tester.takeException(), isNull);
  });
}
