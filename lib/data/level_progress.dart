import 'package:flutter/foundation.dart';

import 'level_node.dart';

/// Best performance per level, kept for the current application session.
/// Three points in a playable level unlock the following level.
class LevelProgress extends ChangeNotifier {
  static const int requiredLights = 3;
  final List<int> _lights = List.filled(kMap1Nodes.length, 0);

  int lightsFor(int level) => _lights[level - 1];
  bool isUnlocked(int level) =>
      level == 1 ||
      _lights.take(level - 1).every((points) => points == requiredLights);
  int get unlockedCount =>
      kMap1Nodes.where((node) => isUnlocked(node.level)).length;
  int get latestUnlocked => unlockedCount;

  void awardLight(int level) {
    if (!isUnlocked(level) || lightsFor(level) >= requiredLights) return;
    recordResult(level, lightsFor(level) + 1);
  }

  /// Preserve the best result: replaying with a lower score never removes it.
  void recordResult(int level, int score) {
    RangeError.checkValueInInterval(score, 0, requiredLights, 'score');
    if (!isUnlocked(level) || score <= lightsFor(level)) return;
    _lights[level - 1] = score;
    notifyListeners();
  }

  /// Clear this result and subsequent progress so development can replay it.
  void resetLevel(int level) {
    if (lightsFor(level) == 0) return;
    _lights.fillRange(level - 1, _lights.length, 0);
    notifyListeners();
  }
}
