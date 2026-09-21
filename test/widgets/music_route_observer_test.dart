import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/data/services/device_game_feedback.dart';
import 'package:sundoku/data/services/game_feedback.dart';
import 'package:sundoku/routes.dart';
import 'package:sundoku/widgets/music_route_observer.dart';

class _MusicSpy extends GameFeedback {
  final scenes = <MusicScene>[];
  @override
  Future<void> setMusicScene(MusicScene scene) async => scenes.add(scene);
}

Route<void> route(String name) => MaterialPageRoute<void>(
  settings: RouteSettings(name: name),
  builder: (_) => const SizedBox(),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'destinations switch music while dialogs preserve the selected track',
    () {
      final output = _MusicSpy();
      final observer = MusicRouteObserver(output);
      final home = route(AppRoutes.home);
      final map = route(AppRoutes.map);
      final game = route(AppRoutes.game);
      final settings = route(AppRoutes.settings);
      observer.didPush(home, null);
      observer.didPush(map, home);
      observer.didPush(game, map);
      observer.didPush(settings, game);
      observer.didPop(settings, game);
      expect(output.scenes, [MusicScene.home, MusicScene.map, MusicScene.game]);
      final nextGame = route(AppRoutes.game);
      observer.didReplace(oldRoute: game, newRoute: nextGame);
      expect(output.scenes.last, MusicScene.game);
      expect(output.scenes.length, 4);
      observer.didPop(nextGame, map);
      observer.didPop(map, home);
      expect(output.scenes.sublist(4), [MusicScene.map, MusicScene.home]);
    },
  );

  test('quick play and tutorial routes select their intended music', () {
    final output = _MusicSpy();
    final observer = MusicRouteObserver(output);
    final quick = route(AppRoutes.quickPlay);
    final game = route(AppRoutes.game);
    final review = route(AppRoutes.tutorialReview);
    observer.didPush(quick, null);
    observer.didReplace(oldRoute: quick, newRoute: game);
    observer.didPush(review, game);
    observer.didRemove(review, game);
    observer.didReplace(
      oldRoute: game,
      newRoute: route(AppRoutes.firstExperience),
    );
    expect(output.scenes, [
      MusicScene.home,
      MusicScene.game,
      MusicScene.map,
      MusicScene.game,
      MusicScene.game,
    ]);
  });

  test('all four MP3 tracks and the existing tap effect are bundled', () async {
    for (final track in [
      DeviceGameFeedback.homeTrack,
      DeviceGameFeedback.mapTrack,
      ...DeviceGameFeedback.gameTracks,
      'audio/soft-tap.wav',
    ]) {
      final bytes = await rootBundle.load('assets/$track');
      expect(bytes.lengthInBytes, greaterThan(0), reason: track);
    }
  });
}
