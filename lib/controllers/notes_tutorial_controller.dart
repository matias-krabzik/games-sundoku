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
  static const titles = [
    'El lápiz de las ideas',
    'Encendemos el lápiz',
    'Guardamos dos ideas',
    'Ideas y respuestas',
    'Buscamos una pista',
    'Descartamos el 7',
    'La respuesta es el 2',
    '¡Vamos a practicar!',
  ];
  static const texts = [
    'En esta casilla podrían ir el 2 o el 7. Mira cómo el lápiz nos ayuda a decidir.',
    'Encendemos el lápiz. Ahora los números se guardan como pequeñas ideas.',
    'Anotamos el 2 y el 7. Son posibilidades, todavía no son respuestas.',
    'Apagamos el lápiz para volver a escribir respuestas grandes.',
    'En la columna iluminada solo falta el 7. Ya podemos colocarlo.',
    'Ahora hay un 7 en la misma fila. Lo quitamos de nuestras notas: aquí no se puede repetir.',
    '¡Solo queda el 2! Apagamos el lápiz y lo convertimos en la respuesta.',
    'Anota posibilidades, descarta las que no encajan y resuelve. El lápiz te acompañará en el primer juego; al completarlo, quedará desbloqueado.',
  ];

  static const durations = [900, 1500, 2600, 1500, 1900, 2600, 2800, 900];

  /// Canonical boundaries also repair old saves that advanced without actions.
  static Json stateAfter(int step) => {
    'notesMode': step == 1 || step == 2 || step == 5,
    'notes': step >= 6 || step < 2
        ? <int>[]
        : step == 5
        ? [2]
        : [2, 7],
    'placed7': step >= 4,
    'placed2': step >= 6,
  };

  /// A deterministic, unscored demonstration. Playback never writes a save.
  static NotesDemoFrame frameAt(int step, int milliseconds) {
    final state = stateAfter(step - 1);
    final actions = switch (step) {
      1 => [(850, 0)],
      2 => [(900, 2), (1900, 7)],
      3 => [(850, 0)],
      4 => [(1100, 7)],
      5 => [(700, 0), (1800, 7)],
      6 => [(700, 0), (1800, 2)],
      _ => <(int, int)>[],
    };
    int? cue;
    for (final (at, number) in actions) {
      if (milliseconds >= at - 450 && milliseconds < at + 350) cue = number;
      if (milliseconds < at) continue;
      if (number == 0) {
        state['notesMode'] = state['notesMode'] != true;
      } else if (state['notesMode'] == true) {
        final notes = (state['notes'] as List<int>).toList();
        notes.contains(number) ? notes.remove(number) : notes.add(number);
        state['notes'] = notes..sort();
      } else {
        state[number == 7 ? 'placed7' : 'placed2'] = true;
        if (number == 2) state['notes'] = <int>[];
      }
    }
    return NotesDemoFrame(step: step, state: state, cue: cue);
  }
}

class NotesDemoFrame {
  const NotesDemoFrame({required this.step, required this.state, this.cue});
  final int step;
  final Json state;

  /// Zero highlights the pencil; 2 and 7 highlight their number controls.
  final int? cue;
  bool get notesMode => state['notesMode'] == true;
  List<int> get notes => state['notes'] as List<int>;
  int get selected => step == 4 ? NotesLesson.other : NotesLesson.target;
  List<int?> get cells => [...NotesLesson.initial]
    ..[NotesLesson.other] = state['placed7'] == true ? 7 : null
    ..[NotesLesson.target] = state['placed2'] == true ? 2 : null;
  List<int> get highlighted => step == 4
      ? [for (var i = 0; i < 9; i++) i * 9 + NotesLesson.other % 9]
      : step == 5
      ? List.generate(9, (i) => i)
      : [NotesLesson.target];
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
    if (busy) return false;
    await _save({
      ...NotesLesson.stateAfter(step),
      if (step == 7) 'completed': true else 'step': step + 1,
    });
    return error == null;
  }

  Future<void> previous() async {
    if (busy || step == 0) return;
    await _save({...NotesLesson.stateAfter(step - 2), 'step': step - 1});
  }

  Future<bool> skipTutorial() async {
    if (busy) return false;
    await _save({'step': 7, 'completed': true, 'notesMode': false});
    return error == null;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
