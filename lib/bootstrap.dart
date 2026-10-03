import 'dart:async';

import 'package:flutter/material.dart';

import 'app.dart';
import 'data/repositories/game_repository.dart';
import 'data/services/open_save_store.dart';
import 'data/services/save_codec.dart';
import 'data/services/save_store.dart';
import 'playables/create_sdk.dart';
import 'playables/playables_runtime.dart';
import 'playables/playables_save_store.dart';
import 'playables/playables_save_codec.dart';
import 'playables/playables_sdk.dart';
import 'theme.dart';

class BootstrapApp extends StatefulWidget {
  const BootstrapApp({super.key, this.playablesSdk});

  final PlayablesSdk? playablesSdk;

  @override
  State<BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<BootstrapApp> {
  GameRepository? _repository;
  PlayablesRuntime? _playables;
  final Completer<void> _firstFrame = Completer<void>();
  late Future<GameRepository> _loading;
  bool _homeReady = false;

  @override
  void initState() {
    super.initState();
    if (youtubePlayablesBuild || widget.playablesSdk != null) {
      _playables = PlayablesRuntime(
        widget.playablesSdk ?? createPlayablesSdk(),
      );
      PlayablesRuntime.active = _playables;
      _playables!.addListener(_tryGameReady);
    }
    _loading = _open();
  }

  void _tryGameReady() {
    final runtime = _playables;
    if (_homeReady && runtime != null && !runtime.isPaused) {
      runtime.gameReady();
    }
  }

  Future<GameRepository> _open() async {
    final runtime = _playables;
    if (runtime != null) await _firstFrame.future;
    final SaveStore store;
    if (youtubePlayablesBuild || runtime != null) {
      store = runtime?.inPlayablesEnvironment == true
          ? PlayablesSaveStore(runtime!.sdk)
          : MemorySaveStore();
    } else {
      store = await openSaveStore();
    }
    final repository = await GameRepository.open(
      store,
      enableWorld3Challenges: true,
      codec: runtime?.inPlayablesEnvironment == true
          ? const PlayablesSaveCodec()
          : const SaveCodec(),
    );
    if (runtime != null) runtime.saveOnPause = repository.flush;
    if (!mounted) {
      await repository.close();
      throw StateError('Bootstrap disposed');
    }
    return _repository = repository;
  }

  @override
  void dispose() {
    final repository = _repository;
    if (repository != null) unawaited(repository.close());
    _playables?.removeListener(_tryGameReady);
    _playables?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<GameRepository>(
    future: _loading,
    builder: (context, snapshot) {
      if (snapshot.hasData) {
        return SunDokuApp(
          repository: snapshot.requireData,
          playables: _playables,
          onHomeReady: () {
            _homeReady = true;
            _tryGameReady();
          },
        );
      }
      return MaterialApp(
        title: 'SunDoku',
        theme: buildSunDokuTheme(),
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: snapshot.hasError
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'No pudimos abrir tu progreso. Tus datos no se borraron.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => setState(() => _loading = _open()),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  )
                : _PlayablesLoading(
                    runtime: _playables,
                    onFirstFrame: () {
                      if (!_firstFrame.isCompleted) _firstFrame.complete();
                    },
                  ),
          ),
        ),
      );
    },
  );
}

class _PlayablesLoading extends StatefulWidget {
  const _PlayablesLoading({required this.runtime, required this.onFirstFrame});
  final PlayablesRuntime? runtime;
  final VoidCallback onFirstFrame;

  @override
  State<_PlayablesLoading> createState() => _PlayablesLoadingState();
}

class _PlayablesLoadingState extends State<_PlayablesLoading> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.runtime?.firstFrameReady();
      widget.onFirstFrame();
    });
  }

  @override
  Widget build(BuildContext context) => const Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      CircularProgressIndicator(),
      SizedBox(height: 16),
      Text('Cargando SunDoku…'),
    ],
  );
}
