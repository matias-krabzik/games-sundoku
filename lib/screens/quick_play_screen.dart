import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../routes.dart';

import '../data/repositories/game_repository.dart';
import '../domain/models/quick_play_difficulty.dart';
import '../widgets/game_feedback_scope.dart';
import '../widgets/game_navigation_header.dart';
import '../widgets/home_art.dart';
import '../widgets/illustrated_action_button.dart';
import '../widgets/juicy_press.dart';
import '../widgets/parallax_background.dart';
import '../widgets/ui_surface_art.dart';
import '../widgets/world_journey_route.dart';
import 'first_experience_screen.dart';
import 'settings_screen.dart';

class QuickPlayScreen extends StatefulWidget {
  const QuickPlayScreen({super.key, required this.repository});
  final GameRepository repository;

  @override
  State<QuickPlayScreen> createState() => _QuickPlayScreenState();
}

class _QuickPlayScreenState extends State<QuickPlayScreen> {
  QuickPlayDifficulty _selected = QuickPlayDifficulty.normal;
  bool _opening = false;
  String? _error;

  QuickPlayDifficulty? get _pendingDifficulty {
    final pending = widget.repository.pendingQuickGame;
    if (pending == null) return null;
    final name = widget
        .repository
        .state
        .puzzles[pending.puzzles.single.puzzleId]!
        .difficulty;
    return QuickPlayDifficulty.values.byName(name);
  }

  String get _replacementWarning {
    final state = widget.repository.state;
    final pending = state.sessions.values
        .where(
          (session) =>
              session.canResume &&
              state.levels[session.levelId]?.worldId == 'quick-play',
        )
        .toList();
    final points = pending.fold(0, (sum, session) => sum + session.points);
    final subject = pending.length > 1
        ? 'las ${pending.length} partidas rápidas pendientes'
        : 'la partida rápida pendiente';
    return 'Perderás $subject y sus $points puntos. La nueva partida será de dificultad ${_selected.label}.';
  }

  @override
  void initState() {
    super.initState();
    _selected = _pendingDifficulty ?? QuickPlayDifficulty.normal;
  }

  Future<bool> _confirmReplacement() async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: UiSurfacePanel(
            surface: UiSurface.goldCreamPanel,
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '¿Empezar otra partida?',
                    textAlign: TextAlign.center,
                    style: homeText(24),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _replacementWarning,
                    textAlign: TextAlign.center,
                    style: homeText(18, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 20),
                  IllustratedActionButton(
                    key: const ValueKey('quick-replace-confirm'),
                    label: 'Empezar otra',
                    compact: true,
                    onPressed: () => Navigator.pop(context, true),
                  ),
                  TextButton(
                    key: const ValueKey('quick-replace-cancel'),
                    onPressed: () => Navigator.pop(context, false),
                    child: Text('Cancelar', style: homeText(18)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ) ??
      false;

  Future<void> _play({bool newGame = false}) async {
    if (_opening) return;
    setState(() {
      _opening = true;
      _error = null;
    });
    try {
      final replacing =
          _pendingDifficulty != null &&
          (newGame || _pendingDifficulty != _selected);
      if (replacing && !await _confirmReplacement()) return;
      await widget.repository.startQuickPlay(
        _selected,
        replacePending: replacing,
      );
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        WorldJourneyRoute(
          settings: const RouteSettings(name: AppRoutes.game),
          reduceMotion: MediaQuery.disableAnimationsOf(context),
          builder: (_) => FirstExperienceScreen(
            repository: widget.repository,
            quickPlayDifficulty: _selected,
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'No pudimos abrir la partida. Intenta de nuevo.',
        );
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) => TickerMode(
    enabled: ModalRoute.of(context)?.isCurrent ?? true,
    child: Scaffold(
      body: ParallaxBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, bounds) {
              final large = bounds.maxWidth >= 700 || bounds.maxHeight >= 900;
              final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
              final rowHeight = math.max(90.0, 40 + 44 * textScale);
              final contentHeight = rowHeight * 5 + 4 * 8 + 50;
              final dokuHeight =
                  (bounds.maxHeight -
                          contentHeight -
                          166 -
                          (_pendingDifficulty != null ? 132 : 0))
                      .clamp(0.0, 170.0);
              return Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      large ? 32 : 16,
                      large ? 24 : 8,
                      large ? 32 : 16,
                      8,
                    ),
                    child: GameNavigationHeader(
                      backLabel: 'Volver al inicio',
                      onBack: _opening
                          ? null
                          : () => Navigator.of(context).maybePop(),
                      onSettings: _opening
                          ? null
                          : () => Navigator.of(context).push(
                              SettingsRoute(repository: widget.repository),
                            ),
                      center: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: UiSurfacePanel(
                          surface: UiSurface.goldCreamPanel,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 16,
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Partida rápida',
                              maxLines: 1,
                              style: homeText(24),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: LayoutBuilder(
                          builder: (context, body) => SingleChildScrollView(
                            key: const ValueKey('quick-play-scroll'),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: body.maxHeight,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (dokuHeight >= 65)
                                    Image.asset(
                                      'assets/images/doku-home.png',
                                      height: dokuHeight,
                                      fit: BoxFit.contain,
                                      excludeFromSemantics: true,
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    child: Text(
                                      'Elige la dificultad',
                                      textAlign: TextAlign.center,
                                      style: homeText(26),
                                    ),
                                  ),
                                  if (_pendingDifficulty != null)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: Text(
                                        'Partida pendiente: ${_pendingDifficulty!.label}. Puedes continuarla o elegir otra.',
                                        textAlign: TextAlign.center,
                                        style: homeText(16),
                                      ),
                                    ),
                                  for (final difficulty
                                      in QuickPlayDifficulty.values)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: _DifficultyCard(
                                        difficulty: difficulty,
                                        selected: difficulty == _selected,
                                        height: rowHeight,
                                        onPressed: _opening
                                            ? null
                                            : () => setState(() {
                                                _selected = difficulty;
                                                _error = null;
                                              }),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: homeText(16),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 14),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListenableBuilder(
                          listenable: widget.repository,
                          builder: (context, _) => IllustratedActionButton(
                            key: const ValueKey('quick-play-start'),
                            label: _opening
                                ? 'Preparando…'
                                : _pendingDifficulty == _selected
                                ? 'Continuar'
                                : 'Jugar',
                            onPressed: _opening ? null : () => _play(),
                          ),
                        ),
                        if (_pendingDifficulty == _selected) ...[
                          const SizedBox(height: 8),
                          IllustratedActionButton(
                            key: const ValueKey('quick-play-new'),
                            label: 'Nueva partida',
                            secondary: true,
                            fontSize: 22,
                            leadingIcon: const Icon(
                              Icons.refresh_rounded,
                              color: Color(0xFFFFF3D3),
                              size: 26,
                            ),
                            onPressed: _opening
                                ? null
                                : () => _play(newGame: true),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );
}

class _DifficultyCard extends StatelessWidget {
  const _DifficultyCard({
    required this.difficulty,
    required this.selected,
    required this.height,
    required this.onPressed,
  });
  final QuickPlayDifficulty difficulty;
  final bool selected;
  final double height;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    inMutuallyExclusiveGroup: true,
    child: JuicyPress(
      key: ValueKey('quick-difficulty-${difficulty.name}'),
      label: '${difficulty.label}. ${difficulty.description}',
      onFeedback: () => GameFeedbackScope.tap(context),
      onPressed: onPressed,
      builder: (_, _) => SizedBox(
        height: height,
        child: UiSurfacePanel(
          surface: selected ? UiSurface.goldButton : UiSurface.creamPanel,
          padding: const EdgeInsets.fromLTRB(28, 18, 28, 20),
          child: Row(
            children: [
              SizedBox(
                width: 54,
                height: 50,
                child: Image.asset(
                  'assets/images/quick-play/${difficulty.name}.png',
                  fit: BoxFit.contain,
                  excludeFromSemantics: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        difficulty.label,
                        maxLines: 1,
                        style: homeText(25),
                      ),
                    ),
                    const SizedBox(height: 3),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        difficulty.description,
                        maxLines: 1,
                        style: homeText(15, weight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 27,
                height: 27,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? homeNavy : const Color(0xFFFFF5DE),
                  border: Border.all(color: const Color(0xFFD7A953), width: 2),
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 19,
                        color: Colors.white,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
