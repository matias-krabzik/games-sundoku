import 'json_data.dart';

class PlayerProfile {
  PlayerProfile({
    required this.id,
    this.name = 'Jugador',
    this.nameChosen = false,
    this.language = 'es',
    Json extra = const {},
  }) : extra = immutableJson(extra) {
    if (id.isEmpty || name.trim().isEmpty) {
      throw const FormatException('Invalid player');
    }
  }

  final String id;
  final String name;
  final bool nameChosen;
  final String language;
  final Json extra;

  factory PlayerProfile.fromJson(Json json) => PlayerProfile(
    id: json['id'] as String,
    name: json['name'] as String? ?? 'Jugador',
    nameChosen: json['nameChosen'] as bool? ?? false,
    language: json['language'] as String? ?? 'es',
    extra: json,
  );

  Json toJson() => {
    ...extra,
    'id': id,
    'name': name,
    'nameChosen': nameChosen,
    'language': language,
  };
}

class GameSettings {
  GameSettings({
    this.sound = true,
    this.music = true,
    this.vibration = true,
    Json extra = const {},
  }) : extra = immutableJson(extra);

  final bool sound;
  final bool music;
  final bool vibration;
  final Json extra;

  factory GameSettings.fromJson(Json json) => GameSettings(
    sound: json['sound'] as bool? ?? true,
    music: json['music'] as bool? ?? true,
    vibration: json['vibration'] as bool? ?? true,
    extra: json,
  );

  Json toJson() => {
    ...extra,
    'sound': sound,
    'music': music,
    'vibration': vibration,
  };
}
