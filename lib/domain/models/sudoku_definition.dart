import 'json_data.dart';

class SudokuDefinition {
  SudokuDefinition({
    required this.id,
    required this.difficulty,
    required this.seed,
    required this.generatorVersion,
    required List<int?> initial,
    required List<int> solution,
    this.size = 9,
    this.boxRows = 3,
    this.boxColumns = 3,
    this.variant = 'classic',
    Json extra = const {},
  }) : initial = List.unmodifiable(initial),
       solution = List.unmodifiable(solution),
       extra = immutableJson(extra) {
    if (id.isEmpty ||
        seed.isEmpty ||
        !initial.contains(null) ||
        difficulty.isEmpty ||
        generatorVersion.isEmpty ||
        size < 1 ||
        boxRows < 1 ||
        boxColumns < 1 ||
        boxRows * boxColumns != size ||
        variant != 'classic' ||
        initial.length != size * size ||
        solution.length != size * size) {
      throw const FormatException('Invalid sudoku definition');
    }
    for (var i = 0; i < solution.length; i++) {
      if (solution[i] < 1 ||
          solution[i] > size ||
          (initial[i] != null && initial[i] != solution[i])) {
        throw const FormatException('Invalid sudoku value');
      }
    }
    for (var i = 0; i < size; i++) {
      final row = {for (var j = 0; j < size; j++) solution[i * size + j]};
      final column = {for (var j = 0; j < size; j++) solution[j * size + i]};
      final box = {
        for (var r = 0; r < boxRows; r++)
          for (var c = 0; c < boxColumns; c++)
            solution[((i ~/ (size ~/ boxColumns)) * boxRows + r) * size +
                (i % (size ~/ boxColumns)) * boxColumns +
                c],
      };
      if (row.length != size || column.length != size || box.length != size) {
        throw const FormatException('Invalid sudoku solution');
      }
    }
  }

  final String id;
  final String difficulty;
  final String seed;
  final String generatorVersion;
  final String variant;
  final int size;
  final int boxRows;
  final int boxColumns;
  final List<int?> initial;
  final List<int> solution;
  final Json extra;

  bool isFixed(int index) => initial[index] != null;
  bool hasError(int index, int? value) =>
      value != null && value != solution[index];

  factory SudokuDefinition.fromJson(Json json) => SudokuDefinition(
    id: json['id'] as String,
    difficulty: json['difficulty'] as String,
    seed: json['seed'] as String,
    generatorVersion: json['generatorVersion'] as String,
    variant: json['variant'] as String? ?? 'classic',
    size: json['size'] as int? ?? 9,
    boxRows: json['boxRows'] as int? ?? 3,
    boxColumns: json['boxColumns'] as int? ?? 3,
    initial: jsonList(json['initial']).cast<int?>(),
    solution: jsonList(json['solution']).cast<int>(),
    extra: json,
  );

  Json toJson() => {
    ...extra,
    'id': id,
    'difficulty': difficulty,
    'seed': seed,
    'generatorVersion': generatorVersion,
    'variant': variant,
    'size': size,
    'boxRows': boxRows,
    'boxColumns': boxColumns,
    'initial': initial,
    'solution': solution,
  };
}

class LevelDefinition {
  LevelDefinition({
    required this.id,
    required this.worldId,
    required List<String> puzzleIds,
    List<String> prerequisites = const [],
    Json extra = const {},
  }) : puzzleIds = List.unmodifiable(puzzleIds),
       prerequisites = List.unmodifiable(prerequisites),
       extra = immutableJson(extra) {
    if (id.isEmpty ||
        worldId.isEmpty ||
        puzzleIds.isEmpty ||
        puzzleIds.any((id) => id.isEmpty) ||
        puzzleIds.toSet().length != puzzleIds.length ||
        prerequisites.contains(id)) {
      throw const FormatException('Invalid level');
    }
  }

  final String id;
  final String worldId;
  final List<String> puzzleIds;
  final List<String> prerequisites;
  final Json extra;
  int get requiredLights => puzzleIds.length;

  factory LevelDefinition.fromJson(Json json) => LevelDefinition(
    id: json['id'] as String,
    worldId: json['worldId'] as String,
    puzzleIds: jsonList(json['puzzleIds']).cast<String>(),
    prerequisites: jsonList(json['prerequisites'] ?? []).cast<String>(),
    extra: json,
  );

  Json toJson() => {
    ...extra,
    'id': id,
    'worldId': worldId,
    'puzzleIds': puzzleIds,
    'prerequisites': prerequisites,
  };
}
