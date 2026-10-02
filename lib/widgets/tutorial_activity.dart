import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../playables/playables_runtime.dart';

/// One visibility signal for typing, demonstrations and automatic navigation.
/// A covered route, a background app or a paused Playable stops all three.
class TutorialActivity extends StatefulWidget {
  const TutorialActivity({super.key, required this.child, this.paused = false});
  final Widget child;
  final bool paused;

  static ValueListenable<bool>? of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_TutorialActivityScope>()
      ?.activity;

  @override
  State<TutorialActivity> createState() => _TutorialActivityState();
}

class _TutorialActivityState extends State<TutorialActivity>
    with WidgetsBindingObserver {
  final _playables = PlayablesRuntime.active;
  ModalRoute<dynamic>? _route;
  final _activity = ValueNotifier(false);
  bool _tickerEnabled = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _playables?.addListener(_refresh);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tickerEnabled = TickerMode.valuesOf(context).enabled;
    final route = ModalRoute.of(context);
    if (route == _route) {
      _refresh();
      return;
    }
    _route?.animation?.removeStatusListener(_routeChanged);
    _route?.secondaryAnimation?.removeStatusListener(_routeChanged);
    _route = route;
    _route?.animation?.addStatusListener(_routeChanged);
    _route?.secondaryAnimation?.addStatusListener(_routeChanged);
    _refresh();
  }

  @override
  void didUpdateWidget(TutorialActivity oldWidget) {
    super.didUpdateWidget(oldWidget);
    _refresh();
  }

  void _routeChanged(AnimationStatus _) => _refresh();
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) => _refresh();

  void _refresh() {
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    final foreground = _playables?.inPlayablesEnvironment == true
        ? !_playables!.isPaused
        : lifecycle == null || lifecycle == AppLifecycleState.resumed;
    _activity.value =
        !widget.paused &&
        foreground &&
        _tickerEnabled &&
        (_route?.isCurrent ?? true) &&
        (_route?.animation?.isCompleted ?? true) &&
        (_route?.secondaryAnimation?.isDismissed ?? true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _playables?.removeListener(_refresh);
    _route?.animation?.removeStatusListener(_routeChanged);
    _route?.secondaryAnimation?.removeStatusListener(_routeChanged);
    _activity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _TutorialActivityScope(activity: _activity, child: widget.child);
}

class _TutorialActivityScope extends InheritedWidget {
  const _TutorialActivityScope({required this.activity, required super.child});
  final ValueListenable<bool> activity;
  @override
  bool updateShouldNotify(_TutorialActivityScope oldWidget) =>
      activity != oldWidget.activity;
}
