import 'package:flutter/foundation.dart';

import '../data/repositories/game_repository.dart';
import '../domain/models/json_data.dart';

/// A separate, unscored example. The target has {2,7}; column B forces 7.
class NotesLesson {
  static const key = 'tutorials/notes/v1';
  static const target = 1;
  static const other = 7;
  static final solution = List<int>.generate(
    81,
    (i) => (i ~/ 9 * 3 + i ~/ 27 + i % 9) % 9 + 1,
  );
  // Swap 7 and 8 so the first row has 2 at A and 7 at B.
  static final values = solution
      .map(
        (n) => n == 7
            ? 8
            : n == 8
            ? 7
            : n,
      )
      .toList();
  static final initial = <int?>[
    for (var i = 0; i < 81; i++)
      if (i == target ||
          i == other ||
          (i % 9 == target % 9 && values[i] == 7) ||
          (i ~/ 27 == 0 && i % 9 ~/ 3 == 0 && values[i] == 7))
        null
      else
        values[i],
  ];
  static const texts = [
    '¡Bienvenido al Bosque de la Cumbre! En la casilla iluminada podrían ir el 2 o el 7. Si aún no sabes cuál, puedes anotar los dos.',
    'El lápiz guarda tus ideas en pequeño. Tócalo para empezar a anotar.',
    'Toca el 2 y después el 7. Cada anotación tiene su lugar en la pequeña cuadrícula. ¡Todavía no son respuestas!',
    'Apaga el lápiz para volver a poner números grandes.',
    'Mira la columna iluminada: tiene todos los números menos el 7. ¡Pon el 7 en la casilla vacía!',
    'Vuelve a la casilla de tus notas. Ahora hay un 7 en su fila, así que aquí no puede ir otro. Enciende el lápiz y toca el 7 para borrarlo.',
    '¡Solo queda el 2! Apaga el lápiz y toca el 2 para poner tu respuesta.',
    '¡Ya sabes usar el lápiz! Las pistas grandes no cambian y tus notas te ayudan a pensar. Practica durante las tres rondas del primer juego. Al terminarlo, podrás usar el lápiz cuando quieras.',
  ];
}

class NotesTutorialController extends ChangeNotifier {
  NotesTutorialController(this.repository, {this.replay = false}) {
    if (!repository.forestUnlocked && !replay) {
      throw StateError('World is locked');
    }
    final saved = repository.state.modules[NotesLesson.key];
    _state = !replay && saved is Map ? jsonObject(saved) : <String, Object?>{};
  }
  final GameRepository repository;
  final bool replay;
  late Json _state;
  bool busy = false;
  String? error;
  bool _disposed = false;
  int get step => (_state['step'] as int? ?? 0).clamp(0, 7);
  bool get notesMode => _state['notesMode'] == true;
  List<int> get notes => ((_state['notes'] as List?) ?? []).cast<int>();
  int get selected => step == 4 ? NotesLesson.other : NotesLesson.target;
  List<int?> get cells => [...NotesLesson.initial]
    ..[NotesLesson.other] = _state['placed7'] == true ? 7 : null
    ..[NotesLesson.target] = _state['placed2'] == true ? 2 : null;
  bool get actionComplete => switch (step) {
    1 => notesMode,
    2 => notes.contains(2) && notes.contains(7),
    3 => !notesMode,
    4 => _state['placed7'] == true,
    5 => notesMode && notes.length == 1 && notes.single == 2,
    6 => _state['placed2'] == true,
    _ => true,
  };
  List<int> get highlighted => step == 4
      ? [for (var i = 0; i < 9; i++) i * 9 + NotesLesson.other % 9]
      : step == 5
      ? List.generate(9, (i) => i)
      : [NotesLesson.target];
  bool get canToggle =>
      !busy &&
      switch (step) {
        1 => !notesMode,
        3 => notesMode,
        5 => !notesMode,
        6 => notesMode,
        _ => false,
      };
  List<int> get allowedNumbers => busy
      ? []
      : switch (step) {
          2 when notesMode => [
            if (!notes.contains(2)) 2,
            if (!notes.contains(7)) 7,
          ],
          4 when !notesMode && !actionComplete => [7],
          5 when notesMode && notes.contains(7) => [7],
          6 when !notesMode && !actionComplete => [2],
          _ => [],
        };
  Future<void> _save(Json changes) async {
    if (busy) return;
    busy = true;
    error = null;
    notifyListeners();
    try {
      final next = {..._state, ...changes};
      if (!replay) await repository.saveModule(NotesLesson.key, next);
      _state = next;
    } catch (_) {
      error = 'No pudimos guardar. Toca de nuevo para reintentar.';
    } finally {
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> toggle() async {
    if (canToggle) await _save({'notesMode': !notesMode});
  }

  Future<void> number(int n) async {
    if (!allowedNumbers.contains(n)) return;
    if (notesMode) {
      await _save({
        'notes':
            notes.contains(n)
                  ? notes.where((x) => x != n).toList()
                  : [...notes, n]
              ..sort(),
      });
    } else {
      await _save({
        n == 7 ? 'placed7' : 'placed2': true,
        if (n == 2) 'notes': <int>[],
      });
    }
  }

  Future<bool> next() async {
    if (busy || !actionComplete) return false;
    await _save(step == 7 ? {'completed': true} : {'step': step + 1});
    return error == null;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
