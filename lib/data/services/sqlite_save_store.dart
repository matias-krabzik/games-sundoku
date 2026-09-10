import 'package:sqflite_common/sqlite_api.dart';

import 'save_store.dart';

class SqliteSaveStore implements SaveStore {
  SqliteSaveStore._(this._database);
  final Database _database;

  static Future<SqliteSaveStore> open(
    DatabaseFactory factory,
    String path,
  ) async {
    final db = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) => db.execute('''
        CREATE TABLE game_save (
          id INTEGER PRIMARY KEY CHECK (id = 1),
          revision INTEGER NOT NULL,
          payload TEXT NOT NULL
        )
      '''),
      ),
    );
    return SqliteSaveStore._(db);
  }

  @override
  Future<String?> read() async {
    final rows = await _database.query(
      'game_save',
      where: 'id = ?',
      whereArgs: [1],
    );
    return rows.isEmpty ? null : rows.single['payload'] as String;
  }

  @override
  Future<void> write(String data, {required int expectedRevision}) =>
      _database.transaction((txn) async {
        final rows = await txn.query(
          'game_save',
          columns: ['revision'],
          where: 'id = ?',
          whereArgs: [1],
        );
        final revision = rows.isEmpty ? -1 : rows.single['revision'] as int;
        if (revision != expectedRevision) throw const SaveConflict();
        if (rows.isEmpty) {
          await txn.insert('game_save', {
            'id': 1,
            'revision': 0,
            'payload': data,
          });
        } else {
          await txn.update(
            'game_save',
            {'revision': revision + 1, 'payload': data},
            where: 'id = ?',
            whereArgs: [1],
          );
        }
      });

  @override
  Future<void> close() => _database.close();
}
