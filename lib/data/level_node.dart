/// A level marker in normalized coordinates of the panoramic world artwork.
class LevelNode {
  const LevelNode({required this.level, required this.x, required this.y});

  final int level;
  final double x;
  final double y;
}

/// Positions follow the path in world-1-horizontal.png from left to right.
const List<LevelNode> kMap1Nodes = <LevelNode>[
  LevelNode(level: 1, x: 0.065, y: 0.640),
  LevelNode(level: 2, x: 0.160, y: 0.685),
  LevelNode(level: 3, x: 0.255, y: 0.657),
  LevelNode(level: 4, x: 0.350, y: 0.627),
  LevelNode(level: 5, x: 0.445, y: 0.668),
  LevelNode(level: 6, x: 0.550, y: 0.600),
  LevelNode(level: 7, x: 0.665, y: 0.613),
  LevelNode(level: 8, x: 0.755, y: 0.552),
  LevelNode(level: 9, x: 0.850, y: 0.586),
  LevelNode(level: 10, x: 0.942, y: 0.477),
];
