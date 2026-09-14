import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/data/services/device_game_feedback.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'error sends a short native vibration only when enabled and open',
    () async {
      final calls = <MethodCall>[];
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        calls.add(call);
        return null;
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
      );
      final feedback = DeviceGameFeedback();
      await feedback.error(vibration: false);
      expect(calls, isEmpty);
      await feedback.error(vibration: true);
      expect(calls.single.method, 'HapticFeedback.vibrate');
      expect(calls.single.arguments, isNull);
      await feedback.close();
      await feedback.error(vibration: true);
      expect(calls.length, 1);
    },
  );

  test('unsupported vibration cannot interrupt gameplay', () async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (_) async {
      throw PlatformException(code: 'unavailable');
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );
    final feedback = DeviceGameFeedback();
    await expectLater(feedback.error(vibration: true), completes);
    await feedback.close();
  });
}
