import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/widgets/developer_floating_menu.dart';

void main() {
  testWidgets('DEV control starts bottom-right, moves and opens its modal', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    var resets = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              const SizedBox.expand(),
              DeveloperFloatingMenu(
                actions: [
                  DeveloperMenuAction(
                    key: const ValueKey('test-reset'),
                    label: 'Resetear',
                    icon: Icons.restart_alt,
                    onPressed: () => resets++,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    final button = find.byKey(const ValueKey('dev-floating-button'));
    final initial = tester.getRect(button);
    expect(initial.right, closeTo(390 - 16, .1));
    expect(initial.bottom, closeTo(844 - 16, .1));

    await tester.drag(button, const Offset(-100, -140));
    await tester.pump();
    final moved = tester.getRect(button);
    expect(moved.left, lessThan(initial.left - 60));
    expect(moved.top, lessThan(initial.top - 100));

    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('dev-menu-dialog')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('test-reset')));
    await tester.pumpAndSettle();
    expect(resets, 1);
  });
}
