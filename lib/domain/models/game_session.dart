import 'json_data.dart';
import 'score_progress.dart';
import 'sudoku_definition.dart';

enum PlayStatus { pending, active, paused, completed, abandoned }

enum ValueSource { player, hint }

class CellProgress {
  CellProgress({
    this.value,
    List<int> notes = const [],
    this.source = ValueSource.player,
    this.errorRevealed = false,
    Json extra = const {},
  }) : notes = List.unmodifiable(notes.toSet().toList()..sort()),
       extra = immutableJson(extra);

  final int? value;
  final List<int> notes;
  final ValueSource source;
  final bool errorRevealed;
  final Json extra;

  factory CellProgress.fromJson(Json json) => CellProgress(
    value: json['value'] as int?,
    notes: jsonList(json['notes'] ?? []).cast<int>(),
    source: ValueSource.values.byName(json['source'] as String? ?? 'player'),
    errorRevealed: json['errorRevealed'] as bool? ?? false,
    extra: json,
  );

  Json toJson() => {
    ...extra,
    'value': value,
    'notes': notes,
    'source': source.name,
    'errorRevealed': errorRevealed,
  };
}

class PuzzleProgress {
  PuzzleProgress({
    required this.puzzleId,
    required List<CellProgress> cells,
    this.status = PlayStatus.pending,
    this.elapsedMs = 0,
    this.mistakes = 0,
    this.hintsUsed = 0,
    this.points = 0,
    this.scoring = const ScoreProgress(),
    this.completedAt,
    Json extra = const {},
  }) : cells = List.unmodifiable(cells),
       extra = immutableJson(extra) {
    if (elapsedMs < 0 ||
        mistakes < 0 ||
        hintsUsed < 0 ||
        points < 0 ||
        (status == PlayStatus.completed) != (completedAt != null)) {
      throw const FormatException('Invalid puzzle progress');
    }
  }

  factory PuzzleProgress.initial(SudokuDefinition puzzle) => PuzzleProgress(
    puzzleId: puzzle.id,
    cells: puzzle.initial.map((value) => CellProgress(value: value)).toList(),
  );

  final String puzzleId;
  final List<CellProgress> cells;
  final PlayStatus status;
  final int elapsedMs;
  final int mistakes;
  final int hintsUsed;
  final int points;
  final ScoreProgress scoring;
  final DateTime? completedAt;
  final Json extra;

  void validate(SudokuDefinition puzzle) {
    if (cells.length != puzzle.initial.length || puzzleId != puzzle.id) {
      throw const FormatException('Wrong board size or puzzle');
    }
    scoring.validate(puzzle);
    for (var i = 0; i < cells.length; i++) {
      final cell = cells[i];
      if ((cell.value != null &&
              (cell.value! < 1 || cell.value! > puzzle.size)) ||
          cell.notes.any((n) => n < 1 || n > puzzle.size) ||
          (cell.value != null && cell.notes.isNotEmpty) ||
          (puzzle.isFixed(i) && cell.value != puzzle.initial[i]) ||
          (status == PlayStatus.completed &&
              cell.value != puzzle.solution[i])) {
        throw const FormatException('Invalid saved cell');
      }
    }
  }

  PuzzleProgress copyWith({
    List<CellProgress>? cells,
    PlayStatus? status,
    int? elapsedMs,
    int? mistakes,
    int? hintsUsed,
    int? points,
    ScoreProgress? scoring,
    DateTime? completedAt,
  }) => PuzzleProgress(
    puzzleId: puzzleId,
    cells: cells ?? this.cells,
    status: status ?? this.status,
    elapsedMs: elapsedMs ?? this.elapsedMs,
    mistakes: mistakes ?? this.mistakes,
    hintsUsed: hintsUsed ?? this.hintsUsed,
    points: points ?? this.points,
    scoring: scoring ?? this.scoring,
    completedAt: completedAt ?? this.completedAt,
    extra: extra,
  );

  factory PuzzleProgress.fromJson(Json json) => PuzzleProgress(
    puzzleId: json['puzzleId'] as String,
    cells: jsonList(json['cells'])
        .map((e) => CellProgress.fromJson(jsonObject(e)))
        .toList(),
    status: PlayStatus.values.byName(json['status'] as String? ?? 'pending'),
    elapsedMs: nonNegative(json['elapsedMs']),
    mistakes: nonNegative(json['mistakes']),
    hintsUsed: nonNegative(json['hintsUsed']),
    points: nonNegative(json['points']),
    scoring: ScoreProgress.fromJson(jsonObject(json['scoring'] ?? {})),
    completedAt: dateFromJson(json['completedAt']),
    extra: json,
  );

  Json toJson() => {
    ...extra,
    'puzzleId': puzzleId,
    'cells': cells.map((c) => c.toJson()).toList(),
    'status': status.name,
    'elapsedMs': elapsedMs,
    'mistakes': mistakes,
    'hintsUsed': hintsUsed,
    'points': points,
    'scoring': scoring.toJson(),
    'completedAt': dateToJson(completedAt),
  };
}

class GameSession {
  GameSession({
    required this.id,
    required this.playerId,
    required this.levelId,
    required List<PuzzleProgress> puzzles,
    required this.startedAt,
    required this.updatedAt,
    this.status = PlayStatus.paused,
    this.completedAt,
    Json extra = const {},
  }) : puzzles = List.unmodifiable(puzzles),
       extra = immutableJson(extra) {
    if (id.isEmpty ||
        puzzles.isEmpty ||
        puzzles.map((p) => p.puzzleId).toSet().length != puzzles.length ||
        (status == PlayStatus.completed) != (completedAt != null) ||
        (status == PlayStatus.completed) != (lights == puzzles.length)) {
      throw const FormatException('Invalid session');
    }
  }

  final String id;
  final String playerId;
  final String levelId;
  final List<PuzzleProgress> puzzles;
  final PlayStatus status;
  final DateTime startedAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final Json extra;
  int get lights =>
      puzzles.where((p) => p.status == PlayStatus.completed).length;
  int get elapsedMs => puzzles.fold(0, (sum, p) => sum + p.elapsedMs);
  int get points => puzzles.fold(0, (sum, p) => sum + p.points);
  bool get canResume =>
      status == PlayStatus.active || status == PlayStatus.paused;
  String? get nextPuzzleId {
    for (final puzzle in puzzles) {
      if (puzzle.status != PlayStatus.completed) return puzzle.puzzleId;
    }
    return null;
  }

  GameSession copyWith({
    List<PuzzleProgress>? puzzles,
    PlayStatus? status,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) => GameSession(
    id: id,
    playerId: playerId,
    levelId: levelId,
    puzzles: puzzles ?? this.puzzles,
    status: status ?? this.status,
    startedAt: startedAt,
    updatedAt: updatedAt ?? this.updatedAt,
    completedAt: completedAt ?? this.completedAt,
    extra: extra,
  );

  factory GameSession.fromJson(Json json) => GameSession(
    id: json['id'] as String,
    playerId: json['playerId'] as String,
    levelId: json['levelId'] as String,
    puzzles: jsonList(json['puzzles'])
        .map((e) => PuzzleProgress.fromJson(jsonObject(e)))
        .toList(),
    status: PlayStatus.values.byName(json['status'] as String),
    startedAt: dateFromJson(json['startedAt'])!,
    updatedAt: dateFromJson(json['updatedAt'])!,
    completedAt: dateFromJson(json['completedAt']),
    extra: json,
  );

  Json toJson() => {
    ...extra,
    'id': id,
    'playerId': playerId,
    'levelId': levelId,
    'puzzles': puzzles.map((p) => p.toJson()).toList(),
    'status': status.name,
    'startedAt': dateToJson(startedAt),
    'updatedAt': dateToJson(updatedAt),
    'completedAt': dateToJson(completedAt),
  };
}
