import 'dart:math' as math;

import '../models/game_session.dart';
import '../models/json_data.dart';
import '../models/sudoku_definition.dart';
import 'sudoku_scoring.dart';

enum ChallengeOutcome {
  inProgress,
  won,
  outOfLives,
  outOfTime,
  mistakesNotAllowed,
  hintsNotAllowed,
  belowTarget,
}

enum ChallengeTimePolicy { activeTimeLimit }

/// Pure rule selection. Session activation and persistence belong to W3-02.
abstract final class AdventureChallenges {
  static const version = 'world3-challenge-v1';
  static const basis = 10000;
  static const preparationMs = 120000;
  static const perEmptyCellMs = 30000;

  static int targetBasisPoints(int level) {
    RangeError.checkValueInInterval(level, 1, 30, 'level');
    if (level <= 10) return 8500 + (level - 1) * 100;
    if (level <= 20) return 9450 + (level - 11) * 50;
    if (level <= 29) return 9910 + (level - 21) * 10;
    return basis;
  }

  /// Other worlds and quick play retain their existing, unrestricted rules.
  static RoundChallengeRules? forPuzzle({
    required String worldId,
    required int level,
    required SudokuDefinition puzzle,
  }) {
    if (worldId != 'world-3') return null;
    final proportion = targetBasisPoints(level);
    if (!puzzle.id.startsWith('$worldId/level-$level/')) {
      throw ArgumentError.value(puzzle.id, 'puzzle', 'Wrong world or level');
    }
    final perfect = SudokuScoring.perfectScore(puzzle);
    final target = (perfect * proportion + basis - 1) ~/ basis;
    return RoundChallengeRules._(
      version: version,
      scoringVersion: SudokuScoring.version,
      worldId: worldId,
      level: level,
      puzzleId: puzzle.id,
      initialLives: level <= 10
          ? 3
          : level <= 20
          ? 2
          : 1,
      perfectPoints: perfect,
      targetPoints: level == 30 ? perfect : math.min(perfect - 1, target),
      targetBasisPoints: proportion,
      timeLimitMs:
          preparationMs +
          puzzle.initial.where((value) => value == null).length *
              perEmptyCellMs,
      requiresNoMistakes: level == 30,
      allowsHints: level != 30,
    );
  }
}

/// Immutable values to freeze for one attempt; never recalculated from its moves.
class RoundChallengeRules {
  const RoundChallengeRules._({
    required this.version,
    required this.scoringVersion,
    required this.worldId,
    required this.level,
    required this.puzzleId,
    required this.initialLives,
    required this.perfectPoints,
    required this.targetPoints,
    required this.targetBasisPoints,
    required this.timeLimitMs,
    required this.requiresNoMistakes,
    required this.allowsHints,
    this.extra = const {},
  });

  final String version;
  final String scoringVersion;
  final String worldId;
  final int level;
  final String puzzleId;
  final int initialLives;
  final int perfectPoints;
  final int targetPoints;
  final int targetBasisPoints;
  final int timeLimitMs;
  final bool requiresNoMistakes;
  final bool allowsHints;
  final Json extra;
  ChallengeTimePolicy get timePolicy => ChallengeTimePolicy.activeTimeLimit;

  factory RoundChallengeRules.fromJson(Json json) {
    final rules = RoundChallengeRules._(
      version: json['version'] as String,
      scoringVersion: json['scoringVersion'] as String,
      worldId: json['worldId'] as String,
      level: json['level'] as int,
      puzzleId: json['puzzleId'] as String,
      initialLives: json['initialLives'] as int,
      perfectPoints: json['perfectPoints'] as int,
      targetPoints: json['targetPoints'] as int,
      targetBasisPoints: json['targetBasisPoints'] as int,
      timeLimitMs: json['timeLimitMs'] as int,
      requiresNoMistakes: json['requiresNoMistakes'] as bool,
      allowsHints: json['allowsHints'] as bool,
      extra: immutableJson(json),
    );
    if (rules.version != AdventureChallenges.version ||
        rules.scoringVersion != SudokuScoring.version ||
        rules.worldId != 'world-3' ||
        rules.level < 1 ||
        rules.level > 30 ||
        !rules.puzzleId.startsWith('${rules.worldId}/level-${rules.level}/') ||
        rules.initialLives < 1 ||
        rules.initialLives > 3 ||
        rules.initialLives !=
            (rules.level <= 10
                ? 3
                : rules.level <= 20
                ? 2
                : 1) ||
        rules.requiresNoMistakes != (rules.level == 30) ||
        rules.allowsHints != (rules.level != 30) ||
        rules.perfectPoints <= 0 ||
        rules.targetPoints <= 0 ||
        rules.targetPoints > rules.perfectPoints ||
        (rules.level < 30 && rules.targetPoints == rules.perfectPoints) ||
        rules.targetBasisPoints <= 0 ||
        rules.targetBasisPoints > AdventureChallenges.basis ||
        rules.timeLimitMs <= 0 ||
        json['timePolicy'] != ChallengeTimePolicy.activeTimeLimit.name ||
        (rules.level == 30 &&
            (!rules.requiresNoMistakes ||
                rules.allowsHints ||
                rules.targetPoints != rules.perfectPoints))) {
      throw const FormatException('Invalid or unsupported challenge rules');
    }
    return rules;
  }

  Json toJson() => {
    ...extra,
    'version': version,
    'scoringVersion': scoringVersion,
    'worldId': worldId,
    'level': level,
    'puzzleId': puzzleId,
    'initialLives': initialLives,
    'perfectPoints': perfectPoints,
    'targetPoints': targetPoints,
    'targetBasisPoints': targetBasisPoints,
    'timeLimitMs': timeLimitMs,
    'timePolicy': timePolicy.name,
    'requiresNoMistakes': requiresNoMistakes,
    'allowsHints': allowsHints,
  };

  int remainingLives(int mistakes) {
    RangeError.checkNotNegative(mistakes, 'mistakes');
    return math.max(0, initialLives - mistakes);
  }

  int remainingTimeMs(int elapsedMs) {
    RangeError.checkNotNegative(elapsedMs, 'elapsedMs');
    return math.max(0, timeLimitMs - elapsedMs);
  }

  /// The deadline is exclusive: at zero remaining time the attempt has expired.
  ChallengeAssessment evaluate(
    SudokuDefinition puzzle,
    PuzzleProgress progress,
  ) {
    if (puzzle.id != puzzleId) {
      throw ArgumentError.value(puzzle.id, 'puzzle', 'Wrong rules snapshot');
    }
    progress.validate(puzzle);
    final lives = remainingLives(progress.mistakes);
    final time = remainingTimeMs(progress.elapsedMs);
    final solved = List.generate(
      puzzle.initial.length,
      (index) => progress.cells[index].value == puzzle.solution[index],
    ).every((correct) => correct);
    final outcome = lives == 0
        ? ChallengeOutcome.outOfLives
        : time == 0
        ? ChallengeOutcome.outOfTime
        : requiresNoMistakes && progress.mistakes != 0
        ? ChallengeOutcome.mistakesNotAllowed
        : !allowsHints && progress.hintsUsed != 0
        ? ChallengeOutcome.hintsNotAllowed
        : !solved
        ? ChallengeOutcome.inProgress
        : progress.points < targetPoints
        ? ChallengeOutcome.belowTarget
        : ChallengeOutcome.won;
    return ChallengeAssessment(
      outcome: outcome,
      solved: solved,
      remainingLives: lives,
      remainingTimeMs: time,
      missingPoints: math.max(0, targetPoints - progress.points),
    );
  }
}

class ChallengeAssessment {
  const ChallengeAssessment({
    required this.outcome,
    required this.solved,
    required this.remainingLives,
    required this.remainingTimeMs,
    required this.missingPoints,
  });

  final ChallengeOutcome outcome;
  final bool solved;
  final int remainingLives;
  final int remainingTimeMs;
  final int missingPoints;
  bool get won => outcome == ChallengeOutcome.won;
  bool get terminal => outcome != ChallengeOutcome.inProgress;
}
