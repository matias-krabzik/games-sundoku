import 'package:flutter/widgets.dart';

/// Plays once when a dialog opens, never when an underlying dialog reappears.
class ModalSoundObserver extends NavigatorObserver {
  ModalSoundObserver({required this.onOpened});

  final VoidCallback onOpened;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PopupRoute) onOpened();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute is PopupRoute) onOpened();
  }
}
