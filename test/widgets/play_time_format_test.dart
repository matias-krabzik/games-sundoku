import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/widgets/game_pause.dart';

void main() {
  test('play time rolls over minutes, hours and days', () {
    final cases = <Duration, String>{
      Duration.zero: '00:00',
      const Duration(milliseconds: 999): '00:00',
      const Duration(seconds: 59): '00:59',
      const Duration(minutes: 1): '01:00',
      const Duration(minutes: 59, seconds: 59): '59:59',
      const Duration(hours: 1): '01:00:00',
      const Duration(hours: 23, minutes: 59, seconds: 59): '23:59:59',
      const Duration(days: 1): '1d 00:00:00',
      const Duration(days: 1, hours: 2, minutes: 3, seconds: 7): '1d 02:03:07',
      const Duration(days: 13, hours: 5): '13d 05:00:00',
    };
    for (final entry in cases.entries) {
      expect(formatPlayTime(entry.key.inMilliseconds), entry.value);
    }
  });
}
