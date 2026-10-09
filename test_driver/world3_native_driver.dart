import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final output = Directory(
    Platform.environment['W3_NATIVE_OUTPUT'] ?? 'build/world3-native',
  );
  await output.create(recursive: true);
  await integrationDriver(
    onScreenshot: (name, bytes, [args]) async {
      await File('${output.path}/$name.png').writeAsBytes(bytes);
      if (args != null) {
        await File('${output.path}/$name.json')
            .writeAsString(const JsonEncoder.withIndent('  ').convert(args));
      }
      return bytes.isNotEmpty;
    },
  );
}
