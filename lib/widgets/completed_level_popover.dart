import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'home_art.dart';
import 'illustrated_action_button.dart';
import 'juicy_press.dart';
import 'map_art.dart';
import 'ui_surface_art.dart';

/// A map-anchored review; false closes it and true requests a fresh practice run.
class CompletedLevelRoute extends RawDialogRoute<bool> {
  CompletedLevelRoute({required Offset anchor})
    : super(
        barrierDismissible: true,
        barrierColor: Colors.transparent,
        barrierLabel: 'Cerrar resumen del nivel',
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (context, _, _) => LayoutBuilder(
          builder: (context, bounds) {
            final safe = MediaQuery.paddingOf(context);
            final width = math.min(440.0, bounds.maxWidth - 24);
            final left = (anchor.dx - width / 2).clamp(
              12.0,
              bounds.maxWidth - width - 12,
            );
            final top = safe.top + (bounds.maxHeight < 500 ? 12 : 78);
            final bottom = anchor.dy.clamp(
              top + 120,
              bounds.maxHeight - safe.bottom - 12,
            );
            return Stack(
              children: [
                Positioned(
                  left: left,
                  bottom: bounds.maxHeight - bottom,
                  width: width,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: bottom - top),
                    child: _CompletedLevelCard(pointerX: anchor.dx - left),
                  ),
                ),
              ],
            );
          },
        ),
        transitionBuilder: (context, animation, _, child) {
          final reduced = MediaQuery.disableAnimationsOf(context);
          final progress = reduced
              ? 1.0
              : Curves.easeOutCubic.transform(animation.value);
          return IgnorePointer(
            ignoring: animation.status != AnimationStatus.completed,
            child: Opacity(
              key: const ValueKey('level-summary-fade'),
              opacity: progress,
              child: Transform.translate(
                key: const ValueKey('level-summary-slide'),
                offset: Offset(0, 24 * (1 - progress)),
                child: child,
              ),
            ),
          );
        },
      );

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 250);
}

class _CompletedLevelCard extends StatelessWidget {
  const _CompletedLevelCard({required this.pointerX});
  final double pointerX;

  @override
  Widget build(BuildContext context) => Material(
    type: MaterialType.transparency,
    child: LayoutBuilder(
      builder: (context, bounds) => Stack(
        key: const ValueKey('level-summary'),
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: pointerX.clamp(28.0, bounds.maxWidth - 28) - 16,
            bottom: 0,
            child: const CustomPaint(
              size: Size(32, 26),
              painter: _CardPointer(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: UiSurfacePanel(
              surface: UiSurface.creamPanel,
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '¡Lo hiciste muy bien!',
                            style: homeText(25),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              MapIcon(MapGlyph.goldStar, size: 32),
                              SizedBox(width: 8),
                              MapIcon(MapGlyph.goldStar, size: 38),
                              SizedBox(width: 8),
                              MapIcon(MapGlyph.goldStar, size: 32),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Completaste los 3 sudokus de práctica.\n¡Ya conoces las reglas básicas!\nPuedes volver a jugar cuando quieras.',
                            style: homeText(17, weight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: IllustratedActionButton(
                          key: const ValueKey('level-replay'),
                          label: 'Volver a jugar',
                          compact: true,
                          fontSize: 19,
                          showPlayIcon: false,
                          onPressed: () => Navigator.of(context).pop(true),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: JuicyPress(
                            key: const ValueKey('level-summary-ok'),
                            label: 'OK',
                            onPressed: () => Navigator.of(context).pop(false),
                            builder: (_, _) => Stack(
                              fit: StackFit.expand,
                              children: [
                                const UiSurfaceArt(UiSurface.creamPill),
                                Center(child: Text('OK', style: homeText(21))),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Only the pointer is new artwork; the panel and buttons reuse shared skins.
class _CardPointer extends CustomPainter {
  const _CardPointer();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height - 1)
      ..lineTo(size.width, 0);
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF6DF), Color(0xFFFFE9BC)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFE9BF70)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_CardPointer oldDelegate) => false;
}
