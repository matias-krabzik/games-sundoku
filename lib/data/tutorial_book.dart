enum BookBlockKind { eyebrow, coverTitle, title, body, illustration, summary }

class BookBlock {
  const BookBlock(this.kind, [this.text = '']);
  final BookBlockKind kind;
  final String text;
}

/// Authored page boundaries remain separate, even when more paper is available.
class BookSection {
  const BookSection({required this.title, required this.blocks});
  final String title;
  final List<BookBlock> blocks;
}

// History and rules: https://www.nikoli.co.jp/en/puzzles/sudoku/
const bookSections = [
  BookSection(
    title: 'El libro de Solara',
    blocks: [
      BookBlock(BookBlockKind.eyebrow, 'UNA MIRADA AL SUDOKU'),
      BookBlock(BookBlockKind.coverTitle, 'El libro de Solara'),
      BookBlock(BookBlockKind.illustration),
      BookBlock(
        BookBlockKind.body,
        'Un tablero, nueve cifras y un juego de lógica que dio la vuelta al mundo.',
      ),
    ],
  ),
  BookSection(
    title: 'Un nombre que viajó',
    blocks: [
      BookBlock(BookBlockKind.eyebrow, 'JAPÓN · 1984'),
      BookBlock(BookBlockKind.title, 'Un nombre que viajó'),
      BookBlock(
        BookBlockKind.body,
        'Antes de llamarse sudoku, este pasatiempo se publicaba en '
        'Estados Unidos como Number Place.',
      ),
      BookBlock(
        BookBlockKind.body,
        'En 1984, la editorial Nikoli lo llevó a Japón. Allí recibió '
        'su nombre actual.',
      ),
    ],
  ),
  BookSection(
    title: 'Se resuelve con lógica',
    blocks: [
      BookBlock(BookBlockKind.eyebrow, '81 CASILLAS · 9 BLOQUES'),
      BookBlock(BookBlockKind.title, 'Se resuelve con lógica'),
      BookBlock(
        BookBlockKind.body,
        'No necesitas sumar ni multiplicar: las cifras son símbolos '
        'que deben encontrar su lugar.',
      ),
      BookBlock(
        BookBlockKind.body,
        'Usa del 1 al 9 sin repetir en cada fila, columna y bloque de 3 × 3.',
      ),
    ],
  ),
  BookSection(
    title: 'Las reglas en movimiento',
    blocks: [
      BookBlock(BookBlockKind.eyebrow, 'PARA VER Y RECORDAR'),
      BookBlock(BookBlockKind.title, 'Las reglas en movimiento'),
      BookBlock(
        BookBlockKind.body,
        'Un resumen animado para ver cómo encajan filas, columnas y bloques.',
      ),
      BookBlock(BookBlockKind.summary),
    ],
  ),
];
