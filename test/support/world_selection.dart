import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/widgets/world_overview_viewport.dart';

/// Bring a destination into view, select its card, then use its explicit entry.
/// Camera movement and gesture behavior have their own selector tests.
Future<void> enterOverviewWorld(WidgetTester tester, String worldId) async {
  final camera = tester
      .widget<WorldOverviewViewport>(find.byType(WorldOverviewViewport))
      .camera;
  camera.focusWorld(worldId, animate: false);
  await tester.pump();
  await tester.tap(find.byKey(ValueKey('choose-$worldId')));
  for (var i = 0; i < 24; i++) {
    await tester.pump(const Duration(milliseconds: 33));
  }
  await tester.tap(find.byKey(ValueKey('world-enter-$worldId')));
  for (var i = 0; i < 24; i++) {
    await tester.pump(const Duration(milliseconds: 33));
  }
}
