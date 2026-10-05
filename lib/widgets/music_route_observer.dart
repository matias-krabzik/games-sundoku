import 'dart:async';

import 'package:flutter/widgets.dart';

import '../data/services/game_feedback.dart';
import '../routes.dart';

/// Dialogs retain the music of the underlying destination.
class MusicRouteObserver extends NavigatorObserver {
  MusicRouteObserver(this.output);

  final GameFeedback output;
  final _routes = <Route<dynamic>>[];
  Route<dynamic>? _musicRoute;

  MusicScene? _scene(Route<dynamic> route) => switch (route.settings.name) {
    AppRoutes.home || AppRoutes.quickPlay => MusicScene.home,
    AppRoutes.worlds ||
    AppRoutes.map ||
    AppRoutes.tutorialReview => MusicScene.map,
    AppRoutes.game || AppRoutes.firstExperience => MusicScene.game,
    _ => null,
  };

  void _sync() {
    for (final route in _routes.reversed) {
      final scene = _scene(route);
      if (scene == null) continue;
      if (!identical(route, _musicRoute)) {
        _musicRoute = route;
        unawaited(output.setMusicScene(scene));
      }
      return;
    }
    _musicRoute = null;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.add(route);
    _sync();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.remove(route);
    _sync();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.remove(route);
    _sync();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final index = oldRoute == null ? -1 : _routes.indexOf(oldRoute);
    if (index >= 0) {
      if (newRoute == null) {
        _routes.removeAt(index);
      } else {
        _routes[index] = newRoute;
      }
    } else if (newRoute != null) {
      _routes.add(newRoute);
    }
    _sync();
  }
}
