import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sundoku/app.dart';
import 'package:sundoku/data/repositories/game_repository.dart';
import 'package:sundoku/data/services/game_feedback.dart';
import 'package:sundoku/data/services/save_store.dart';
import 'package:sundoku/domain/models/player_profile.dart';
import 'package:sundoku/screens/home_screen.dart';
import 'package:sundoku/screens/settings_screen.dart';
import 'package:sundoku/widgets/juicy_press.dart';

class _FeedbackSpy extends GameFeedback {
  final music = <bool>[];
  final taps = <({bool sound, bool vibration})>[];
  @override
  Future<void> setMusicEnabled(bool enabled) async => music.add(enabled);
  @override
  Future<void> tap({required bool sound, required bool vibration}) async =>
      taps.add((sound: sound, vibration: vibration));
}

class _FailingStore extends MemorySaveStore {
  bool fail = false;
  @override
  Future<void> write(String data, {required int expectedRevision}) async {
    if (fail) throw StateError('Disk write failed');
    await super.write(data, expectedRevision: expectedRevision);
  }
}

Future<void> _open(
  WidgetTester tester,
  GameRepository repository, {
  GameFeedback feedback = const GameFeedback(),
  Size size = const Size(390, 844),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    SunDokuApp(repository: repository, feedback: feedback),
  );
  await tester.pump(const Duration(seconds: 3));
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(seconds: 1));
  for (var frame = 0; frame < 10; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  final welcome = find.byKey(const ValueKey('profile-close'));
  if (welcome.evaluate().isNotEmpty) {
    await tester.tap(welcome);
    for (var frame = 0; frame < 10; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }
  await tester.tap(find.byKey(const ValueKey('home-settings')));
  await tester.pumpAndSettle();
}

Future<void> _toggle(WidgetTester tester, String label) async {
  final finder = find.byKey(ValueKey('setting-$label'));
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'modal keeps home behind it and finishes its press before closing',
    (tester) async {
      final repo = GameRepository.memory();
      addTearDown(repo.dispose);
      await _open(tester, repo);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Configuración'), findsOneWidget);
      expect(find.text('Idioma'), findsNothing);
      final homeContext = tester.element(find.byType(HomeScreen));
      expect(ModalRoute.of(homeContext)!.isCurrent, isFalse);
      final done = find.byKey(const ValueKey('settings-done'));
      final gesture = await tester.startGesture(tester.getCenter(done));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 110));
      final transform = tester.widget<Transform>(
        find.descendant(
          of: done,
          matching: find.byKey(const ValueKey('juicy-press-transform')),
        ),
      );
      expect(transform.transform.entry(1, 1), lessThan(.96));
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 60));
      expect(find.byType(SettingsScreen), findsOneWidget);
      // The home logo resumes its idle animation when the dialog closes.
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(SettingsScreen), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('all preferences persist and drive real feedback decisions', (
    tester,
  ) async {
    final store = MemorySaveStore();
    final repo = await GameRepository.open(store);
    final feedback = _FeedbackSpy();
    await _open(tester, repo, feedback: feedback);
    await _toggle(tester, 'Música');
    await _toggle(tester, 'Efectos de sonido');
    await _toggle(tester, 'Vibración');
    expect(repo.state.settings.music, isFalse);
    expect(repo.state.settings.sound, isFalse);
    expect(repo.state.settings.vibration, isFalse);
    expect(feedback.music.last, isFalse);
    expect(feedback.taps.last, (sound: false, vibration: false));
    await _toggle(tester, 'Vibración');
    expect(feedback.taps.last, (sound: false, vibration: true));
    await _toggle(tester, 'Música');
    expect(feedback.music.last, isTrue);
    await tester.pumpWidget(const SizedBox());
    await repo.close();
    final reopened = await GameRepository.open(store);
    expect(reopened.state.settings.music, isTrue);
    expect(reopened.state.settings.sound, isFalse);
    expect(reopened.state.settings.vibration, isTrue);
    await reopened.close();
  });

  testWidgets('failed save restores the toggle and allows a retry', (
    tester,
  ) async {
    final store = _FailingStore();
    final repo = await GameRepository.open(store);
    addTearDown(repo.dispose);
    await _open(tester, repo);
    store.fail = true;
    await _toggle(tester, 'Música');
    expect(repo.state.settings.music, isTrue);
    final row = tester.widget<JuicyPress>(
      find.byKey(const ValueKey('setting-Música')),
    );
    expect(row.toggled, isTrue);
    expect(find.textContaining('No pudimos guardar'), findsOneWidget);
    store.fail = false;
    await _toggle(tester, 'Música');
    expect(repo.state.settings.music, isFalse);
    expect(find.textContaining('No pudimos guardar'), findsNothing);
  });

  testWidgets(
    'small screens, rotation and large text keep controls reachable',
    (tester) async {
      final repo = GameRepository.memory();
      addTearDown(repo.dispose);
      await _open(tester, repo, size: const Size(320, 568));
      expect(tester.takeException(), isNull);
      expect(
        find.byKey(const ValueKey('settings-done')).hitTestable(),
        findsOneWidget,
      );
      await _toggle(tester, 'Vibración');
      tester.view.physicalSize = const Size(844, 390);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Acerca de SunDoku'));
      await tester.tap(find.text('Acerca de SunDoku'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Volver'));
      await tester.tap(find.text('Volver'));
      await tester.pumpAndSettle();
      expect(find.text('Configuración'), findsOneWidget);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      tester.view.physicalSize = const Size(320, 568);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        find.byKey(const ValueKey('settings-done')).hitTestable(),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'canceling a press does not close; reduced motion and back work',
    (tester) async {
      final repo = GameRepository.memory();
      addTearDown(repo.dispose);
      await _open(tester, repo);
      final done = find.byKey(const ValueKey('settings-done'));
      final gesture = await tester.startGesture(tester.getCenter(done));
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.cancel();
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await tester.pumpAndSettle();
      await _toggle(tester, 'Efectos de sonido');
      expect(repo.state.settings.sound, isFalse);
      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(SettingsScreen), findsNothing);
    },
  );

  test(
    'older saves enable vibration by default and retain unknown settings',
    () {
      final settings = GameSettings.fromJson({'sound': false, 'future': 7});
      expect(settings.vibration, isTrue);
      expect(settings.toJson()['future'], 7);
      expect(
        GameSettings.fromJson({...settings.toJson(), 'vibration': false})
            .vibration,
        isFalse,
      );
    },
  );
}
