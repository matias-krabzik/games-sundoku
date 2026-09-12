import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'home_art.dart';
import 'ui_surface_art.dart';

/// A short, skippable reveal that keeps the final paragraph's layout intact.
class TutorialStory extends StatefulWidget {
  const TutorialStory({
    super.key,
    this.autoplay = true,
    this.onFinished,
    this.lines = sentences,
    this.tip = conclusion,
    this.skipHint = 'Toca para mostrar toda la historia',
    this.interactive = true,
    this.animate = true,
  });

  final bool autoplay;
  final VoidCallback? onFinished;
  final List<String> lines;
  final String tip;
  final String skipHint;
  final bool interactive;
  final bool animate;

  static const sentences = [
    'Antes se llamaba Number Place.',
    'En 1984, Nikoli lo llevó a Japón.',
    'Allí recibió el nombre Sudoku.',
  ];
  static const conclusion = 'No necesitas hacer cuentas.';
  static final semanticLabel = '${sentences.join(' ')} $conclusion';

  static const blockLines = [
    'Vamos a completar un bloque de 9 casillas.',
    'Elige números del 1 al 9, sin repetir.',
    'Yo iré marcando otra casilla vacía.',
  ];
  static const blockTip = 'También puedes tocar otra casilla.';

  @override
  State<TutorialStory> createState() => _TutorialStoryState();
}

class _TutorialStoryState extends State<TutorialStory>
    with SingleTickerProviderStateMixin {
  final _revealAt = <int>[];
  late final AnimationController _reveal;
  late int _typingEnd;
  late int _duration;
  bool _started = false;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _reveal = AnimationController(vsync: this)
      ..addStatusListener(_statusChanged);
    _configureTiming();
  }

  void _configureTiming() {
    _revealAt.clear();
    var time = 350;
    for (final letter in widget.lines.join('\n').characters) {
      time += 32;
      _revealAt.add(time);
      if (letter == '.') time += 220;
      if (letter == ',') time += 100;
    }
    _typingEnd = time;
    _duration = time + 450;
    _reveal.duration = Duration(milliseconds: _duration);
  }

  void _statusChanged(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _reveal.isCompleted) widget.onFinished?.call();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _begin();
  }

  @override
  void didUpdateWidget(TutorialStory oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.lines, widget.lines) ||
        oldWidget.tip != widget.tip) {
      _started = false;
      _reveal.reset();
      _configureTiming();
      _begin();
      return;
    }
    if (!oldWidget.autoplay && widget.autoplay) _begin();
    if (oldWidget.animate && !widget.animate) _finish();
  }

  void _begin() {
    if (!widget.autoplay) return;
    if (!widget.animate ||
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context)) {
      _finish();
    } else if (!_started) {
      _reveal.forward();
    }
    _started = true;
  }

  void _finish() => _reveal.value = 1;

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 360;
    final largeText = MediaQuery.textScalerOf(context).scale(16) > 24;
    final letters = widget.lines.join(narrow ? ' ' : '\n').characters;
    return AnimatedBuilder(
      animation: _reveal,
      builder: (context, _) {
        final time = _reveal.value * _duration;
        final count = _revealAt.where((at) => at <= time).length;
        final conclusion = Curves.easeOut.transform(
          ((time - _typingEnd) / 450).clamp(0.0, 1.0),
        );
        return Semantics(
          label: '${widget.lines.join(' ')} ${widget.tip}',
          hint: _reveal.isCompleted || !widget.interactive
              ? null
              : widget.skipHint,
          onTap: _reveal.isCompleted || !widget.interactive ? null : _finish,
          excludeSemantics: true,
          child: FocusableActionDetector(
            enabled: widget.interactive && !_reveal.isCompleted,
            onShowFocusHighlight: (value) => setState(() => _focused = value),
            shortcuts: const {
              SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
              SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
            },
            actions: {
              ActivateIntent: CallbackAction<ActivateIntent>(
                onInvoke: (_) {
                  _finish();
                  return null;
                },
              ),
            },
            child: GestureDetector(
              key: const ValueKey('intro-story'),
              behavior: HitTestBehavior.opaque,
              onTap:
                  _reveal.isCompleted || !widget.autoplay || !widget.interactive
                  ? null
                  : _finish,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: _focused
                      ? Border.all(color: homeNavy, width: 2)
                      : null,
                ),
                child: UiSurfacePanel(
                  surface: UiSurface.goldCreamPanel,
                  padding: EdgeInsets.fromLTRB(
                    24,
                    largeText ? 46 : 23,
                    24,
                    largeText ? 54 : 27,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text.rich(
                        key: const ValueKey('intro-story-text'),
                        TextSpan(
                          children: [
                            TextSpan(text: letters.take(count).toString()),
                            TextSpan(
                              text: letters.skip(count).toString(),
                              style: const TextStyle(color: Colors.transparent),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                        style: homeText(
                          narrow ? 17 : 18,
                          weight: FontWeight.w600,
                        ).copyWith(height: 1.25),
                      ),
                      Opacity(
                        opacity: conclusion,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: SizedBox(
                            height: 2,
                            child: HomeArt(HomeSurface.progressFill),
                          ),
                        ),
                      ),
                      Opacity(
                        key: const ValueKey('intro-story-conclusion'),
                        opacity: conclusion,
                        child: Transform.scale(
                          scale: .96 + .04 * conclusion,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const HomeIcon(HomeGlyph.sun, size: 28),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  widget.tip,
                                  textAlign: TextAlign.center,
                                  style: homeText(narrow ? 18 : 20),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
