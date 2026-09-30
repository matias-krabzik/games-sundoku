import 'level_node.dart';
import '../models/world_map_definition.dart';
import 'valley_map.dart';
import 'spring_forest_map.dart';
import 'crossed_rivers_map.dart';

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

const crossedRiversLevelNames = [
  'La entrada de las corrientes',
  'La orilla de los sauces',
  'Las piedras que asoman',
  'El sendero del agua',
  'El prado de los juncos',
  'Aguas tranquilas',
  'El puente entre orillas',
  'Los pinos lejanos',
  'El claro del río',
  'El sendero de los álamos',
  'La curva azul',
  'La pequeña cascada',
  'La orilla de las rocas',
  'El remanso',
  'La bajada al agua',
  'Donde se cruzan los ríos',
  'El sendero de los helechos',
  'La cascada escondida',
  'La ribera alta',
  'El puente de piedra',
  'El salto de agua',
  'Junto al lago',
  'El lago abierto',
  'La orilla de los lirios',
  'Las piedras del lago',
  'El camino de la colina',
  'Las flores silvestres',
  'El mirador del agua',
  'La última subida',
  'El claro de la cima',
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
  'world-3': AdventureWorld(
    id: 'world-3',
    number: 3,
    name: 'Ríos Cruzados',
    names: crossedRiversLevelNames,
    map: crossedRiversMap,
    nodes: crossedRiversNodes,
  ),
};

AdventureWorld adventureWorld(String id) =>
    adventureWorlds[id] ?? (throw ArgumentError.value(id, 'worldId'));

String adventureModuleKey(String worldId, int number) => worldId == 'world-1'
    ? (number == 1 ? 'firstExperience' : 'generatedLevel/$number')
    : 'adventure/$worldId/level-$number';
