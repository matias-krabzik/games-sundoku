import 'json_data.dart';
import 'sudoku_definition.dart';

/// Persistent reward history prevents scoring the same work twice.
class ScoreProgress {
  const ScoreProgress({
    this.initialized = false,
    this.streak = 0,
    this.cells = const {},
    this.zones = const {},
    this.assisted = const {},
  });

  final bool initialized;
  final int streak;
  final Set<int> cells;
  final Set<int> zones;
  final Set<int> assisted;

  factory ScoreProgress.fromJson(Json json) => ScoreProgress(
    initialized: json['initialized'] as bool? ?? false,
    streak: nonNegative(json['streak']),
    cells: Set.unmodifiable(jsonList(json['cells'] ?? []).cast<int>()),
    zones: Set.unmodifiable(jsonList(json['zones'] ?? []).cast<int>()),
    assisted: Set.unmodifiable(jsonList(json['assisted'] ?? []).cast<int>()),
  );

  void validate(SudokuDefinition puzzle) {
    if (streak < 0 ||
        cells.any((i) => i < 0 || i >= puzzle.size * puzzle.size) ||
        assisted.any((i) => i < 0 || i >= puzzle.size * puzzle.size) ||
        zones.any((i) => i < 0 || i > puzzle.size * 3)) {
      throw const FormatException('Invalid score history');
    }
  }

  Json toJson() => {
    'initialized': initialized,
    'streak': streak,
    'cells': cells.toList()..sort(),
    'zones': zones.toList()..sort(),
    'assisted': assisted.toList()..sort(),
  };
}
