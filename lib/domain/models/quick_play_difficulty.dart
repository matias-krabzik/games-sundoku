enum QuickPlayDifficulty {
  easy('Fácil', 'Para entrar en calor', 38),
  normal('Normal', 'Encuentra tu ritmo', 44),
  medium('Medio', 'Un paso más', 49),
  hard('Difícil', 'Pon a prueba tu lógica', 53),
  extreme('Extremo', 'Tu mayor desafío', 57);

  const QuickPlayDifficulty(this.label, this.description, this.emptyCells);
  final String label;
  final String description;
  final int emptyCells;
  String get storageKey => 'quickPlay/$name';
}
