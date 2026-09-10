abstract interface class SaveStore {
  Future<String?> read();
  Future<void> write(String data, {required int expectedRevision});
  Future<void> close();
}

class SaveConflict implements Exception {
  const SaveConflict();
  @override
  String toString() => 'The save was changed by another instance';
}

class MemorySaveStore implements SaveStore {
  String? _data;
  int _revision = -1;

  @override
  Future<String?> read() async => _data;

  @override
  Future<void> write(String data, {required int expectedRevision}) async {
    if (_revision != expectedRevision) throw const SaveConflict();
    _data = data;
    _revision++;
  }

  @override
  Future<void> close() async {}
}
