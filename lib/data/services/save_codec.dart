import 'dart:convert';

import '../../domain/models/game_save.dart';
import '../../domain/models/json_data.dart';

typedef SaveMigration = Json Function(Json);

class SaveCodec {
  const SaveCodec({this.migrations = const {}});
  final Map<int, SaveMigration> migrations;

  String encode(GameSave save) {
    save.validate();
    return jsonEncode(save.toJson());
  }

  GameSave decode(String source) {
    var data = jsonObject(jsonDecode(source));
    var version = data['schemaVersion'] as int;
    if (version > GameSave.schemaVersion) {
      throw const FormatException('Save belongs to a newer app version');
    }
    while (version < GameSave.schemaVersion) {
      final migration = migrations[version] ?? (version == 1 ? _fromOne : null);
      if (migration == null) {
        throw FormatException('Missing migration from $version');
      }
      data = migration(data);
      if (data['schemaVersion'] != version + 1) {
        throw const FormatException('Migration must advance one version');
      }
      version++;
    }
    return GameSave.fromJson(data);
  }
}

// Schema 1 did not enforce challenge rules. Mark the entire session, including
// untouched rounds, explicitly so later upgrades cannot impose new requirements.
Json _fromOne(Json source) => {
  ...source,
  'schemaVersion': 2,
  'sessions': {
    for (final entry in jsonObject(source['sessions'] ?? {}).entries)
      entry.key: {...jsonObject(entry.value), 'rulesMode': 'legacy'},
  },
};
