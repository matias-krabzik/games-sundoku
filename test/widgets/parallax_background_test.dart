import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:sundoku/screens/home_screen.dart';
import 'package:sundoku/widgets/parallax_background.dart';

class _Sensors extends SensorsPlatform {
  int requests = 0;
  int listeners = 0;
  late final events = StreamController<GyroscopeEvent>.broadcast(
    onListen: () => listeners++,
    onCancel: () => listeners--,
  );

  @override
  Stream<GyroscopeEvent> gyroscopeEventStream({
    Duration samplingPeriod = SensorInterval.normalInterval,
  }) {
    requests++;
    return events.stream;
  }
}

Offset offset(WidgetTester tester) {
  final matrix = tester
      .widget<Transform>(find.byKey(const ValueKey('parallax-offset')))
      .transform;
  return Offset(matrix.storage[12], matrix.storage[13]);
}

Future<void> frames(WidgetTester tester, [int count = 90]) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

void main() {
  late _Sensors sensors;
  late SensorsPlatform previousSensors;
  setUp(() {
    previousSensors = SensorsPlatform.instance;
    sensors = _Sensors();
    SensorsPlatform.instance = sensors;
  });
  tearDown(() async {
    SensorsPlatform.instance = previousSensors;
    debugDefaultTargetPlatformOverride = null;
    await sensors.events.close();
  });

  Widget scene({
    bool visible = true,
    bool reduced = false,
    bool accessible = false,
  }) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(
        disableAnimations: reduced,
        accessibleNavigation: accessible,
      ),
      child: TickerMode(
        enabled: visible,
        child: const ParallaxBackground(child: SizedBox.expand()),
      ),
    ),
  );

  testWidgets(
    'macOS hover works in a visible unfocused window but stops when hidden',
    (tester) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      addTearDown(
        () => tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        ),
      );
      await tester.pumpWidget(scene());
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(790, 590));
      await frames(tester);
      expect(offset(tester).dx, lessThan(-20));
      expect(offset(tester).dy, lessThan(-14));
      expect(sensors.requests, 0);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      await tester.pump();
      // Hidden windows do not render another frame; animation must be stopped.
      expect(tester.binding.transientCallbackCount, 0);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(offset(tester), Offset.zero);
      await mouse.moveTo(const Offset(10, 10));
      await frames(tester);
      expect(offset(tester).dx, greaterThan(20));
      expect(offset(tester).dy, greaterThan(14));
      await mouse.removePointer();
      await tester.pumpWidget(const SizedBox());
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    },
    variant: TargetPlatformVariant({TargetPlatform.macOS}),
  );

  for (final platform in [
    TargetPlatform.macOS,
    TargetPlatform.windows,
    TargetPlatform.linux,
    TargetPlatform.fuchsia,
  ]) {
    testWidgets('$platform uses only hover and recenters on exit', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = platform;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      await tester.pumpWidget(scene());
      expect(sensors.requests, 0);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(400, 300));
      await mouse.moveTo(const Offset(790, 590));
      await frames(tester);
      expect(offset(tester).dx, inInclusiveRange(-22, -20));
      expect(offset(tester).dy, inInclusiveRange(-16, -14));
      // A parked pointer keeps the scene still at its target and stops ticking.
      final stationary = offset(tester);
      await tester.pump(const Duration(seconds: 1));
      expect(offset(tester), stationary);
      expect(tester.binding.transientCallbackCount, 0);
      await mouse.moveTo(const Offset(10, 10));
      await frames(tester);
      expect(offset(tester).dx, greaterThan(20));
      expect(offset(tester).dy, greaterThan(14));
      await mouse.removePointer();
      await frames(tester);
      expect(offset(tester), Offset.zero);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(sensors.requests, 0);
      await tester.pumpWidget(const SizedBox());
      debugDefaultTargetPlatformOverride = null;
    });
  }

  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    testWidgets('$platform keeps gyro only while visible and foreground', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = platform;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      await tester.pumpWidget(scene());
      expect(sensors.requests, 1);
      expect(sensors.listeners, 1);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(790, 590));
      await frames(tester, 10);
      expect(offset(tester), Offset.zero);
      sensors.events.add(GyroscopeEvent(.5, 1, 0, DateTime.now()));
      await tester.pump();
      await frames(tester, 6);
      expect(offset(tester).distance, greaterThan(0));
      await tester.pumpWidget(scene(visible: false));
      expect(sensors.listeners, 0);
      expect(offset(tester), Offset.zero);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(sensors.requests, 1);
      await tester.pumpWidget(scene());
      expect(sensors.requests, 2);
      expect(sensors.listeners, 1);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(sensors.listeners, 0);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(sensors.requests, 3);
      expect(sensors.listeners, 1);
      await mouse.removePointer();
      await tester.pumpWidget(const SizedBox());
      debugDefaultTargetPlatformOverride = null;
      expect(sensors.listeners, 0);
    });
  }

  testWidgets('reduced motion disables both gyro and hover', (tester) async {
    for (final platform in [TargetPlatform.android, TargetPlatform.macOS]) {
      debugDefaultTargetPlatformOverride = platform;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      for (final accessible in [false, true]) {
        debugDefaultTargetPlatformOverride = platform;
        await tester.pumpWidget(
          scene(reduced: !accessible, accessible: accessible),
        );
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: const Offset(790, 590));
        await frames(tester, 10);
        expect(offset(tester), Offset.zero);
        expect(sensors.requests, 0);
        await mouse.removePointer();
        await tester.pumpWidget(const SizedBox());
        debugDefaultTargetPlatformOverride = null;
      }
    }
  });

  testWidgets(
    'hover over home controls moves only scenery and taps still work',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      var plays = 0;
      await tester.pumpWidget(
        MaterialApp(home: HomeScreen(onPlay: () => plays++)),
      );
      await frames(tester);
      final play = find.byKey(const ValueKey('home-play'));
      final playRect = tester.getRect(play);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: playRect.center);
      await frames(tester);
      expect(offset(tester).distance, greaterThan(0));
      expect(tester.getRect(play), playRect);
      await tester.tap(play);
      await frames(tester, 20);
      expect(plays, 1);
      expect(sensors.requests, 0);
      expect(tester.takeException(), isNull);
      await mouse.removePointer();
      await tester.pumpWidget(const SizedBox());
      debugDefaultTargetPlatformOverride = null;
    },
  );
}
