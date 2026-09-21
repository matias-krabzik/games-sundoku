import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/widgets/modal_sound_observer.dart';

void main() {
  testWidgets('dialogs sound once on opening, not on rebuild or closing', (
    tester,
  ) async {
    var openings = 0;
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        navigatorObservers: [ModalSoundObserver(onOpened: () => openings++)],
        home: const Scaffold(body: Text('Home')),
      ),
    );
    expect(openings, 0);
    void open() => showDialog<void>(
      context: navigator.currentContext!,
      builder: (_) => const AlertDialog(content: Text('Modal')),
    );
    open();
    await tester.pumpAndSettle();
    expect(openings, 1);
    open();
    await tester.pumpAndSettle();
    expect(openings, 2);
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(openings, 2);
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    open();
    await tester.pumpAndSettle();
    expect(openings, 3);
  });

  test('question WAV is included in the asset bundle', () async {
    final data = await rootBundle.load('assets/audio/sfx/question.wav');
    expect(String.fromCharCodes(data.buffer.asUint8List(0, 4)), 'RIFF');
    expect(data.lengthInBytes, greaterThan(44));
  });
}
