import 'package:flutter/foundation.dart';

import '../data/repositories/game_repository.dart';
import '../domain/tutorial/challenge_lesson.dart';

class ChallengeTutorialController extends ChangeNotifier {
  ChallengeTutorialController(this.repository, {this.replay = false}) {
    if (!repository.isWorldUnlocked('world-3')) {
      throw StateError('World is locked');
    }
    final saved = repository.state.modules[ChallengeLesson.key];
    if (!replay && saved is Map && saved['version'] == 1) {
      final step = saved['step'];
      _step = (step is int ? step : 0).clamp(0, 3);
    }
  }
  final GameRepository repository;
  final bool replay;
  int _step = 0;
  int get step => _step;
  bool busy = false;
  bool _disposed = false;
  String? error;

  Future<bool> _save(int next, {bool completed = false}) async {
    if (busy || _disposed) return false;
    busy = true;
    error = null;
    notifyListeners();
    try {
      if (!replay) {
        await repository.saveModule(ChallengeLesson.key, {
          'version': 1,
          'step': next,
          'completed': completed,
        });
      }
      _step = next;
      return true;
    } catch (_) {
      error = 'No pudimos guardar. Toca de nuevo para reintentar.';
      return false;
    } finally {
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<bool> next() => _save((_step + 1).clamp(0, 3), completed: _step == 3);
  Future<bool> skip() => _save(3, completed: true);
  Future<void> previous() async {
    if (_step > 0) await _save(_step - 1);
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
