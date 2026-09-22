import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:sundoku/app.dart';
import 'package:sundoku/data/repositories/game_repository.dart';
import 'package:sundoku/data/services/game_feedback.dart';
import 'package:sundoku/data/services/save_store.dart';
import 'package:sundoku/domain/models/player_profile.dart';
import 'package:sundoku/screens/home_screen.dart';
import 'package:sundoku/screens/settings_screen.dart';
import 'package:sundoku/widgets/juicy_press.dart';

class _FeedbackSpy extends GameFeedback {
  var effectsPrepared = false;
  @override
  Future<void> prepareEffects() async => effectsPrepared = true;
  final music = <bool>[];
  final modals = <bool>[];
  @override
  Future<void> modalOpened({required bool sound}) async {
    expect(
      effectsPrepared,
      isTrue,
      reason: 'Effects prepare before the first modal',
    );
    modals.add(sound);
  }

  final toggles = <({bool enabled, bool sound, bool vibration})>[];
  @override
  Future<void> toggle({
    required bool enabled,
    required bool sound,
    required bool vibration,
  }) async =>
      toggles.add((enabled: enabled, sound: sound, vibration: vibration));
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
    'about shows the installed version and opens the studio website',
    (tester) async {
      PackageInfo.setMockInitialValues(
        appName: 'SunDoku',
        packageName: 'com.krabzik.games.sundoku',
        version: '2.3.4',
        buildNumber: '7',
        buildSignature: '',
      );
      const channel = MethodChannel('plugins.flutter.io/url_launcher');
      final messenger = tester.binding.defaultBinaryMessenger;
      final launches = <MethodCall>[];
      var canOpen = true;
      messenger.setMockMethodCallHandler(channel, (call) async {
        launches.add(call);
        return canOpen;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      final repo = GameRepository.memory();
      addTearDown(repo.dispose);
      await _open(tester, repo);
      expect(find.text('SunDoku · v2.3.4'), findsOneWidget);
      await _toggle(tester, 'Acerca de SunDoku');
    expect(find.bySemanticsLabel('Krabzik Games'), findsOneWidget);
      expect(find.text('Versión 2.3.4'), findsOneWidget);
      expect(find.textContaining('acompañá a Doku'), findsNothing);
      final website = find.text('games.krabzik.com');
      await tester.ensureVisible(website);
      await tester.pumpAndSettle();
      await tester.tap(website);
      await tester.pumpAndSettle();
      expect(launches.single.method, 'launch');
      expect(launches.single.arguments['url'], 'https://games.krabzik.com');
      expect(launches.single.arguments['useSafariVC'], isFalse);
      expect(launches.single.arguments['useWebView'], isFalse);

      canOpen = false;
      await tester.tap(website);
      await tester.pumpAndSettle();
      expect(find.text('https://games.krabzik.com'), findsOneWidget);
      expect(find.textContaining('No pudimos abrir el enlace'), findsOneWidget);

      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      for (final size in [
        const Size(320, 568),
        const Size(844, 390),
        const Size(1024, 1366),
      ]) {
        tester.view.physicalSize = size;
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          find.byKey(const ValueKey('about-back')).hitTestable(),
          findsOneWidget,
        );
      }
      await tester.tap(find.byKey(const ValueKey('about-back')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('about-dialog')), findsNothing);
      expect(find.byType(SettingsScreen), findsOneWidget);
    },
  );

  testWidgets(
    'modal keeps home behind it and finishes its press before closing',
    (tester) async {
      final repo = GameRepository.memory();
      addTearDown(repo.dispose);
      await _open(tester, repo);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Configuración'), findsOneWidget);
      expect(find.text('Idioma'), findsNothing);
      expect(find.text('A tu manera, a tu ritmo'), findsNothing);
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

  testWidgets(
    'licenses read the Flutter registry and return through each modal',
    (tester) async {
      LicenseRegistry.addLicense(() async* {
        yield LicenseEntryWithLineBreaks([
          '0 Test library',
          '0 Shared library',
        ], 'Shared copyright notice.');
        yield LicenseEntryWithLineBreaks([
          '0 Test library',
        ], 'Second required license notice.');
      });
      final repo = GameRepository.memory();
      addTearDown(repo.dispose);
      final feedback = _FeedbackSpy();
      await _open(tester, repo, feedback: feedback);
      final previousSounds = feedback.modals.length;
      await _toggle(tester, 'Licencias');
      expect(feedback.modals.length, previousSounds + 1);
      await tester.tap(find.text('Flutter y bibliotecas'));
      await tester.pumpAndSettle();
      expect(feedback.modals.length, previousSounds + 2);
      await tester.tap(find.text('0 Test library'));
      await tester.pumpAndSettle();
      expect(feedback.modals.length, previousSounds + 3);
      final text = tester
          .widget<SelectableText>(find.byType(SelectableText).last)
          .data!;
      expect(text, contains('Shared copyright notice.'));
      expect(text, contains('Second required license notice.'));
      await tester.tap(find.byKey(const ValueKey('licenses-back')).last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Baloo 2'));
      await tester.tap(find.text('Baloo 2'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<SelectableText>(find.byType(SelectableText).last).data,
        contains('SIL OPEN FONT LICENSE'),
      );
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byKey(const ValueKey('licenses-back')).last);
        await tester.pumpAndSettle();
      }
      expect(find.byKey(const ValueKey('licenses-dialog')), findsNothing);
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'audio credits include the bundled licenses and stay usable after rotation',
    (tester) async {
      final repo = GameRepository.memory();
      addTearDown(repo.dispose);
      await _open(tester, repo, size: const Size(320, 568));
      await _toggle(tester, 'Licencias');
      await tester.tap(find.text('Música y sonidos'));
      await tester.pumpAndSettle();
      final credits = find.byType(ListView).last;
      expect(find.text('Kevin MacLeod (incompetech.com)'), findsOneWidget);
      final music = tester
          .widgetList<SelectableText>(find.byType(SelectableText))
          .map((w) => w.data ?? '')
          .join('\n');
      for (final title in [
        'Devonshire Waltz Moderato',
        'Devonshire Waltz Allegretto',
        'Morning',
        'Evening',
      ]) {
        expect(music, contains(title));
      }
      final readMusic = find.byKey(
        const ValueKey('license-assets/licenses/CC-BY-4.0.txt'),
      );
      await tester.ensureVisible(readMusic);
      await tester.pumpAndSettle();
      await tester.tap(readMusic);
      await tester.pumpAndSettle();
      expect(
        tester.widget<SelectableText>(find.byType(SelectableText).last).data,
        contains(
          'Creative Commons Attribution 4.0 International Public License',
        ),
      );
      for (final size in [const Size(844, 390), const Size(320, 568)]) {
        tester.view.physicalSize = size;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('licenses-back')).last.hitTestable(),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      }
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.tap(find.byKey(const ValueKey('licenses-back')).last);
      await tester.pumpAndSettle();
      final readKenney = find.byKey(
        const ValueKey('license-assets/licenses/CC0-1.0.txt'),
      );
      await tester.scrollUntilVisible(
        readKenney,
        200,
        scrollable: find
            .descendant(of: credits, matching: find.byType(Scrollable))
            .first,
      );
      await tester.pumpAndSettle();
      await tester.tap(readKenney);
      await tester.pumpAndSettle();
      expect(
        tester.widget<SelectableText>(find.byType(SelectableText).last).data,
        contains('CC0 1.0 Universal'),
      );
      await tester.tap(find.byKey(const ValueKey('licenses-back')).last);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Mixkit'),
        200,
        scrollable: find
            .descendant(of: credits, matching: find.byType(Scrollable))
            .first,
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Mixkit Sound Effects Free License'),
        findsOneWidget,
      );
      expect(
        await rootBundle.loadString('assets/licenses/CC-BY-4.0.txt'),
        contains('Section 8 -- Interpretation'),
      );
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
    expect(feedback.modals.last, isTrue);
    await _toggle(tester, 'Música');
    await _toggle(tester, 'Efectos de sonido');
    await _toggle(tester, 'Vibración');
    expect(repo.state.settings.music, isFalse);
    expect(repo.state.settings.sound, isFalse);
    expect(repo.state.settings.vibration, isFalse);
    expect(feedback.music.last, isFalse);
    expect(feedback.toggles, [
      (enabled: false, sound: true, vibration: true),
      (enabled: false, sound: true, vibration: true),
      (enabled: false, sound: false, vibration: false),
    ]);
    await _toggle(tester, 'Vibración');
    expect(feedback.toggles.last, (
      enabled: true,
      sound: false,
      vibration: true,
    ));
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
