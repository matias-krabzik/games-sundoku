import 'level_node.dart';
import '../models/world_map_definition.dart';
import 'valley_map.dart';
import 'spring_forest_map.dart';

class AdventureWorld {
  AdventureWorld({
    required this.id,
    required this.number,
    required this.name,
    required List<String> names,
    required this.map,
    List<LevelNode>? nodes,
  }) : names = List.unmodifiable(names),
       nodes = List.unmodifiable(nodes ?? map.nodesFor(names.length)) {
    map.validate();
    if (this.names.isEmpty || this.names.length != this.nodes.length) {
      throw ArgumentError('Every map level needs a name and a position.');
    }
    for (var i = 0; i < this.nodes.length; i++) {
      final node = this.nodes[i];
      if (node.level != i + 1 ||
          !node.x.isFinite ||
          !node.y.isFinite ||
          node.x < 0 ||
          node.x > 1 ||
          node.y < 0 ||
          node.y > 1) {
        throw ArgumentError(
          'Map levels must be numbered in order with normalized positions.',
        );
      }
    }
  }
  final String id;
  final int number;
  final String name;
  final List<String> names;
  final List<LevelNode> nodes;
  final WorldMapDefinition map;
  int get levelCount => names.length;
  bool get isForest => id == 'world-2';
}

const forestLevelNames = [
  'La entrada del bosque',
  'Las primeras anotaciones',
  'Bajo las hojas',
  'El sendero de tierra',
  'El viejo tronco',
  'Hojas al viento',
  'La primera claridad',
  'Junto al arroyo',
  'Las piedras redondas',
  'El puente de madera',
  'Entre los helechos',
  'La curva del agua',
  'La orilla tranquila',
  'Raíces del camino',
  'El sendero que sube',
  'Entre las copas',
  'La luz entre ramas',
  'Cerca de la cascada',
  'Los árboles antiguos',
  'La cima del bosque',
];

final adventureWorlds = <String, AdventureWorld>{
  'world-1': AdventureWorld(
    id: 'world-1',
    number: 1,
    name: 'Valle del Sol',
    names: kValleyLevelNames,
    nodes: kMap1Nodes,
    map: valleyMap,
  ),
  'world-2': AdventureWorld(
    id: 'world-2',
    number: 2,
    name: 'Bosque de la Cumbre',
    names: forestLevelNames,
    map: springForestMap,
    nodes: springForestNodes,
  ),
};

AdventureWorld adventureWorld(String id) =>
    adventureWorlds[id] ?? (throw ArgumentError.value(id, 'worldId'));

String adventureModuleKey(String worldId, int number) => worldId == 'world-1'
    ? (number == 1 ? 'firstExperience' : 'generatedLevel/$number')
    : 'adventure/$worldId/level-$number';
