import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Keeps the illustrated desktop pointer above routes and dialogs.
class SunDokuCursor extends StatefulWidget {
  const SunDokuCursor({super.key, required this.child});

  static const asset = 'assets/images/cursor-blue.png';
  static const size = 40.0;
  static const hotspot = Offset(6.5, 2.5);
  final Widget child;

  @override
  State<SunDokuCursor> createState() => _SunDokuCursorState();
}

class _SunDokuCursorState extends State<SunDokuCursor> {
  static const _image = ResizeImage(
    AssetImage(SunDokuCursor.asset),
    width: 128,
  );
  final _position = ValueNotifier<Offset?>(null);
  bool _loading = false;
  bool _ready = false;

  bool get _desktop => switch (defaultTargetPlatform) {
    TargetPlatform.android || TargetPlatform.iOS => false,
    _ => true,
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_desktop || _loading) return;
    _loading = true;
    var failed = false;
    unawaited(
      precacheImage(
        _image,
        context,
        onError: (error, stack) {
          failed = true;
          FlutterError.reportError(
            FlutterErrorDetails(
              exception: error,
              stack: stack,
              library: 'SunDoku cursor',
              context: ErrorDescription('loading the desktop cursor artwork'),
            ),
          );
        },
      ).then((_) {
        if (mounted && !failed) setState(() => _ready = true);
      }),
    );
  }

  void _move(PointerEvent event) {
    _position.value = event.kind == PointerDeviceKind.mouse
        ? event.localPosition
        : null;
  }

  @override
  void dispose() {
    _position.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_desktop) return widget.child;
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        // Translucent hit testing preserves every underlying hover, tap and drag.
        Positioned.fill(
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: _move,
            onPointerMove: _move,
            child: MouseRegion(
              opaque: false,
              hitTestBehavior: HitTestBehavior.translucent,
              cursor: _ready ? SystemMouseCursors.none : MouseCursor.defer,
              onEnter: _move,
              onHover: _move,
              onExit: (_) => _position.value = null,
              child: const SizedBox.expand(),
            ),
          ),
        ),
        if (_ready)
          Positioned.fill(
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: ValueListenableBuilder<Offset?>(
                  valueListenable: _position,
                  child: const Image(
                    image: _image,
                    width: SunDokuCursor.size,
                    height: SunDokuCursor.size,
                    filterQuality: FilterQuality.high,
                  ),
                  builder: (context, point, child) => Stack(
                    children: [
                      if (point != null)
                        Positioned(
                          key: const ValueKey('sundoku-pointer'),
                          left: point.dx - SunDokuCursor.hotspot.dx,
                          top: point.dy - SunDokuCursor.hotspot.dy,
                          child: RepaintBoundary(child: child),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
