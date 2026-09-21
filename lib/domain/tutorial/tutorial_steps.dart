import 'tutorial_sudokus.dart';

enum FirstExperienceStep {
  welcome,
  blockIntroduction,
  block,
  expansion,
  blocksRule,
  rowIntroduction,
  rowRule,
  rowPractice,
  columnIntroduction,
  columnRule,
  columnPractice,
  gameIntroduction,
  givensIntroduction,
  inputIntroduction,
  playing,
  celebration,
  complete,
}

/// Keep old enum names readable in saves; navigation uses this explicit order.
const tutorialStorySteps = [
  FirstExperienceStep.welcome,
  FirstExperienceStep.blockIntroduction,
  FirstExperienceStep.expansion,
  FirstExperienceStep.rowRule,
  FirstExperienceStep.columnRule,
  FirstExperienceStep.givensIntroduction,
];

FirstExperienceStep normalizeTutorialStep(
  FirstExperienceStep step, {
  required int gameIndex,
  required bool hasSession,
}) => switch (step) {
  FirstExperienceStep.block => FirstExperienceStep.blockIntroduction,
  FirstExperienceStep.blocksRule => FirstExperienceStep.expansion,
  FirstExperienceStep.rowIntroduction ||
  FirstExperienceStep.rowPractice => FirstExperienceStep.rowRule,
  FirstExperienceStep.columnIntroduction ||
  FirstExperienceStep.columnPractice => FirstExperienceStep.columnRule,
  FirstExperienceStep.gameIntroduction ||
  FirstExperienceStep.givensIntroduction ||
  FirstExperienceStep.inputIntroduction =>
    hasSession && gameIndex > 0
        ? FirstExperienceStep.playing
        : FirstExperienceStep.givensIntroduction,
  FirstExperienceStep.celebration when gameIndex == 2 =>
    FirstExperienceStep.complete,
  _ => step,
};

class TutorialLesson {
  const TutorialLesson(
    this.title,
    this.message,
    this.action, {
    this.group,
    this.anchor = 40,
  });
  final String title;
  final String message;
  final String action;
  final SudokuGroup? group;
  final int anchor;
}

TutorialLesson? lessonFor(
  FirstExperienceStep step,
  List<int> center,
) => switch (step) {
  FirstExperienceStep.blockIntroduction => const TutorialLesson(
    'Un bloque, 9 casillas',
    '¡Mira cómo se llena este bloque!\nVan los números del 1 al 9, sin repetir ninguno.',
    'Siguiente',
  ),
  FirstExperienceStep.expansion => const TutorialLesson(
    'El tablero completo',
    '¡El bloque forma parte de un tablero más grande!\nHay 9 bloques. En cada uno van los números del 1 al 9, sin repetir.',
    'Siguiente',
    group: SudokuGroup.block,
  ),
  FirstExperienceStep.rowRule => TutorialLesson(
    'Las filas',
    'Una fila va de lado a lado.\n¡Mira! Ya están el ${center[3]}, el ${center[4]} y el ${center[5]}.\nNo puedes ponerlos otra vez en las casillas de la izquierda ni de la derecha de esta fila.',
    'Siguiente',
    group: SudokuGroup.row,
  ),
  FirstExperienceStep.columnRule => TutorialLesson(
    'Las columnas',
    'Una columna va de arriba abajo.\n¡Mira! Ya están el ${center[1]}, el ${center[4]} y el ${center[7]}.\nNo puedes ponerlos otra vez en las casillas de arriba ni de abajo de esta columna.',
    'Siguiente',
    group: SudokuGroup.column,
  ),
  _ => null,
};
