import 'dart:async';

import 'package:flutter/material.dart';

import 'app.dart';
import 'data/repositories/game_repository.dart';
import 'data/services/open_save_store.dart';
import 'theme.dart';

class BootstrapApp extends StatefulWidget {
  const BootstrapApp({super.key});

  @override
  State<BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<BootstrapApp> {
  GameRepository? _repository;
  late Future<GameRepository> _loading = _open();

  Future<GameRepository> _open() async {
    final repository = await GameRepository.open(await openSaveStore());
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<GameRepository>(
    future: _loading,
    builder: (context, snapshot) {
      if (snapshot.hasData) return SunDokuApp(repository: snapshot.requireData);
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
                : const CircularProgressIndicator(),
          ),
        ),
      );
    },
  );
}
