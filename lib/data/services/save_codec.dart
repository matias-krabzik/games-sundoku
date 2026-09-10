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
      final migration = migrations[version];
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
