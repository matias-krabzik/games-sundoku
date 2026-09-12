import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import 'home_art.dart';
import 'ui_surface_art.dart';

/// Static story segments. [index] is zero based; time never advances a story.
class TutorialStoryProgress extends StatelessWidget {
  const TutorialStoryProgress({
    super.key,
    required this.index,
    required this.count,
  }) : assert(count > 0),
       assert(index >= 0 && index < count);

  final int index;
  final int count;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: 'Historia ${index + 1} de $count',
    excludeSemantics: true,
    child: SizedBox(
      height: 12,
      child: Row(
        children: [
          for (var segment = 0; segment < count; segment++) ...[
            if (segment > 0) const SizedBox(width: 5),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: segment == index
                      ? Border.all(color: homeNavy, width: 1.5)
                      : null,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: UiSurfaceArt(
                    segment <= index
                        ? UiSurface.progressFill
                        : UiSurface.progressTrack,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

/// Local story navigation that leaves child controls and vertical scroll free.
class TutorialStoryGestures extends StatefulWidget {
  const TutorialStoryGestures({
    super.key,
    required this.child,
    required this.onNext,
    this.onPrevious,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final bool enabled;

  @override
  State<TutorialStoryGestures> createState() => _TutorialStoryGesturesState();
}

class _TutorialStoryGesturesState extends State<TutorialStoryGestures> {
  static const _previousAction = CustomSemanticsAction(
    label: 'Historia anterior',
  );
  static const _nextAction = CustomSemanticsAction(label: 'Historia siguiente');
  static const _swipeDistance = 56.0;
  Offset? _dragStart;
  Offset? _dragPosition;
  bool _showFocus = false;
  late final _focusNode = FocusNode(
    debugLabel: 'Tutorial story navigation',
    onKeyEvent: _keyEvent,
  );

  bool get _active =>
      widget.enabled && (widget.onNext != null || widget.onPrevious != null);

  void _navigate(bool forward) {
    if (!_active) return;
    (forward ? widget.onNext : widget.onPrevious)?.call();
  }

  KeyEventResult _keyEvent(FocusNode node, KeyEvent event) {
    // A focused child keeps its own activation, selection and editing keys.
    if (!_active || !node.hasPrimaryFocus || event is KeyUpEvent) {
      return KeyEventResult.ignored;
    }
    final keyboard = HardwareKeyboard.instance;
    if (keyboard.isControlPressed ||
        keyboard.isAltPressed ||
        keyboard.isMetaPressed ||
        keyboard.isShiftPressed) {
      return KeyEventResult.ignored;
    }
    final forward = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowRight || LogicalKeyboardKey.space => true,
      LogicalKeyboardKey.arrowLeft => false,
      _ => null,
    };
    if (forward == null ||
        (forward ? widget.onNext : widget.onPrevious) == null) {
      return KeyEventResult.ignored;
    }
    if (event is KeyDownEvent) _navigate(forward);
    return KeyEventResult.handled;
  }

  void _tap(TapUpDetails details) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    _navigate(details.localPosition.dx >= box.size.width * .28);
  }

  void _endSwipe(DragEndDetails details) {
    final start = _dragStart;
    final position = _dragPosition;
    _dragStart = _dragPosition = null;
    if (start == null || position == null) return;
    final travel = position - start;
    if (travel.dx.abs() >= _swipeDistance &&
        travel.dx.abs() > travel.dy.abs() * 1.3) {
      _navigate(travel.dx < 0);
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    explicitChildNodes: true,
    label: 'Navegación de la historia',
    customSemanticsActions: {
      if (_active && widget.onPrevious != null)
        _previousAction: () => _navigate(false),
      if (_active && widget.onNext != null) _nextAction: () => _navigate(true),
    },
    child: FocusableActionDetector(
      enabled: _active,
      focusNode: _focusNode,
      autofocus: true,
      includeFocusSemantics: false,
      onShowFocusHighlight: (value) => setState(() => _showFocus = value),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        dragStartBehavior: DragStartBehavior.down,
        onTapUp: _active ? _tap : null,
        onHorizontalDragStart: _active
            ? (details) {
                _dragStart = _dragPosition = details.globalPosition;
              }
            : null,
        onHorizontalDragUpdate: _active
            ? (details) => _dragPosition = details.globalPosition
            : null,
        onHorizontalDragEnd: _active ? _endSwipe : null,
        onHorizontalDragCancel: _active
            ? () => _dragStart = _dragPosition = null
            : null,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: _showFocus && _active
                ? Border.all(color: homeNavy, width: 2)
                : null,
          ),
          child: widget.child,
        ),
      ),
    ),
  );
}
