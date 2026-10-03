import '../scoring/adventure_challenge.dart';
import 'game_session.dart';
import 'json_data.dart';
import 'sudoku_definition.dart';

/// A durable attempt token prevents delayed retry/continue callbacks from
/// mutating a newer attempt. Only the current attempt is retained.
class RoundAttempt {
  RoundAttempt({
    required this.id,
    required this.rules,
    this.number = 1,
    this.previousId,
    this.result,
    this.acknowledged = false,
    Json extra = const {},
  }) : extra = immutableJson(extra) {
    if (id.isEmpty ||
        number < 1 ||
        (number == 1) != (previousId == null) ||
        previousId == '' ||
        previousId == id ||
        (acknowledged && result?.outcome != ChallengeOutcome.won)) {
      throw const FormatException('Invalid round attempt');
    }
  }

  final String id;
  final int number;
  final String? previousId;
  final RoundChallengeRules rules;
  final RoundResult? result;
  final bool acknowledged;
  final Json extra;

  RoundAttempt copyWith({RoundResult? result, bool? acknowledged}) =>
      RoundAttempt(
        id: id,
        number: number,
        previousId: previousId,
        rules: rules,
        result: result ?? this.result,
        acknowledged: acknowledged ?? this.acknowledged,
        extra: extra,
      );

  void validate(PuzzleProgress board, SudokuDefinition puzzle) {
    if (puzzle.id != rules.puzzleId) {
      throw const FormatException('Rules belong to another puzzle');
    }
    final assessment = rules.evaluate(puzzle, board);
    final saved = result;
    if (assessment.terminal != (saved != null) ||
        (board.status == PlayStatus.completed) != assessment.won ||
        (board.status == PlayStatus.failed) !=
            (assessment.terminal && !assessment.won)) {
      throw const FormatException('Attempt status does not match its result');
    }
    if (saved != null &&
        (saved.outcome != assessment.outcome ||
            saved.points != board.points ||
            saved.elapsedMs != board.elapsedMs ||
            saved.mistakes != board.mistakes ||
            saved.hintsUsed != board.hintsUsed ||
            (assessment.won && saved.finishedAt != board.completedAt))) {
      throw const FormatException('Result does not match its frozen board');
    }
  }

  factory RoundAttempt.fromJson(Json json) => RoundAttempt(
    id: json['id'] as String,
    number: json['number'] as int,
    previousId: json['previousId'] as String?,
    rules: RoundChallengeRules.fromJson(jsonObject(json['rules'])),
    result: json['result'] == null
        ? null
        : RoundResult.fromJson(jsonObject(json['result'])),
    acknowledged: json['acknowledged'] as bool,
    extra: json,
  );

  Json toJson() => {
    ...extra,
    'id': id,
    'number': number,
    'previousId': previousId,
    'rules': rules.toJson(),
    'result': result?.toJson(),
    'acknowledged': acknowledged,
  };
}

class RoundResult {
  RoundResult({
    required this.outcome,
    required this.points,
    required this.elapsedMs,
    required this.mistakes,
    required this.hintsUsed,
    required this.finishedAt,
    Json extra = const {},
  }) : extra = immutableJson(extra) {
    if (outcome == ChallengeOutcome.inProgress ||
        points < 0 ||
        elapsedMs < 0 ||
        mistakes < 0 ||
        hintsUsed < 0) {
      throw const FormatException('Invalid round result');
    }
  }

  final ChallengeOutcome outcome;
  final int points;
  final int elapsedMs;
  final int mistakes;
  final int hintsUsed;
  final DateTime finishedAt;
  final Json extra;

  factory RoundResult.fromJson(Json json) => RoundResult(
    outcome: ChallengeOutcome.values.byName(json['outcome'] as String),
    points: json['points'] as int,
    elapsedMs: json['elapsedMs'] as int,
    mistakes: json['mistakes'] as int,
    hintsUsed: json['hintsUsed'] as int,
    finishedAt: dateFromJson(json['finishedAt'])!,
    extra: json,
  );

  Json toJson() => {
    ...extra,
    'outcome': outcome.name,
    'points': points,
    'elapsedMs': elapsedMs,
    'mistakes': mistakes,
    'hintsUsed': hintsUsed,
    'finishedAt': dateToJson(finishedAt),
  };
}
