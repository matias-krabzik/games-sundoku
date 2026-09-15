import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/models/game_save.dart';
import '../domain/models/game_session.dart';
import 'game_pause.dart';
import 'home_art.dart';
import 'illustrated_action_button.dart';
import 'juicy_press.dart';
import 'map_art.dart';
import 'score_feedback.dart';
import 'ui_surface_art.dart';

/// Shows one consistent level summary for new, resumable and finished levels.
class LevelSummaryRoute extends RawDialogRoute<bool> {
  LevelSummaryRoute({
    required int level,
    required int lights,
    required GameSession? session,
    required LevelRecord record,
  }) : super(
         barrierDismissible: true,
         barrierColor: const Color(0x99072346),
         barrierLabel: 'Cerrar resumen del nivel',
         transitionDuration: const Duration(milliseconds: 350),
         pageBuilder: (context, _, _) => SafeArea(
           minimum: const EdgeInsets.all(12),
           child: Center(
             child: LevelSummaryCard(
               level: level,
               lights: lights,
               session: session,
               record: record,
               onContinue: () => Navigator.of(context).pop(true),
               onOk: () => Navigator.of(context).pop(false),
             ),
           ),
         ),
         transitionBuilder: (context, animation, _, child) {
           final reduced = MediaQuery.disableAnimationsOf(context);
           final progress = reduced
               ? 1.0
               : Curves.easeOutBack.transform(animation.value);
           return IgnorePointer(
             ignoring: animation.status != AnimationStatus.completed,
             child: Opacity(
               key: const ValueKey('level-summary-fade'),
               opacity: animation.value,
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

class LevelSummaryCard extends StatelessWidget {
  const LevelSummaryCard({
    required this.level,
    required this.lights,
    required this.session,
    required this.record,
    required this.onContinue,
    required this.onOk,
    super.key,
  });

  final int level;
  final int lights;
  final GameSession? session;
  final LevelRecord record;
  final VoidCallback onContinue;
  final VoidCallback onOk;

  bool get _isPracticeComplete => level == 1 && lights >= 3;
  bool get _isComplete =>
      _isPracticeComplete || (session?.canResume != true && lights >= 3);

  List<_RoundSummary> get _rounds {
    final puzzles = session?.puzzles;
    if (puzzles == null) {
      return List.generate(
        3,
        (index) => _RoundSummary(
          state: index < lights ? _RoundState.completed : _RoundState.pending,
        ),
      );
    }

    var currentAssigned = false;
    return List.generate(3, (index) {
      if (index >= puzzles.length) {
        return const _RoundSummary(state: _RoundState.pending);
      }
      final puzzle = puzzles[index];
      if (puzzle.status == PlayStatus.completed) {
        return _RoundSummary(
          state: _RoundState.completed,
          points: puzzle.points,
          elapsedMs: puzzle.elapsedMs,
        );
      }
      if (!currentAssigned && session!.canResume) {
        currentAssigned = true;
        return _RoundSummary(
          state: _RoundState.current,
          points: puzzle.points,
          elapsedMs: puzzle.elapsedMs,
        );
      }
      return const _RoundSummary(state: _RoundState.pending);
    });
  }

  int get _completedRounds =>
      _rounds.where((round) => round.state == _RoundState.completed).length;

  int get _totalPoints => session?.points ?? record.bestPoints;
  int get _totalElapsedMs => session?.elapsedMs ?? record.bestElapsedMs ?? 0;

  @override
  Widget build(BuildContext context) => Material(
    type: MaterialType.transparency,
    child: LayoutBuilder(
      builder: (context, bounds) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        if (_isPracticeComplete) {
          final width = math.min(440.0, bounds.maxWidth);
          final height = math.min(
            340.0 + (textScale - 1).clamp(0.0, 1.0) * 100,
            bounds.maxHeight,
          );
          final dense = bounds.maxWidth < 360 || bounds.maxHeight < 420;
          return SizedBox(
            key: const ValueKey('level-summary'),
            width: width,
            height: height,
            child: UiSurfacePanel(
              surface: UiSurface.goldCreamPanel,
              padding: EdgeInsets.all(dense ? 14 : 18),
              child: _practiceSummary(dense: dense),
            ),
          );
        }

        final wide = bounds.maxWidth > 680 && bounds.maxHeight < 580;
        final width = math.min(wide ? 720.0 : 540.0, bounds.maxWidth);
        final preferredHeight = wide ? 360.0 : 690.0;
        final height = math.min(preferredHeight, bounds.maxHeight);
        final dense = bounds.maxHeight < (wide ? 340 : 610);
        final padding = dense ? 14.0 : 22.0;
        final card = UiSurfacePanel(
          surface: UiSurface.goldCreamPanel,
          padding: EdgeInsets.fromLTRB(padding, padding, padding, padding - 2),
          child: wide
              ? Row(
                  children: [
                    Expanded(flex: 4, child: _heading(dense: dense)),
                    const SizedBox(width: 22),
                    Expanded(flex: 6, child: _details(dense: dense)),
                  ],
                )
              : Column(
                  children: [
                    Expanded(flex: 42, child: _heading(dense: dense)),
                    SizedBox(height: dense ? 7 : 12),
                    Expanded(flex: 58, child: _details(dense: dense)),
                  ],
                ),
        );
        return SizedBox(
          key: const ValueKey('level-summary'),
          width: width,
          height: height,
          child: card,
        );
      },
    ),
  );

  Widget _practiceSummary({required bool dense}) => Column(
    children: [
      Flexible(
        flex: 2,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '¡Lo hiciste muy bien!',
            style: homeText(dense ? 22 : 25),
          ),
        ),
      ),
      SizedBox(height: dense ? 5 : 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          3,
          (_) => Padding(
            padding: EdgeInsets.symmetric(horizontal: dense ? 3 : 5),
            child: MapIcon(MapGlyph.goldStar, size: dense ? 31 : 38),
          ),
        ),
      ),
      SizedBox(height: dense ? 5 : 9),
      Expanded(
        flex: 4,
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'Completaste las 3 rondas de práctica.\n'
              '¡Ya conoces las reglas básicas!\n'
              'Puedes volver a jugar cuando quieras.',
              style: homeText(dense ? 16 : 18, weight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      SizedBox(height: dense ? 5 : 8),
      _SummaryActions(
        primaryKey: const ValueKey('level-replay'),
        primaryLabel: 'Volver a jugar',
        primaryFontSize: dense ? 17 : 20,
        onPrimary: onContinue,
        onOk: onOk,
        dense: dense,
      ),
    ],
  );

  Widget _heading({required bool dense}) => Column(
    children: [
      _fitText(
        'MUNDO 1',
        homeText(dense ? 12 : 14).copyWith(color: const Color(0xFFAC691C)),
      ),
      _fitText('Valle del Sol', homeText(dense ? 22 : 27)),
      SizedBox(height: dense ? 2 : 6),
      _fitText('Nivel $level', homeText(dense ? 27 : 34)),
      _fitText(
        _isPracticeComplete
            ? '¡Lo hiciste muy bien!'
            : _isComplete
            ? '¡Completado!'
            : 'En progreso',
        homeText(dense ? 16 : 20).copyWith(
          color: _isComplete
              ? const Color(0xFF2C873E)
              : const Color(0xFF9A630B),
        ),
      ),
      SizedBox(height: dense ? 3 : 7),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          final earned = index < lights;
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: dense ? 2 : 4),
            child: MapIcon(
              earned ? MapGlyph.goldStar : MapGlyph.emptyStar,
              size: dense ? 28 : 37,
            ),
          );
        }),
      ),
      SizedBox(height: dense ? 2 : 6),
      _fitText(
        _isPracticeComplete
            ? 'Práctica completada'
            : '$_completedRounds de 3 rondas completadas',
        homeText(dense ? 13 : 16, weight: FontWeight.w600),
      ),
    ],
  );

  Widget _details({required bool dense}) => Column(
    children: [
      Expanded(
        child: _ResultsTable(
          rounds: _rounds,
          totalPoints: _totalPoints,
          totalElapsedMs: _totalElapsedMs,
          complete: _isComplete,
          dense: dense,
        ),
      ),
      SizedBox(height: dense ? 4 : 8),
      Text(
        _footer,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: homeText(dense ? 14 : 17),
        textAlign: TextAlign.center,
      ),
      SizedBox(height: dense ? 5 : 10),
      _SummaryActions(
        primaryKey: _isComplete
            ? null
            : const ValueKey('level-summary-continue'),
        primaryLabel: _isComplete ? null : 'Continuar',
        primaryFontSize: dense ? 17 : 20,
        onPrimary: onContinue,
        onOk: onOk,
        dense: dense,
      ),
    ],
  );

  String get _footer {
    if (_isComplete) return '¡Ganaste las 3 estrellas!';
    if (session == null) return 'Todo está listo para comenzar.';
    return 'Sigue desde donde lo dejaste.';
  }

  Widget _fitText(String text, TextStyle style) => Expanded(
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(text, style: style, textAlign: TextAlign.center),
    ),
  );
}

class _SummaryActions extends StatelessWidget {
  const _SummaryActions({
    required this.primaryKey,
    required this.primaryLabel,
    required this.primaryFontSize,
    required this.onPrimary,
    required this.onOk,
    required this.dense,
  });

  final Key? primaryKey;
  final String? primaryLabel;
  final double primaryFontSize;
  final VoidCallback onPrimary;
  final VoidCallback onOk;
  final bool dense;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: dense ? 70 : 74,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (primaryLabel != null)
          Expanded(
            child: Align(
              alignment: Alignment.center,
              child: IllustratedActionButton(
                key: primaryKey,
                label: primaryLabel!,
                compact: true,
                fontSize: primaryFontSize,
                showPlayIcon: true,
                onPressed: onPrimary,
              ),
            ),
          )
        else
          const Spacer(),
        SizedBox(width: dense ? 6 : 10),
        SizedBox(
          width: dense ? 84 : 92,
          child: _SmallOkButton(dense: dense, onPressed: onOk),
        ),
      ],
    ),
  );
}

class _SmallOkButton extends StatelessWidget {
  const _SmallOkButton({required this.dense, required this.onPressed});

  final bool dense;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    key: const ValueKey('level-summary-ok-frame'),
    height: dense ? 60 : 64,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: JuicyPress(
        key: const ValueKey('level-summary-ok'),
        label: 'Ok',
        onPressed: onPressed,
        builder: (_, _) => Stack(
          fit: StackFit.expand,
          children: [
            const UiSurfaceArt(UiSurface.creamPill),
            Center(child: Text('Ok', style: homeText(dense ? 17 : 20))),
          ],
        ),
      ),
    ),
  );
}

enum _RoundState { completed, current, pending }

class _RoundSummary {
  const _RoundSummary({required this.state, this.points, this.elapsedMs});

  final _RoundState state;
  final int? points;
  final int? elapsedMs;
}

class _ResultsTable extends StatelessWidget {
  const _ResultsTable({
    required this.rounds,
    required this.totalPoints,
    required this.totalElapsedMs,
    required this.complete,
    required this.dense,
  });

  final List<_RoundSummary> rounds;
  final int totalPoints;
  final int totalElapsedMs;
  final bool complete;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    const border = Color(0xFFE9C77F);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xCFFFF9E8),
        border: Border.all(color: border, width: 1.3),
        borderRadius: BorderRadius.circular(17),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Expanded(
              child: _row(
                color: const Color(0xFFFFEAB2),
                cells: const [
                  _TableCell('Ronda', flex: 5),
                  _TableCell('Puntos', flex: 3),
                  _TableCell('Tiempo', flex: 3),
                ],
                header: true,
              ),
            ),
            for (var i = 0; i < rounds.length; i++) ...[
              const Divider(height: 1, thickness: 1, color: border),
              Expanded(child: _roundRow(i, rounds[i])),
            ],
            const Divider(height: 1, thickness: 1.3, color: border),
            Expanded(
              child: _row(
                color: const Color(0xFFFFE39A),
                cells: [
                  _TableCell(complete ? 'Total' : 'Total actual', flex: 5),
                  _TableCell(formatScore(totalPoints), flex: 3),
                  _TableCell(formatPlayTime(totalElapsedMs), flex: 3),
                ],
                strong: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roundRow(int index, _RoundSummary round) {
    final status = switch (round.state) {
      _RoundState.completed => '✓ Completada',
      _RoundState.current => 'En curso',
      _RoundState.pending => 'Pendiente',
    };
    return _row(
      color: round.state == _RoundState.current
          ? const Color(0xFFFFF0BF)
          : const Color(0x00FFFFFF),
      cells: [
        _TableCell(
          '${index + 1}  $status',
          flex: 5,
          color: round.state == _RoundState.completed
              ? const Color(0xFF27883E)
              : round.state == _RoundState.current
              ? const Color(0xFF9A630B)
              : const Color(0xFF766A56),
        ),
        _TableCell(
          round.points == null ? '—' : formatScore(round.points!),
          flex: 3,
        ),
        _TableCell(
          round.elapsedMs == null ? '—' : formatPlayTime(round.elapsedMs!),
          flex: 3,
        ),
      ],
    );
  }

  Widget _row({
    required Color color,
    required List<_TableCell> cells,
    bool header = false,
    bool strong = false,
  }) => ColoredBox(
    color: color,
    child: Row(
      children: [
        for (final cell in cells)
          Expanded(
            flex: cell.flex,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: dense ? 4 : 8),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: cell.flex == 5
                    ? Alignment.centerLeft
                    : Alignment.center,
                child: Text(
                  cell.text,
                  maxLines: 1,
                  style:
                      homeText(
                        dense ? 13 : 16,
                        weight: header || strong
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ).copyWith(
                        color: cell.color,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class _TableCell {
  const _TableCell(this.text, {required this.flex, this.color});

  final String text;
  final int flex;
  final Color? color;
}
