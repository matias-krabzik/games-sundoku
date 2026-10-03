import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/models/game_save.dart';
import '../domain/models/game_session.dart';
import '../domain/scoring/adventure_challenge.dart';
import 'level_catalog.dart';
import 'world_catalog.dart';
import 'repositories/game_repository.dart';

/// Presents the current map's saved records; challenge rules live in the catalog.
class LevelProgress extends ChangeNotifier {
  LevelProgress({GameRepository? repository, this.worldId = 'world-1'})
    : _repository = repository ?? GameRepository.memory(),
      _ownsRepository = repository == null {
    _repository.addListener(notifyListeners);
  }

  final String worldId;
  AdventureWorld get world => adventureWorld(worldId);

  static const int requiredLights = 3;
  final GameRepository _repository;
  final bool _ownsRepository;
  bool get worldUnlocked => _repository.isWorldUnlocked(worldId);

  String _id(int level) {
    RangeError.checkValueInInterval(level, 1, world.nodes.length, 'level');
    return mapLevelId(level, worldId: worldId);
  }

  int lightsFor(int level) =>
      _repository.state.progress[_id(level)]?.bestLights ?? 0;
  bool isUnlocked(int level) => _repository.state.isUnlocked(_id(level));
  int get unlockedCount =>
      world.nodes.where((node) => isUnlocked(node.level)).length;
  int get latestUnlocked => world.nodes
      .lastWhere(
        (node) => isUnlocked(node.level),
        orElse: () => world.nodes.first,
      )
      .level;

  bool get gateCelebrationPending =>
      world.map.gate != null && _repository.shouldCelebrateGate(worldId);
  Future<void> markGateCelebrated() =>
      _repository.markWorldGateCelebrated(worldId: worldId);

  LevelRecord recordFor(int level) =>
      _repository.state.progress[_id(level)] ?? LevelRecord();

  RoundChallengeRules? challengeFor(int level) =>
      _repository.previewChallenge(level, worldId: worldId);

  /// Sum each level's best saved score, including an unfinished attempt.
  int get worldPoints => world.nodes.fold(0, (total, node) {
    var points = recordFor(node.level).bestPoints;
    for (final session in _repository.state.sessions.values) {
      if (session.levelId == _id(node.level) && session.points > points) {
        points = session.points;
      }
    }
    return total + points;
  });

  /// The resumable attempt is the useful map summary. Otherwise show the most
  /// recent finished attempt so every level, including level 1, uses one card.
  GameSession? sessionFor(int level) {
    final id = _id(level);
    final sessions =
        _repository.state.sessions.values
            .where((session) => session.levelId == id)
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    for (final session in sessions) {
      if (session.canResume) return session;
    }
    for (final session in sessions) {
      if (session.status == PlayStatus.completed) return session;
    }
    return null;
  }

  Future<void> awardLight(int level) =>
      recordResult(level, (lightsFor(level) + 1).clamp(0, requiredLights));

  /// Development simulation only. Real lights come from completed sudokus.
  Future<void> recordResult(int level, int score) =>
      _repository.recordDebugLights(_id(level), score);

  Future<void> resetLevel(int level) {
    _id(level);
    return _repository.resetDebugLevels({
      for (final node in world.nodes.where((node) => node.level >= level))
        _id(node.level),
    });
  }

  Future<void> completeRandomLevel(int level) {
    _id(level);
    return _repository.completeDebugLevel(level, worldId: worldId);
  }

  Future<void> completeWorldExceptLastPuzzle() =>
      _repository.completeDebugWorldExceptLastPuzzle(worldId: worldId);

  Future<void> prepareForest() => _repository.prepareDebugForest();
  Future<void> resetNotesLesson() => _repository.resetDebugNotesTutorial();

  @override
  void dispose() {
    _repository.removeListener(notifyListeners);
    if (_ownsRepository) unawaited(_repository.close());
    super.dispose();
  }
}
