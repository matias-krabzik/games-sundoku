import 'dart:async';
import 'dart:convert';

import '../data/services/save_store.dart';
import 'playables_sdk.dart';

/// An in-memory, revision-checked snapshot with serialized cloud flushes.
class PlayablesSaveStore implements FlushableSaveStore {
  PlayablesSaveStore(this.sdk, {this.debounce = const Duration(seconds: 2)});

  final PlayablesSdk sdk;
  final Duration debounce;
  bool _loaded = false;
  bool _closed = false;
  int _revision = -1;
  int _savedRevision = -1;
  String? _pending;
  Timer? _timer;
  Future<void> _saving = Future.value();
  Object? lastSaveError;

  @override
  Future<String?> read() async {
    if (_loaded) throw StateError('Playables save was already loaded');
    final source = await sdk.loadData();
    // The SDK can return an empty string for a player with no saved game.
    final data = source == null || source.isEmpty ? null : source;
    if (data != null) {
      final object = jsonDecode(data);
      if (object is! Map<String, dynamic>) {
        throw const FormatException('Invalid Playables save');
      }
      _revision = object['revision'] is int ? object['revision'] as int : 0;
    }
    _loaded = true;
    return data;
  }

  @override
  Future<void> write(String data, {required int expectedRevision}) async {
    if (!_loaded || _closed) throw StateError('Playables save is unavailable');
    if (_revision != expectedRevision) throw const SaveConflict();
    if (utf8.encode(data).length >= 3 * 1024 * 1024) {
      throw const FormatException('Playables save exceeds the 3 MiB limit');
    }
    _pending = data;
    _revision++;
    _timer ??= Timer(
      debounce,
      () => unawaited(flush().catchError((Object _) {})),
    );
  }

  @override
  Future<void> flush() {
    _timer?.cancel();
    _timer = null;
    final snapshot = _pending;
    final revision = _revision;
    if (snapshot == null || revision <= _savedRevision) return _saving;
    final write = _saving.then((_) async {
      if (revision <= _savedRevision) return;
      await sdk.saveData(snapshot);
      _savedRevision = revision;
      lastSaveError = null;
      if (_revision == revision) _pending = null;
    });
    _saving = write.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {
        lastSaveError = error;
      },
    );
    return write;
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _timer?.cancel();
    await flush();
    _closed = true;
  }
}
