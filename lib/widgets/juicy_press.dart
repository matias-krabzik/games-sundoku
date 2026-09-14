import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Squash on contact, spring on release, then invoke the action exactly once.
class JuicyPress extends StatefulWidget {
  const JuicyPress({
    super.key,
    required this.label,
    required this.builder,
    required this.onPressed,
    this.onFeedback,
    this.toggled,
  });

  final String label;
  final Widget Function(BuildContext context, double depression) builder;
  final FutureOr<void> Function()? onPressed;
  final VoidCallback? onFeedback;
  final bool? toggled;

  @override
  State<JuicyPress> createState() => _JuicyPressState();
}

class _JuicyPressState extends State<JuicyPress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 85),
    reverseDuration: const Duration(milliseconds: 150),
  );
  bool _busy = false;
  bool _focused = false;
  bool _hovered = false;
  bool _feedbackSent = false;
  bool get _reduced => MediaQuery.disableAnimationsOf(context);

  void _down() {
    if (_busy || widget.onPressed == null) return;
    _feedbackSent = true;
    widget.onFeedback?.call();
    if (!_reduced) unawaited(_press.forward());
  }

  void _cancel() {
    if (_busy) return;
    _feedbackSent = false;
    unawaited(_press.reverse());
  }

  Future<void> _activate() async {
    if (_busy || widget.onPressed == null) return;
    _busy = true;
    try {
      if (!_feedbackSent) widget.onFeedback?.call();
      if (!_reduced) {
        await _press.forward().orCancel;
        await _press
            .animateBack(
              0,
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOutBack,
            )
            .orCancel;
      }
      if (mounted) await widget.onPressed?.call();
    } on TickerCanceled {
      // Closing the parent route may dispose a button while it springs back.
    } finally {
      _busy = false;
      _feedbackSent = false;
    }
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: widget.label,
    button: widget.toggled == null,
    toggled: widget.toggled,
    enabled: widget.onPressed != null,
    onTap: widget.onPressed == null ? null : _activate,
    excludeSemantics: true,
    child: FocusableActionDetector(
      enabled: widget.onPressed != null,
      mouseCursor: widget.onPressed == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      onShowFocusHighlight: (value) => setState(() => _focused = value),
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            unawaited(_activate());
            return null;
          },
        ),
      },
      child: MouseRegion(
        onEnter: (_) {
          if (widget.onPressed == null) return;
          if (!_hovered) setState(() => _hovered = true);
        },
        onExit: (_) {
          if (widget.onPressed == null) return;
          if (_hovered) setState(() => _hovered = false);
        },
        child: Listener(
          onPointerDown: widget.onPressed == null ? null : (_) => _down(),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapCancel: _cancel,
            onTap: widget.onPressed == null ? null : _activate,
            child: AnimatedBuilder(
              animation: _press,
              builder: (context, _) {
                final amount = _reduced ? 0.0 : _press.value;
                final hoverScale =
                    widget.onPressed == null || _reduced || !_hovered
                        ? 0.0
                        : .018;
                return Transform.translate(
                  offset: Offset(0, amount * 3.5),
                  child: Transform.scale(
                    key: const ValueKey('juicy-press-transform'),
                    scaleX: (1 + hoverScale) - amount * .025,
                    scaleY: (1 + hoverScale) - amount * .075,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        border: _focused
                            ? Border.all(color: const Color(0xFF2466A7), width: 3)
                            : null,
                      ),
                      child: widget.builder(context, amount),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
}
