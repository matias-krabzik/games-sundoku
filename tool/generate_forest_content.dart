import 'dart:io';

import 'package:sundoku/domain/generation/seeded_sudokus.dart';

void main() {
  final rows = <String>[];
  for (var n = 1; n <= 63; n++) {
    for (var attempt = 0; ; attempt++) {
      final p = SeededSudokus.create(id: 'f', seed: 'autumn-v1/$n/$attempt');
      final cells = p.initial.map((n) => n ?? 0).toList();
      final witnesses = <(int, int)>[];
      for (var a = 0; a < 81; a++) {
        if (cells[a] != 0) continue;
        final notes = SeededSudokus.candidates(cells, a);
        if (notes.length != 2) continue;
        for (final unit in SeededSudokus.units.where((u) => u.contains(a))) {
          for (final b in unit) {
            if (a == b || cells[b] != 0) continue;
            final options = SeededSudokus.candidates(cells, b);
            if (options.length == 1 && notes.contains(options.single)) {
              witnesses.add((a, b));
            }
          }
        }
      }
      if (witnesses.length <
          (n <= 21
              ? 1
              : n <= 42
              ? 2
              : 3)) {
        continue;
      }
      rows.add(
        "  ('${cells.join()}', '${p.solution.join()}', '${p.seed}', ${witnesses.first.$1}, ${witnesses.first.$2}),",
      );
      break;
    }
  }
  File('lib/data/forest_puzzles.dart').writeAsStringSync(
    '''// Frozen content. Regenerate intentionally with tool/generate_forest_content.dart.
import '../domain/models/sudoku_definition.dart';

const forestPuzzleData = <(String, String, String, int, int)>[
${rows.join('\n')}
];

List<SudokuDefinition> forestPuzzles(int level) => [
  for (var round = 0; round < 3; round++)
    _definition(level, round, forestPuzzleData[(level - 1) * 3 + round]),
];

SudokuDefinition _definition(int level, int round, (String, String, String, int, int) row) => SudokuDefinition(
  id: 'world-2/level-\$level/sudoku-\${round + 1}', difficulty: 'easy',
  seed: row.\$3, generatorVersion: 'autumn-notes-v1',
  initial: row.\$1.split('').map((n) => n == '0' ? null : int.parse(n)).toList(),
  solution: row.\$2.split('').map(int.parse).toList(),
  extra: {'notesTarget': row.\$4, 'deductionCell': row.\$5,
    'objective': 'Anota dos posibilidades y descarta una al resolver otra casilla.'},
);
''',
  );
}
