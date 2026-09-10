import 'dart:async';

import 'package:flutter/foundation.dart';

import 'level_catalog.dart';
import 'level_node.dart';
import 'repositories/game_repository.dart';

/// Presents the current map's saved records; challenge rules live in the catalog.
class LevelProgress extends ChangeNotifier {
  LevelProgress({GameRepository? repository})
    : _repository = repository ?? GameRepository.memory(),
      _ownsRepository = repository == null {
    _repository.addListener(notifyListeners);
  }

  static const int requiredLights = 3;
  final GameRepository _repository;
  final bool _ownsRepository;

  String _id(int level) {
    RangeError.checkValueInInterval(level, 1, kMap1Nodes.length, 'level');
    return mapLevelId(level);
  }

  int lightsFor(int level) =>
      _repository.state.progress[_id(level)]?.bestLights ?? 0;
  bool isUnlocked(int level) => _repository.state.isUnlocked(_id(level));
  int get unlockedCount =>
      kMap1Nodes.where((node) => isUnlocked(node.level)).length;
  int get latestUnlocked =>
      kMap1Nodes.lastWhere((node) => isUnlocked(node.level)).level;

  Future<void> awardLight(int level) =>
      recordResult(level, (lightsFor(level) + 1).clamp(0, requiredLights));

  /// Development simulation only. Real lights come from completed sudokus.
  Future<void> recordResult(int level, int score) =>
      _repository.recordDebugLights(_id(level), score);

  Future<void> resetLevel(int level) {
    _id(level);
    return _repository.resetDebugLevels({
      for (final node in kMap1Nodes.where((node) => node.level >= level))
        _id(node.level),
    });
  }

  @override
  void dispose() {
    _repository.removeListener(notifyListeners);
    if (_ownsRepository) unawaited(_repository.close());
    super.dispose();
  }
}
