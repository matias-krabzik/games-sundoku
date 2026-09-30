import '../data/services/save_codec.dart';
import '../domain/models/json_data.dart';

/// Playables' cloud schema 0 used the same payload fields as the current save.
class PlayablesSaveCodec extends SaveCodec {
  const PlayablesSaveCodec() : super(migrations: const {0: _fromZero});
}

Json _fromZero(Json source) => {
  ...source,
  'schemaVersion': 1,
  'revision': source['revision'] ?? 0,
};
