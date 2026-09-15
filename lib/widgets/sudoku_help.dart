import 'package:flutter/material.dart';

import '../domain/help/sudoku_help.dart';
import 'game_feedback_scope.dart';
import 'game_layout.dart';
import 'home_art.dart';
import 'juicy_press.dart';
import 'ui_surface_art.dart';

class SudokuHelpButton extends StatelessWidget {
  const SudokuHelpButton({
    super.key,
    required this.onPressed,
    this.active = false,
  });

  final VoidCallback? onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: GameLayout.controlSize - 2,
    child: Semantics(
      selected: active,
      child: JuicyPress(
        label: active ? 'Cerrar ayuda' : 'Ayuda para esta casilla: −77 puntos',
        onPressed: onPressed,
        onFeedback: () => GameFeedbackScope.tap(context),
        builder: (_, _) => Stack(
          fit: StackFit.expand,
          children: [
            UiSurfaceArt(active ? UiSurface.goldTile : UiSurface.creamTile),
            Center(
              child: Opacity(
                opacity: onPressed == null ? .4 : 1,
                child: const SizedBox.square(
                  dimension: 29,
                  child: CustomPaint(painter: _HelpBulbPainter()),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _HelpBulbPainter extends CustomPainter {
  const _HelpBulbPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 32, size.height / 32);
    final bulb = Path()
      ..moveTo(12, 23)
      ..lineTo(12, 21)
      ..cubicTo(12, 18, 7, 17, 7, 12)
      ..cubicTo(7, 1, 25, 1, 25, 12)
      ..cubicTo(25, 17, 20, 18, 20, 21)
      ..lineTo(20, 23)
      ..close();
    canvas.drawPath(
      bulb,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF7BA), Color(0xFFFFD127), Color(0xFFE7A51D)],
        ).createShader(const Rect.fromLTWH(7, 3, 18, 20)),
    );
    final outline = Paint()
      ..color = homeNavy
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(bulb, outline);
    canvas.drawLine(const Offset(12, 26), const Offset(20, 26), outline);
    canvas.drawLine(const Offset(14, 29), const Offset(18, 29), outline);
    canvas.drawLine(const Offset(2, 12), const Offset(4, 12), outline);
    canvas.drawLine(const Offset(28, 12), const Offset(30, 12), outline);
    canvas.drawLine(const Offset(4, 3), const Offset(6, 5), outline);
    canvas.drawLine(const Offset(26, 5), const Offset(28, 3), outline);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_HelpBulbPainter oldDelegate) => false;
}

class SudokuHelpCard extends StatefulWidget {
  const SudokuHelpCard({super.key, required this.tip});

  final SudokuHelpTip tip;

  @override
  State<SudokuHelpCard> createState() => _SudokuHelpCardState();
}

class _SudokuHelpCardState extends State<SudokuHelpCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final reduced =
          MediaQuery.disableAnimationsOf(context) ||
          MediaQuery.accessibleNavigationOf(context);
      Scrollable.ensureVisible(
        context,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        duration: reduced ? Duration.zero : const Duration(milliseconds: 180),
      );
    });
  }

  @override
  Widget build(BuildContext context) => UiSurfacePanel(
    surface: UiSurface.goldCreamPanel,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Center(
        child: Semantics(
          liveRegion: true,
          child: Text(
            widget.tip.message,
            textAlign: TextAlign.center,
            style: homeText(18),
          ),
        ),
      ),
    ),
  );
}

/// Focus geometry comes from the board so gaps and responsive sizes agree.
class SudokuHelpSpotlight extends StatefulWidget {
  const SudokuHelpSpotlight({super.key, required this.areas});
  final List<Rect> areas;

  @override
  State<SudokuHelpSpotlight> createState() => _SudokuHelpSpotlightState();
}

class _SudokuHelpSpotlightState extends State<SudokuHelpSpotlight> {
  List<Rect> _lastAreas = const [];

  @override
  Widget build(BuildContext context) {
    if (widget.areas.isNotEmpty) _lastAreas = widget.areas;
    final reduced =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    return IgnorePointer(
      child: ExcludeSemantics(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: widget.areas.isEmpty ? 0 : 1),
          duration: reduced ? Duration.zero : const Duration(milliseconds: 180),
          builder: (context, amount, _) =>
              CustomPaint(painter: _SpotlightPainter(_lastAreas, amount)),
        ),
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  const _SpotlightPainter(this.areas, this.amount);
  final List<Rect> areas;
  final double amount;

  @override
  void paint(Canvas canvas, Size size) {
    if (amount == 0 || areas.isEmpty) return;
    var focus = Path();
    for (final area in areas) {
      focus = Path.combine(
        PathOperation.union,
        focus,
        Path()
          ..addRRect(RRect.fromRectAndRadius(area, const Radius.circular(4))),
      );
    }
    final dim = Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      focus,
    );
    canvas.drawPath(
      dim,
      Paint()..color = const Color(0xFF51472D).withValues(alpha: .46 * amount),
    );
    canvas.drawPath(
      focus,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFFFFBE18).withValues(alpha: amount),
    );
  }

  @override
  bool shouldRepaint(_SpotlightPainter oldDelegate) =>
      areas != oldDelegate.areas || amount != oldDelegate.amount;
}
