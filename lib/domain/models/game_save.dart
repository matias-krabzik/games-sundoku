import 'game_session.dart';
import 'json_data.dart';
import 'player_profile.dart';
import 'sudoku_definition.dart';

class LevelRecord {
  LevelRecord({
    this.bestLights = 0,
    this.bestPoints = 0,
    this.bestElapsedMs,
    this.firstCompletedAt,
    Json extra = const {},
  }) : extra = immutableJson(extra) {
    if (bestLights < 0 || bestPoints < 0 || (bestElapsedMs ?? 0) < 0) {
      throw const FormatException('Invalid level record');
    }
  }

  final int bestLights;
  final int bestPoints;
  final int? bestElapsedMs;
  final DateTime? firstCompletedAt;
  final Json extra;

  factory LevelRecord.fromJson(Json json) => LevelRecord(
    bestLights: nonNegative(json['bestLights']),
    bestPoints: nonNegative(json['bestPoints']),
    bestElapsedMs: json['bestElapsedMs'] as int?,
    firstCompletedAt: dateFromJson(json['firstCompletedAt']),
    extra: json,
  );

  Json toJson() => {
    ...extra,
    'bestLights': bestLights,
    'bestPoints': bestPoints,
    'bestElapsedMs': bestElapsedMs,
    'firstCompletedAt': dateToJson(firstCompletedAt),
  };
}

class GameSave {
  GameSave({
    required this.player,
    required this.settings,
    required this.updatedAt,
    this.revision = 0,
    Map<String, LevelDefinition> levels = const {},
    Map<String, SudokuDefinition> puzzles = const {},
    Map<String, GameSession> sessions = const {},
    Map<String, LevelRecord> progress = const {},
    this.activeSessionId,
    Json modules = const {},
    Json extra = const {},
  }) : levels = Map.unmodifiable(levels),
       puzzles = Map.unmodifiable(puzzles),
       sessions = Map.unmodifiable(sessions),
       progress = Map.unmodifiable(progress),
       modules = immutableJson(modules),
       extra = immutableJson(extra);

  static const schemaVersion = 1;
  final int revision;
  final PlayerProfile player;
  final GameSettings settings;
  final Map<String, LevelDefinition> levels;
  final Map<String, SudokuDefinition> puzzles;
  final Map<String, GameSession> sessions;
  final Map<String, LevelRecord> progress;
  final String? activeSessionId;
  final DateTime updatedAt;
  final Json modules;
  final Json extra;

  int get totalLights =>
      progress.values.fold(0, (sum, p) => sum + p.bestLights);
  int get totalPoints =>
      progress.values.fold(0, (sum, p) => sum + p.bestPoints);

  bool isUnlocked(String levelId) {
    final level = levels[levelId];
    if (level == null) return false;
    return level.prerequisites.every(
      (id) =>
          levels.containsKey(id) &&
          (progress[id]?.bestLights ?? 0) >= levels[id]!.requiredLights,
    );
  }

  GameSave copyWith({
    PlayerProfile? player,
    GameSettings? settings,
    Map<String, LevelDefinition>? levels,
    Map<String, SudokuDefinition>? puzzles,
    Map<String, GameSession>? sessions,
    Map<String, LevelRecord>? progress,
    String? activeSessionId,
    bool clearActiveSession = false,
    DateTime? updatedAt,
    int? revision,
    Json? modules,
  }) => GameSave(
    player: player ?? this.player,
    settings: settings ?? this.settings,
    levels: levels ?? this.levels,
    puzzles: puzzles ?? this.puzzles,
    sessions: sessions ?? this.sessions,
    progress: progress ?? this.progress,
    activeSessionId: clearActiveSession
        ? null
        : activeSessionId ?? this.activeSessionId,
    updatedAt: updatedAt ?? this.updatedAt,
    revision: revision ?? this.revision,
    modules: modules ?? this.modules,
    extra: extra,
  );

  void validate() {
    if (revision < 0) throw const FormatException('Invalid save revision');
    for (final entry in levels.entries) {
      if (entry.key != entry.value.id ||
          entry.value.prerequisites.any((id) => !levels.containsKey(id))) {
        throw const FormatException('Invalid level reference');
      }
    }
    final visited = <String>{};
    void visit(String id, Set<String> ancestors) {
      if (ancestors.contains(id)) {
        throw const FormatException('Cyclic level requirements');
      }
      if (!visited.add(id)) return;
      for (final prerequisite in levels[id]!.prerequisites) {
        visit(prerequisite, {...ancestors, id});
      }
    }

    for (final id in levels.keys) {
      visit(id, {});
    }
    for (final entry in puzzles.entries) {
      if (entry.key != entry.value.id) {
        throw const FormatException('Invalid puzzle ID');
      }
    }
    for (final entry in progress.entries) {
      final level = levels[entry.key];
      if (level == null || entry.value.bestLights > level.requiredLights) {
        throw const FormatException('Invalid level progress');
      }
    }
    final pendingLevels = <String>{};
    for (final entry in sessions.entries) {
      final session = entry.value;
      final level = levels[session.levelId];
      if (entry.key != session.id ||
          session.playerId != player.id ||
          level == null ||
          session.puzzles.length != level.puzzleIds.length) {
        throw const FormatException('Invalid session reference');
      }
      if (session.canResume && !pendingLevels.add(session.levelId)) {
        throw const FormatException('Multiple pending attempts for one level');
      }
      if ((progress[session.levelId]?.bestLights ?? 0) < session.lights) {
        throw const FormatException('Missing completion rewards');
      }
      if (session.status == PlayStatus.active &&
          activeSessionId != session.id) {
        throw const FormatException('Active session reference is inconsistent');
      }
      var foundPending = false;
      for (var i = 0; i < session.puzzles.length; i++) {
        final board = session.puzzles[i];
        if (board.status != PlayStatus.completed) {
          foundPending = true;
        } else if (foundPending) {
          throw const FormatException('Challenges completed out of order');
        }
        final puzzle = puzzles[session.puzzles[i].puzzleId];
        if (puzzle == null || puzzle.id != level.puzzleIds[i]) {
          throw const FormatException('Missing session puzzle');
        }
        session.puzzles[i].validate(puzzle);
      }
    }
    if (activeSessionId != null &&
        sessions[activeSessionId]?.canResume != true) {
      throw const FormatException('Invalid active session');
    }
  }

  factory GameSave.fromJson(Json json) {
    final save = GameSave(
      player: PlayerProfile.fromJson(jsonObject(json['player'])),
      settings: GameSettings.fromJson(jsonObject(json['settings'] ?? {})),
      levels: _readModels(json['levels'], LevelDefinition.fromJson),
      puzzles: _readModels(json['puzzles'], SudokuDefinition.fromJson),
      sessions: _readModels(json['sessions'], GameSession.fromJson),
      progress: _readModels(json['progress'], LevelRecord.fromJson),
      revision: nonNegative(json['revision']),
      activeSessionId: json['activeSessionId'] as String?,
      updatedAt: dateFromJson(json['updatedAt'])!,
      modules: jsonObject(json['modules'] ?? {}),
      extra: json,
    );
    save.validate();
    return save;
  }

  Json toJson() => {
    ...extra,
    'schemaVersion': schemaVersion,
    'revision': revision,
    'player': player.toJson(),
    'settings': settings.toJson(),
    'levels': levels.map((id, value) => MapEntry(id, value.toJson())),
    'puzzles': puzzles.map((id, value) => MapEntry(id, value.toJson())),
    'sessions': sessions.map((id, value) => MapEntry(id, value.toJson())),
    'progress': progress.map((id, value) => MapEntry(id, value.toJson())),
    'activeSessionId': activeSessionId,
    'updatedAt': dateToJson(updatedAt),
    'modules': modules,
  };
}

Map<String, T> _readModels<T>(Object? value, T Function(Json) read) =>
    jsonObject(value ?? {})
        .map((key, value) => MapEntry(key, read(jsonObject(value))));
