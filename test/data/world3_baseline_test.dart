import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/data/level_catalog.dart';
import 'package:sundoku/data/services/save_codec.dart';
import 'package:sundoku/domain/models/game_session.dart';

import '../support/world3_baseline.dart';

const fixtureDirectory = 'test/fixtures/world3-baseline';

void main() {
  final exportDirectory = Platform.environment['W3_BASELINE_EXPORT_DIR'];
  if (exportDirectory != null) {
    test('explicitly export reproducible pre-challenge fixtures', () async {
      final fixtures = await buildWorld3Baseline();
      await Directory(exportDirectory).create(recursive: true);
      for (final entry in fixtures.entries) {
        const SaveCodec().encode(entry.value);
        await File('$exportDirectory/${entry.key}.json').writeAsString(
          '${const JsonEncoder.withIndent('  ').convert(entry.value.toJson())}\n',
        );
      }
      expect(fixtures.keys, containsAll(baselineFixtureNames));
    });
    return;
  }

  for (final name in baselineFixtureNames) {
    test('legacy fixture $name restores progression and round state', () async {
      const codec = SaveCodec();
      final save = codec.decode(
        await File('$fixtureDirectory/$name.json').readAsString(),
      );
      expect(codec.decode(codec.encode(save)).toJson(), save.toJson());
      final repo = await openBaselineRepository(save);
      addTearDown(repo.close);
      expect(repo.state.player.id, baselinePlayer);
      expect(repo.state.progress.keys, save.progress.keys);
      expect(repo.state.totalLights, save.totalLights);
      expect(repo.state.totalPoints, save.totalPoints);
      expect(repo.state.modules, save.modules);
      expect(repo.state.puzzles.keys, save.puzzles.keys);
      expect(
        repo.state.sessions.map((id, value) => MapEntry(id, value.toJson())),
        save.sessions.map((id, value) => MapEntry(id, value.toJson())),
      );
      if (name == 'new-profile') {
        expect(repo.isWorldUnlocked('world-3'), isFalse);
        expect(repo.state.sessions, isEmpty);
      } else {
        expect(repo.isWorldUnlocked('world-3'), isTrue);
        expect(repo.notesUnlocked, isTrue);
      }
      final level = mapLevelId(1, worldId: 'world-3');
      if (name == 'world-3-one-star' || name == 'world-3-two-stars') {
        final expected = name == 'world-3-one-star' ? 1 : 2;
        expect(repo.state.progress[level]!.bestLights, expected);
        expect(repo.state.sessions.values.single.lights, expected);
        expect(
          repo.state.isUnlocked(mapLevelId(2, worldId: 'world-3')),
          isFalse,
        );
      }
      if (name == 'world-3-in-progress') {
        final session = repo.state.sessions.values.single;
        final round = session.puzzles[2];
        expect(session.status, PlayStatus.paused);
        expect(round.mistakes, 1);
        expect(round.hintsUsed, 1);
        expect(round.elapsedMs, 180000);
        expect(round.cells.any((cell) => cell.notes.length == 2), isTrue);
        final resumed = await repo.startGeneratedLevel(1, worldId: 'world-3');
        expect(resumed.id, session.id);
        expect(resumed.puzzles[2].toJson(), round.toJson());
      }
      if (name == 'world-3-level-complete') {
        expect(repo.state.sessions.values.single.lights, 3);
        expect(
          repo.state.isUnlocked(mapLevelId(2, worldId: 'world-3')),
          isTrue,
        );
        // Preserve the current no-replay flow; retry will apply to failed rounds.
        await expectLater(
          repo.startGeneratedLevel(1, worldId: 'world-3'),
          throwsStateError,
        );
      }
      expect(repo.worldCompleted('world-3'), name == 'world-3-complete');
    });
  }
}
