import '../tutorial/tutorial_sudokus.dart';
import 'sudoku_help_motion.dart';

export 'sudoku_help_motion.dart';

/// A snapshot of what the player can see. Rules never receive the solution.
class SudokuHelpContext {
  SudokuHelpContext({
    required List<int?> cells,
    required this.selectedIndex,
    Set<int> fixedIndices = const {},
  }) : cells = List.unmodifiable(cells),
       fixedIndices = Set.unmodifiable(fixedIndices) {
    if (cells.length != 81 ||
        cells.any((value) => value != null && (value < 1 || value > 9))) {
      throw ArgumentError('Expected 81 cells with values from 1 to 9 or null.');
    }
    RangeError.checkValueInInterval(selectedIndex, 0, 80, 'selectedIndex');
  }

  final List<int?> cells;
  final int selectedIndex;
  final Set<int> fixedIndices;

  Set<int> get peers => {
    for (final group in SudokuGroup.values) ...groupCells(selectedIndex, group),
  };

  bool hasRepeat(Iterable<int> indices) {
    final values = indices.map((i) => cells[i]).whereType<int>().toList();
    return values.length != values.toSet().length;
  }

  bool get hasLocalRepeat => SudokuGroup.values.any(
    (group) => hasRepeat(groupCells(selectedIndex, group)),
  );
}

/// The UI renders the explanation and illuminates these board positions.
class SudokuHelpTip {
  SudokuHelpTip({
    required this.ruleId,
    required this.message,
    Set<int> focusIndices = const {},
    this.deducedValue,
    this.emphasizedNumber,
    this.traces = const [],
    this.arrivalIndex,
  }) : focusIndices = Set.unmodifiable(focusIndices);

  final String ruleId;
  final String message;
  final Set<int> focusIndices;

  /// Logical evidence for a placement, not an instruction to fill the cell.
  /// The UI never automatically displays or enters this value.
  final int? deducedValue;

  /// Only a number explicitly mentioned in the message. Never infer it from
  /// [deducedValue], since discovery prompts must not reveal their answer.
  final int? emphasizedNumber;
  final List<SudokuHelpTrace> traces;
  final int? arrivalIndex;
}

abstract interface class SudokuHelpRule {
  /// Returns null when this rule cannot explain the selected position.
  SudokuHelpTip? evaluate(SudokuHelpContext context);
}

const _deductionRules = <SudokuHelpRule>[
  LastEmptyBlockRule(),
  LastEmptyLineRule(SudokuGroup.row),
  LastEmptyLineRule(SudokuGroup.column),
  OnlyCandidateRule(),
  OnlyPlaceRule(SudokuGroup.block),
  OnlyPlaceRule(SudokuGroup.row),
  OnlyPlaceRule(SudokuGroup.column),
];

/// The first matching rule wins. Add rules in teaching priority order.
class SudokuHelpEngine {
  const SudokuHelpEngine({
    this.rules = const [
      CompletedBoardRule(),
      RepeatedNumberRule(),
      NoCandidateRule(),
      FixedNumberRule(),
      ..._deductionRules,
      EnteredNumberRule(),
      NearbyEasyGroupRule(),
    ],
  });

  final List<SudokuHelpRule> rules;

  SudokuHelpTip explain(SudokuHelpContext context) {
    for (final rule in rules) {
      final tip = rule.evaluate(context);
      if (tip != null) return tip;
    }
    return SudokuHelpTip(
      ruleId: 'no-simple-tip',
      message:
          'Aquí todavía necesitamos descubrir algo más.\n'
          'Prueba la ayuda en otra casilla. No hace falta adivinar.',
      focusIndices: context.peers,
    );
  }
}

String _name(SudokuGroup group) => switch (group) {
  SudokuGroup.block => 'cuadro',
  SudokuGroup.row => 'fila',
  SudokuGroup.column => 'columna',
};
String _this(SudokuGroup group) => group == SudokuGroup.block ? 'este' : 'esta';
String _the(SudokuGroup group) => group == SudokuGroup.block ? 'el' : 'la';

class CompletedBoardRule implements SudokuHelpRule {
  const CompletedBoardRule();

  @override
  SudokuHelpTip? evaluate(SudokuHelpContext context) {
    if (context.cells.contains(null)) return null;
    for (var i = 0; i < 9; i++) {
      for (final indices in [
        groupCells(i * 9, SudokuGroup.row),
        groupCells(i, SudokuGroup.column),
        groupCells(i ~/ 3 * 27 + i % 3 * 3, SudokuGroup.block),
      ]) {
        if (context.hasRepeat(indices)) return null;
      }
    }
    return SudokuHelpTip(
      ruleId: 'completed-board',
      message: '¡Lo completaste!\nCada fila, columna y cuadro tiene los números del 1 al 9.',
      focusIndices: Set.of(List.generate(81, (i) => i)),
    );
  }
}

class RepeatedNumberRule implements SudokuHelpRule {
  const RepeatedNumberRule();

  @override
  SudokuHelpTip? evaluate(SudokuHelpContext context) {
    final selectedValue = context.cells[context.selectedIndex];
    // Prefer a repetition of the selected number, then other local conflicts.
    final numbers = {?selectedValue, ...List.generate(9, (i) => i + 1)};
    for (final number in numbers) {
      for (final group in SudokuGroup.values) {
        final indices = groupCells(context.selectedIndex, group);
        if (indices.where((i) => context.cells[i] == number).length < 2) {
          continue;
        }
        return SudokuHelpTip(
          ruleId: 'repeated-number',
          traces: [
            for (final other
                in indices.where((i) => context.cells[i] == number).skip(1))
              connectHelpCells(
                indices.firstWhere((i) => context.cells[i] == number),
                other,
              ),
          ],
          emphasizedNumber: number,
          message:
              'Mira ${_this(group)} ${_name(group)}: el $number se repite.\n'
              'Revisa las fichas que colocaste. Cada número va una sola vez.',
          focusIndices: indices.toSet(),
        );
      }
    }
    return null;
  }
}

class NoCandidateRule implements SudokuHelpRule {
  const NoCandidateRule();

  @override
  SudokuHelpTip? evaluate(SudokuHelpContext context) {
    if (context.cells[context.selectedIndex] != null ||
        candidates(context.cells, context.selectedIndex).isNotEmpty) {
      return null;
    }
    return SudokuHelpTip(
      ruleId: 'no-candidate',
      traces: scanHelpPeers(context.selectedIndex),
      message:
          'Aquí no queda ningún número que podamos poner.\n'
          'Revisemos las fichas que colocamos en las zonas iluminadas.',
      focusIndices: context.peers,
    );
  }
}

class FixedNumberRule implements SudokuHelpRule {
  const FixedNumberRule();

  @override
  SudokuHelpTip? evaluate(SudokuHelpContext context) {
    final number = context.cells[context.selectedIndex];
    if (number == null ||
        !context.fixedIndices.contains(context.selectedIndex)) {
      return null;
    }
    return SudokuHelpTip(
      ruleId: 'fixed-number',
      traces: [
        for (final trace in scanHelpPeers(context.selectedIndex))
          SudokuHelpTrace(trace.cells.reversed, isBlockHop: trace.isBlockHop),
      ],
      emphasizedNumber: number,
      message:
          'Este $number venía con el tablero. ¡Es una pista!\n'
          'No puede haber otro $number en su fila, columna o cuadro.',
      focusIndices: {
        ...context.peers,
        for (var i = 0; i < 81; i++)
          if (context.cells[i] == number) i,
      },
    );
  }
}

SudokuHelpTip? _lastEmpty(SudokuHelpContext context, SudokuGroup group) {
  final index = context.selectedIndex;
  if (context.cells[index] != null || context.hasLocalRepeat) return null;
  final indices = groupCells(index, group);
  if (indices.where((i) => context.cells[i] == null).length != 1) return null;
  final possible = candidates(context.cells, index);
  if (possible.length != 1) return null;
  return SudokuHelpTip(
    ruleId: 'last-empty-${group.name}',
    traces: scanHelpGroup(index, group),
    arrivalIndex: index,
    message: switch (group) {
      SudokuGroup.block =>
        'En este cuadro falta un solo número.\nMira cuáles están. ¿Cuál falta?',
      SudokuGroup.row =>
        'Esta fila está casi lista.\nMira de lado a lado. ¿Qué número falta?',
      SudokuGroup.column => 'Esta columna está casi lista.\nMira de arriba abajo. ¿Qué número falta?',
    },
    focusIndices: indices.toSet(),
    deducedValue: possible.single,
  );
}

class LastEmptyBlockRule implements SudokuHelpRule {
  const LastEmptyBlockRule();

  @override
  SudokuHelpTip? evaluate(SudokuHelpContext context) =>
      _lastEmpty(context, SudokuGroup.block);
}

class LastEmptyLineRule implements SudokuHelpRule {
  const LastEmptyLineRule(this.group) : assert(group != SudokuGroup.block);
  final SudokuGroup group;

  @override
  SudokuHelpTip? evaluate(SudokuHelpContext context) =>
      _lastEmpty(context, group);
}

class OnlyCandidateRule implements SudokuHelpRule {
  const OnlyCandidateRule();

  @override
  SudokuHelpTip? evaluate(SudokuHelpContext context) {
    final index = context.selectedIndex;
    if (context.cells[index] != null || context.hasLocalRepeat) return null;
    final possible = candidates(context.cells, index);
    if (possible.length != 1) return null;
    return SudokuHelpTip(
      ruleId: 'only-candidate',
      traces: scanHelpPeers(index),
      arrivalIndex: index,
      message:
          'Mira su fila, columna y cuadro.\n'
          'Descarta los números que ya están. ¡Solo uno puede ir aquí!',
      focusIndices: context.peers,
      deducedValue: possible.single,
    );
  }
}

class OnlyPlaceRule implements SudokuHelpRule {
  const OnlyPlaceRule(this.group);
  final SudokuGroup group;

  @override
  SudokuHelpTip? evaluate(SudokuHelpContext context) {
    final index = context.selectedIndex;
    if (context.cells[index] != null || context.hasLocalRepeat) return null;
    final indices = groupCells(index, group);
    for (final number in candidates(context.cells, index)) {
      final otherHoles = indices.where(
        (i) => i != index && context.cells[i] == null,
      );
      final evidence = <int>{...indices};
      final traces = <SudokuHelpTrace>[];
      var onlyPlace = true;
      for (final other in otherHoles) {
        SudokuGroup? blockedBy;
        for (final peerGroup in SudokuGroup.values) {
          final peers = groupCells(other, peerGroup);
          if (peers.any((i) => context.cells[i] == number)) {
            blockedBy = peerGroup;
            evidence.addAll(peers);
            final source = peers.firstWhere((i) => context.cells[i] == number);
            traces.add(connectHelpCells(source, other));
            break;
          }
        }
        if (blockedBy == null) {
          onlyPlace = false;
          break;
        }
      }
      if (!onlyPlace) continue;
      return SudokuHelpTip(
        ruleId: 'only-place-${group.name}',
        traces: traces,
        arrivalIndex: index,
        emphasizedNumber: number,
        message:
            'Busquemos el $number en ${_this(group)} ${_name(group)}.\n'
            'Los otros $number cierran los demás huecos. ¿Qué lugar queda?',
        focusIndices: evidence,
        deducedValue: number,
      );
    }
    return null;
  }
}

class EnteredNumberRule implements SudokuHelpRule {
  const EnteredNumberRule();

  @override
  SudokuHelpTip? evaluate(SudokuHelpContext context) {
    final index = context.selectedIndex;
    final number = context.cells[index];
    if (number == null || context.fixedIndices.contains(index)) return null;
    final withoutEntry = SudokuHelpContext(
      cells: [...context.cells]..[index] = null,
      selectedIndex: index,
      fixedIndices: context.fixedIndices,
    );
    for (final rule in _deductionRules) {
      final proof = rule.evaluate(withoutEntry);
      if (proof?.deducedValue != number) continue;
      final reason = switch (proof!.ruleId) {
        'last-empty-block' => 'Era el único número que faltaba en este cuadro.',
        'last-empty-row' => 'Era el único número que faltaba en esta fila.',
        'last-empty-column' =>
          'Era el único número que faltaba en esta columna.',
        'only-candidate' =>
          'Su fila, columna y cuadro descartan todos los demás.',
        'only-place-block' =>
          'Los otros huecos de este cuadro no pueden llevar un $number.',
        'only-place-row' =>
          'Los otros huecos de esta fila no pueden llevar un $number.',
        _ => 'Los otros huecos de esta columna no pueden llevar un $number.',
      };
      return SudokuHelpTip(
        ruleId: 'justified-entry',
        traces: proof.traces,
        arrivalIndex: index,
        emphasizedNumber: number,
        message: 'Este $number encaja con las pistas que vemos.\n$reason',
        focusIndices: proof.focusIndices,
        deducedValue: number,
      );
    }
    return SudokuHelpTip(
      ruleId: 'unproven-entry',
      traces: scanHelpPeers(index),
      emphasizedNumber: number,
      message:
          'Este $number no se repite en su fila, columna ni cuadro.\n'
          'Para comprobarlo mejor, sigamos buscando pistas.',
      focusIndices: context.peers,
    );
  }
}

class NearbyEasyGroupRule implements SudokuHelpRule {
  const NearbyEasyGroupRule();

  @override
  SudokuHelpTip? evaluate(SudokuHelpContext context) {
    if (context.cells[context.selectedIndex] != null ||
        context.hasLocalRepeat) {
      return null;
    }
    final order = {...context.peers, ...List.generate(81, (i) => i)};
    for (final other in order) {
      if (other == context.selectedIndex || context.cells[other] != null) {
        continue;
      }
      final alternative = SudokuHelpContext(
        cells: context.cells,
        selectedIndex: other,
        fixedIndices: context.fixedIndices,
      );
      for (final group in SudokuGroup.values) {
        final tip = _lastEmpty(alternative, group);
        if (tip == null) continue;
        return SudokuHelpTip(
          ruleId: 'nearby-easy-group',
          traces: tip.traces,
          arrivalIndex: other,
          message:
              'Aquí todavía hay varias opciones.\n'
              'Mira ${_the(group)} ${_name(group)} ${group == SudokuGroup.block ? 'iluminado' : 'iluminada'}: ¡tiene un solo hueco!',
          focusIndices: tip.focusIndices,
        );
      }
    }
    return null;
  }
}
