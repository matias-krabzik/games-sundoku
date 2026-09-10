import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../routes.dart';
import '../data/level_node.dart';

const Color _navy = Color(0xFF082A62);
const Color _gold = Color(0xFFFFC928);
const Color _goldDark = Color(0xFFF39A08);

/// Sunny title screen with Doku, the primary play action, and game progress.
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    this.availableLevel = 1,
    this.unlockedLevels = 1,
  });

  final int availableLevel;
  final int unlockedLevels;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _ParallaxBackground(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final bool wideShort =
                    constraints.maxWidth >= 700 && constraints.maxHeight < 520;
                if (wideShort) {
                  return _WideHomeLayout(
                    constraints: constraints,
                    availableLevel: availableLevel,
                    unlockedLevels: unlockedLevels,
                  );
                }

                final bool veryShort = constraints.maxHeight < 620;
                final bool compact = constraints.maxHeight < 720;
                final double horizontalPadding = compact ? 16 : 20;
                final double contentWidth = constraints.maxWidth.clamp(0, 560);
                final double innerWidth = contentWidth - horizontalPadding * 2;
                final double logoWidth =
                    (innerWidth * (veryShort ? 0.72 : 0.82))
                        .clamp(190, 330)
                        .toDouble();
                final double headerHeight = veryShort
                    ? 96
                    : compact
                    ? 118
                    : 168;

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        compact ? 6 : 12,
                        horizontalPadding,
                        compact ? 10 : 18,
                      ),
                      child: Column(
                        children: [
                          SizedBox(
                            height: headerHeight,
                            child: Stack(
                              children: [
                                Align(
                                  alignment: Alignment.bottomCenter,
                                  child: _AnimatedLogo(width: logoWidth),
                                ),
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: _SettingsButton(
                                    compact: compact,
                                    onPressed: () =>
                                        Navigator.of(context)
                                            .pushNamed(AppRoutes.settings),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: compact ? 18 : 4,
                              ),
                              child: Image.asset(
                                'assets/images/doku-home.png',
                                fit: BoxFit.contain,
                                alignment: Alignment.bottomCenter,
                                semanticLabel: 'Doku saluda alegremente',
                              ),
                            ),
                          ),
                          SizedBox(height: compact ? 4 : 8),
                          _PlayButton(
                            compact: compact,
                            onPressed: () =>
                                Navigator.of(context).pushNamed(AppRoutes.map),
                          ),
                          SizedBox(height: compact ? 10 : 14),
                          _GameStatusCard(
                            compact: compact,
                            availableLevel: availableLevel,
                            unlockedLevels: unlockedLevels,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WideHomeLayout extends StatelessWidget {
  const _WideHomeLayout({
    required this.constraints,
    required this.availableLevel,
    required this.unlockedLevels,
  });

  final int availableLevel;
  final int unlockedLevels;

  final BoxConstraints constraints;

  @override
  Widget build(BuildContext context) {
    final double logoWidth = (constraints.maxWidth * 0.38)
        .clamp(250, 330)
        .toDouble();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 920),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
          child: Stack(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: Column(
                      children: [
                        SizedBox(
                          height: 104,
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: _AnimatedLogo(width: logoWidth),
                          ),
                        ),
                        Expanded(
                          child: Image.asset(
                            'assets/images/doku-home.png',
                            fit: BoxFit.contain,
                            alignment: Alignment.bottomCenter,
                            semanticLabel: 'Doku saluda alegremente',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 5,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 350),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _PlayButton(
                              compact: true,
                              onPressed: () =>
                                  Navigator.of(context)
                                      .pushNamed(AppRoutes.map),
                            ),
                            const SizedBox(height: 18),
                            _GameStatusCard(
                              compact: true,
                              availableLevel: availableLevel,
                              unlockedLevels: unlockedLevels,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                right: 0,
                top: 0,
                child: _SettingsButton(
                  compact: true,
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AppRoutes.settings),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedLogo extends StatefulWidget {
  const _AnimatedLogo({required this.width});

  final double width;

  @override
  State<_AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<_AnimatedLogo>
    with TickerProviderStateMixin {
  static bool _hasPlayedEntrance = false;

  late final AnimationController _entranceController;
  late final AnimationController _idleController;
  late final Animation<Offset> _idleOffset;
  late final Animation<double> _idleRotation;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    );

    final math.Random random = math.Random();
    final List<Offset> offsets = [
      Offset.zero,
      for (int i = 0; i < 7; i++)
        Offset(random.nextDouble() * 6 - 3, random.nextDouble() * 4 - 2),
      Offset.zero,
    ];
    final List<double> rotations = [
      0,
      for (int i = 0; i < 7; i++) random.nextDouble() * 0.016 - 0.008,
      0,
    ];

    _idleOffset = _offsetSequence(offsets).animate(_idleController);
    _idleRotation = _doubleSequence(rotations).animate(_idleController);
  }

  TweenSequence<Offset> _offsetSequence(List<Offset> values) {
    return TweenSequence<Offset>([
      for (int i = 0; i < values.length - 1; i++)
        TweenSequenceItem(
          tween: Tween<Offset>(
            begin: values[i],
            end: values[i + 1],
          ).chain(CurveTween(curve: Curves.easeInOut)),
          weight: 1,
        ),
    ]);
  }

  TweenSequence<double> _doubleSequence(List<double> values) {
    return TweenSequence<double>([
      for (int i = 0; i < values.length - 1; i++)
        TweenSequenceItem(
          tween: Tween<double>(
            begin: values[i],
            end: values[i + 1],
          ).chain(CurveTween(curve: Curves.easeInOut)),
          weight: 1,
        ),
    ]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    final bool animationsDisabled = MediaQuery.disableAnimationsOf(context);
    final bool shouldPlayEntrance = !_hasPlayedEntrance;
    _hasPlayedEntrance = true;

    if (animationsDisabled || !shouldPlayEntrance) {
      _entranceController.value = 1;
      if (!animationsDisabled) _idleController.repeat();
      return;
    }

    _entranceController.forward().whenComplete(() {
      if (mounted) _idleController.repeat();
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _idleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([_entranceController, _idleController]),
        child: Image.asset(
          'assets/images/sundoku-logo.png',
          width: widget.width,
          fit: BoxFit.contain,
          semanticLabel: 'SunDoku',
        ),
        builder: (context, child) {
          final double entrance = Curves.easeOutBack.transform(
            _entranceController.value,
          );
          final Offset position =
              Offset(0, -34 * (1 - entrance)) + _idleOffset.value;
          final double scale = 0.72 + 0.28 * entrance;

          return Transform.translate(
            offset: position,
            child: Transform.rotate(
              angle: _idleRotation.value,
              child: Transform.scale(scale: scale, child: child),
            ),
          );
        },
      ),
    );
  }
}

class _ParallaxBackground extends StatefulWidget {
  const _ParallaxBackground();

  @override
  State<_ParallaxBackground> createState() => _ParallaxBackgroundState();
}

class _ParallaxBackgroundState extends State<_ParallaxBackground>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  static const double _maxX = 22;
  static const double _maxY = 16;
  static const double _sensorStrength = 280;
  static const double _springStrength = 12;
  static const double _friction = 5.5;

  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  late final Ticker _motionTicker;
  Duration _lastFrame = Duration.zero;
  DateTime? _lastSensorEvent;
  Offset _sensorInput = Offset.zero;
  Offset _position = Offset.zero;
  Offset _velocity = Offset.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _motionTicker = createTicker(_advanceMotion);
    _startListening();
  }

  void _startListening() {
    _gyroscopeSubscription ??= gyroscopeEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen(_handleGyroscope, onError: (_) {}, cancelOnError: true);
  }

  void _handleGyroscope(GyroscopeEvent event) {
    if (!mounted) return;

    final Offset rawReading = Offset(
      (-event.y).clamp(-2.5, 2.5).toDouble(),
      (-event.x).clamp(-2.5, 2.5).toDouble(),
    );
    final Offset reading = rawReading.distance < 0.025
        ? Offset.zero
        : rawReading;
    _sensorInput = Offset.lerp(_sensorInput, reading, 0.35)!;
    if (_sensorInput.distance < 0.01) _sensorInput = Offset.zero;
    _lastSensorEvent = DateTime.now();

    final bool needsMotion =
        _sensorInput != Offset.zero ||
        _position.distance >= 0.12 ||
        _velocity.distance >= 0.12;
    if (!_motionTicker.isActive && needsMotion) {
      _lastFrame = Duration.zero;
      _motionTicker.start();
    }
  }

  void _advanceMotion(Duration elapsed) {
    if (_lastFrame == Duration.zero) {
      _lastFrame = elapsed;
      return;
    }

    final double dt = ((elapsed - _lastFrame).inMicroseconds / 1000000)
        .clamp(1 / 240, 1 / 30)
        .toDouble();
    _lastFrame = elapsed;

    if (_lastSensorEvent == null ||
        DateTime.now().difference(_lastSensorEvent!) >
            const Duration(milliseconds: 120)) {
      _sensorInput = Offset.zero;
    }

    final Offset acceleration = Offset(
      _sensorInput.dx * _sensorStrength -
          _position.dx * _springStrength -
          _velocity.dx * _friction,
      _sensorInput.dy * _sensorStrength -
          _position.dy * _springStrength -
          _velocity.dy * _friction,
    );

    _velocity += acceleration * dt;
    Offset nextPosition = _position + _velocity * dt;

    final double clampedX = nextPosition.dx.clamp(-_maxX, _maxX).toDouble();
    final double clampedY = nextPosition.dy.clamp(-_maxY, _maxY).toDouble();
    if (clampedX != nextPosition.dx) {
      _velocity = Offset(-_velocity.dx * 0.18, _velocity.dy);
    }
    if (clampedY != nextPosition.dy) {
      _velocity = Offset(_velocity.dx, -_velocity.dy * 0.18);
    }
    nextPosition = Offset(clampedX, clampedY);

    final bool settled =
        _sensorInput.distance < 0.01 &&
        _velocity.distance < 0.12 &&
        nextPosition.distance < 0.12;
    if (settled) {
      _position = Offset.zero;
      _velocity = Offset.zero;
      _motionTicker.stop();
    } else {
      _position = nextPosition;
    }

    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startListening();
    } else {
      _motionTicker.stop();
      _sensorInput = Offset.zero;
      _gyroscopeSubscription?.cancel();
      _gyroscopeSubscription = null;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _gyroscopeSubscription?.cancel();
    _motionTicker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Transform.translate(
        offset: _position,
        child: Transform.scale(
          scale: 1.1,
          child: Image.asset(
            'assets/images/home-background.png',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        ),
      ),
    );
  }
}

class _SettingsButton extends StatelessWidget {
  const _SettingsButton({required this.compact, required this.onPressed});

  final bool compact;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final double size = compact ? 50 : 58;

    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF7D7), Color(0xFFFFD45E)],
        ),
        border: Border.fromBorderSide(
          BorderSide(color: Color(0xFFFFED9A), width: 3),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x75062A55),
            offset: Offset(0, 8),
            blurRadius: 11,
          ),
          BoxShadow(color: Color(0xFFD88C0B), offset: Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Icon(
            Icons.settings_rounded,
            color: _navy,
            size: compact ? 28 : 32,
            semanticLabel: 'Ajustes',
          ),
        ),
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.compact, required this.onPressed});

  final bool compact;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Jugar',
      child: Container(
        width: compact ? 220 : 260,
        height: compact ? 62 : 72,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFE65A), _gold],
          ),
          border: Border.all(color: const Color(0xFFFFF0A0), width: 3),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66087549),
              offset: Offset(0, 8),
              blurRadius: 12,
            ),
            BoxShadow(color: _goldDark, offset: Offset(0, 4)),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(28),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.play_arrow_rounded,
                  color: _navy,
                  size: compact ? 38 : 44,
                ),
                const SizedBox(width: 8),
                Text(
                  'Jugar',
                  style: TextStyle(
                    color: _navy,
                    fontSize: compact ? 27 : 31,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GameStatusCard extends StatelessWidget {
  const _GameStatusCard({
    required this.compact,
    required this.availableLevel,
    required this.unlockedLevels,
  });

  final int availableLevel;
  final int unlockedLevels;

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 112 : 132,
      padding: EdgeInsets.fromLTRB(
        compact ? 16 : 22,
        compact ? 12 : 16,
        compact ? 16 : 22,
        compact ? 10 : 14,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFAE9), Color(0xFFFFE2A0)],
          stops: [0.15, 1],
        ),
        borderRadius: BorderRadius.circular(compact ? 28 : 34),
        border: Border.all(color: const Color(0xFFFFF2B8), width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x73506A22),
            offset: Offset(0, 11),
            blurRadius: 17,
          ),
          BoxShadow(color: Color(0xFFD99A32), offset: Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                const Icon(Icons.sunny, color: _goldDark, size: 32),
                const SizedBox(width: 8),
                Expanded(child: _StatusText('Nivel $availableLevel')),
                Container(
                  width: 2,
                  height: compact ? 30 : 38,
                  color: const Color(0xFFD9A84E),
                ),
                const SizedBox(width: 12),
                const Icon(
                  Icons.landscape_rounded,
                  color: Color(0xFF4A9B47),
                  size: 33,
                ),
                const SizedBox(width: 8),
                const Expanded(child: _StatusText('Mundo 1')),
              ],
            ),
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: compact ? 10 : 12,
              color: const Color(0xFFDCCDA7),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: unlockedLevels / kMap1Nodes.length,
                heightFactor: 1,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [_gold, _goldDark]),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: compact ? 3 : 5),
          Text(
            '$unlockedLevels de ${kMap1Nodes.length}',
            style: TextStyle(
              color: _navy,
              fontSize: compact ? 14 : 16,
              height: 1,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusText extends StatelessWidget {
  const _StatusText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.fade,
      softWrap: false,
      style: const TextStyle(
        color: _navy,
        fontSize: 18,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.3,
      ),
    );
  }
}
