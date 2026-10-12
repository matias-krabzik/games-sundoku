enum BookBlockKind { eyebrow, coverTitle, title, body, illustration, summary }

enum BookLesson { rules, notes }

class BookBlock {
  const BookBlock(this.kind, [this.text = '']);
  final BookBlockKind kind;
  final String text;
}

/// Authored page boundaries remain separate, even when more paper is available.
class BookSection {
  const BookSection({
    required this.title,
    required this.blocks,
    this.lesson = BookLesson.rules,
  });
  final String title;
  final List<BookBlock> blocks;
  final BookLesson lesson;
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

const notesBookSections = [
  BookSection(
    lesson: BookLesson.notes,
    title: 'El lápiz de las ideas',
    blocks: [
      BookBlock(BookBlockKind.eyebrow, 'ANOTACIONES · POSIBILIDADES'),
      BookBlock(BookBlockKind.title, 'El lápiz de las ideas'),
      BookBlock(BookBlockKind.illustration),
      BookBlock(
        BookBlockKind.body,
        'Una cifra pequeña guarda una posibilidad. Anotar permite recordar '
        'lo que aún estás investigando, sin darlo por resuelto.',
      ),
    ],
  ),
  BookSection(
    lesson: BookLesson.notes,
    title: 'Una casilla, varias opciones',
    blocks: [
      BookBlock(BookBlockKind.eyebrow, 'MIRAR ANTES DE ELEGIR'),
      BookBlock(BookBlockKind.title, 'Una casilla, varias opciones'),
      BookBlock(
        BookBlockKind.body,
        'Un candidato es una cifra que todavía puede ocupar una casilla '
        'según lo que muestra el tablero.',
      ),
      BookBlock(
        BookBlockKind.body,
        'Si ya aparece en su fila, columna o bloque, queda descartada. '
        'Las notas reúnen las opciones que siguen siendo posibles.',
      ),
    ],
  ),
  BookSection(
    lesson: BookLesson.notes,
    title: 'Descartar para avanzar',
    blocks: [
      BookBlock(BookBlockKind.eyebrow, 'UN EJEMPLO · 2 Y 7'),
      BookBlock(BookBlockKind.title, 'Descartar para avanzar'),
      BookBlock(
        BookBlockKind.body,
        'Imagina una casilla con solo dos posibilidades: 2 y 7. '
        'Al confirmar un 7 en esa fila, puedes quitarlo de tus notas.',
      ),
      BookBlock(
        BookBlockKind.body,
        'Solo queda el 2. Apaga el lápiz y escríbelo como respuesta. '
        'Cada cifra resuelta ayuda a revisar las notas de sus vecinas.',
      ),
    ],
  ),
  BookSection(
    lesson: BookLesson.notes,
    title: 'Las notas en movimiento',
    blocks: [
      BookBlock(BookBlockKind.eyebrow, 'PARA VER Y RECORDAR'),
      BookBlock(BookBlockKind.title, 'Las notas en movimiento'),
      BookBlock(
        BookBlockKind.body,
        'Mira cómo encender el lápiz, guardar candidatos y convertir '
        'una posibilidad en respuesta.',
      ),
      BookBlock(BookBlockKind.summary),
    ],
  ),
];
