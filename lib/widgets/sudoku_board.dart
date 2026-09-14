import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/models/sudoku_completion.dart';

import 'home_art.dart';
import 'sudoku_digit.dart';
import 'ui_surface_art.dart';

enum SudokuBoardReveal { none, row, column, remaining }

class SudokuBoard extends StatefulWidget {
  const SudokuBoard({
    super.key,
    required this.cells,
    this.selectedIndex,
    this.onSelect,
    this.centerOnly = false,
    this.highlightedIndices = const [],
    this.conflictIndices = const {},
    this.errorPulse = 0,
    this.completion,
    this.onCompletionFinished,
    this.fixedIndices = const {},
    this.highlightKey,
    this.reveal = SudokuBoardReveal.none,
    this.onAnimationChanged,
    this.dealProgress,
  }) : assert(cells.length == 81),
       assert(
         selectedIndex == null || (selectedIndex >= 0 && selectedIndex < 81),
       );

  final List<int?> cells;
  final int? selectedIndex;
  final ValueChanged<int>? onSelect;
  final bool centerOnly;
  final List<int> highlightedIndices;
  final Set<int> conflictIndices;

  /// Changes only for a new incorrect entry, never just for selecting a cell.
  final int errorPulse;
  final SudokuCompletion? completion;
  final ValueChanged<SudokuCompletion>? onCompletionFinished;
  final Set<int> fixedIndices;
  final Object? highlightKey;
  final SudokuBoardReveal reveal;
  final ValueChanged<bool>? onAnimationChanged;
  final double? dealProgress;

  @override
  State<SudokuBoard> createState() => _SudokuBoardState();
}

class _SudokuBoardState extends State<SudokuBoard>
    with TickerProviderStateMixin {
  late final _expansion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
    value: 1,
  );
  late final _lesson = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    value: 1,
  );
  late final _errorBuzz = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
    value: 1,
  );
  int? _errorIndex;
  late final _completionWave = AnimationController(vsync: this, value: 1)
    ..addStatusListener((status) {
      final completion = _waveCompletion;
      if (status == AnimationStatus.completed && completion != null) {
        _reportCompletion(completion);
      }
    });
  SudokuCompletion? _waveCompletion;
  Map<int, double> _completionDelays = {};
  late Map<int, Offset> _completionDirections = {};
  SudokuBoard? _previousLesson;
  Set<int> _incoming = {};
  Set<int> _outgoing = {};
  bool _reducedMotion = false;
  bool _motionReported = false;

  @override
  void initState() {
    super.initState();
    _expansion.addStatusListener(_motionChanged);
    _lesson.addStatusListener(_motionChanged);
    final completion = widget.completion;
    if (completion != null) _reportCompletion(completion);
  }

  void _motionChanged(AnimationStatus _) {
    // Controllers may start during didUpdateWidget; notify the parent after build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final animating = _expansion.isAnimating || _lesson.isAnimating;
      if (animating == _motionReported) return;
      _motionReported = animating;
      widget.onAnimationChanged?.call(animating);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reducedMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    if (_reducedMotion) {
      _expansion.value = 1;
      _lesson.value = 1;
      _errorBuzz.value = 1;
      _completionWave.value = 1;
    }
  }

  @override
  void didUpdateWidget(SudokuBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.completion, widget.completion)) {
      final completion = _waveCompletion = widget.completion;
      _completionDelays = {};
      _completionDirections = {};
      if (completion != null) {
        final distances = {
          for (final index in completion.cells)
            index: math.sqrt(
              math.pow(index % 9 - completion.origin % 9, 2) +
                  math.pow(index ~/ 9 - completion.origin ~/ 9, 2),
            ),
        };
        final radius = distances.values.fold(0.0, math.max);
        _completionDelays = {
          for (final entry in distances.entries)
            entry.key: radius == 0 ? 0 : entry.value / radius,
        };
        _completionDirections = {
          for (final entry in distances.entries)
            entry.key: entry.value == 0
                ? Offset.zero
                : Offset(
                    (entry.key % 9 - completion.origin % 9) / entry.value,
                    (entry.key ~/ 9 - completion.origin ~/ 9) / entry.value,
                  ),
        };
      }
      if (completion != null && !_reducedMotion) {
        _completionWave.duration = Duration(
          milliseconds: completion.wholeBoard ? 900 : 500,
        );
        _completionWave.forward(from: 0);
      } else {
        _completionWave.value = 1;
        if (completion != null) _reportCompletion(completion);
      }
    }
    if (oldWidget.errorPulse != widget.errorPulse &&
        widget.selectedIndex != null &&
        widget.conflictIndices.contains(widget.selectedIndex)) {
      _errorIndex = widget.selectedIndex;
      if (_reducedMotion) {
        _errorBuzz.value = 1;
      } else {
        _errorBuzz.forward(from: 0);
      }
    } else if (_errorIndex != widget.selectedIndex ||
        !widget.conflictIndices.contains(_errorIndex)) {
      _errorBuzz.value = 1;
    }
    if (oldWidget.reveal != widget.reveal) {
      _previousLesson = oldWidget;
      final highlighted = widget.highlightedIndices.toSet();
      _incoming = switch (widget.reveal) {
        SudokuBoardReveal.row || SudokuBoardReveal.column =>
          highlighted.difference(oldWidget.highlightedIndices.toSet()),
        SudokuBoardReveal.remaining => {
          for (var i = 0; i < 81; i++)
            if (!_centerIndices.contains(i) ||
                oldWidget.cells[i] != widget.cells[i])
              i,
        },
        SudokuBoardReveal.none => <int>{},
      };
      _outgoing =
          oldWidget.reveal == SudokuBoardReveal.row ||
              oldWidget.reveal == SudokuBoardReveal.column
          ? oldWidget.highlightedIndices.toSet().difference(highlighted)
          : <int>{};
      if (!_reducedMotion && widget.reveal != SudokuBoardReveal.none) {
        _expansion.value = 1;
        _lesson.duration = Duration(
          milliseconds: widget.reveal == SudokuBoardReveal.remaining
              ? 1700
              : 900,
        );
        _lesson.forward(from: 0);
      } else {
        _lesson.value = 1;
      }
    }
    if (oldWidget.centerOnly && !widget.centerOnly && !_reducedMotion) {
      _expansion.forward(from: 0);
    } else if (widget.centerOnly) {
      _expansion.value = 1;
    }
  }

  @override
  void dispose() {
    _expansion.dispose();
    _lesson.dispose();
    _errorBuzz.dispose();
    _completionWave.dispose();
    super.dispose();
  }

  Widget _lessonTile(int index, double extent, Widget child) {
    child = _completionTile(index, extent, _errorTile(index, extent, child));
    final previous = _previousLesson;
    if (_lesson.value >= 1 ||
        previous == null ||
        (!_incoming.contains(index) && !_outgoing.contains(index))) {
      return child;
    }
    Widget oldCell({required bool highlighted}) => _SudokuCell(
      index: index,
      value: previous.cells[index],
      selected: highlighted && previous.selectedIndex == index,
      onSelect: null,
      fixed: previous.fixedIndices.contains(index),
      marked: previous.fixedIndices.isNotEmpty,
      conflict: false,
      highlight: highlighted && previous.highlightedIndices.contains(index)
          ? 1
          : 0,
    );
    final incoming = _incoming.contains(index);
    final sequential = widget.reveal == SudokuBoardReveal.remaining;
    final elapsed = _lesson.value * (sequential ? 1700 : 900);
    final arrival = sequential
        ? ((elapsed - 900) / 800).clamp(0.0, 1.0)
        : _lesson.value;
    final departure = sequential
        ? (elapsed / 900).clamp(0.0, 1.0)
        : _lesson.value;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (incoming)
          ExcludeSemantics(
            child: IgnorePointer(child: oldCell(highlighted: false)),
          )
        else
          child,
        if (sequential && incoming && _outgoing.contains(index))
          ExcludeSemantics(
            child: IgnorePointer(
              child: _TileArrival(
                index: index,
                progress: 1 - departure,
                extent: extent,
                animationKey: 'lesson-departure-$index',
                child: oldCell(highlighted: true),
              ),
            ),
          ),
        ExcludeSemantics(
          child: IgnorePointer(
            child: _TileArrival(
              index: index,
              progress: incoming ? arrival : 1 - departure,
              extent: extent,
              animationKey: 'lesson-tile-$index',
              child: incoming ? child : oldCell(highlighted: true),
            ),
          ),
        ),
      ],
    );
  }

  static const _centerIndices = [30, 31, 32, 39, 40, 41, 48, 49, 50];

  void _reportCompletion(SudokuCompletion completion) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && identical(widget.completion, completion)) {
        widget.onCompletionFinished?.call(completion);
      }
    });
  }

  Widget _completionTile(int index, double extent, Widget child) {
    final completion = _waveCompletion;
    var lift = 0.0;
    if (completion != null &&
        _completionWave.value < 1 &&
        completion.cells.contains(index)) {
      final travel = completion.wholeBoard ? .64 : .40;
      final delay = _completionDelays[index]! * travel;
      final local = ((_completionWave.value - delay) / (1 - travel)).clamp(
        0.0,
        1.0,
      );
      lift = local == 0 || local == 1 ? 0 : math.sin(local * math.pi);
    }
    // Move out from the placed tile in both axes, then return to the same slot.
    return Transform.translate(
      key: ValueKey('sudoku-completion-motion-$index'),
      offset:
          (_completionDirections[index] ?? Offset.zero) * (extent * .12 * lift),
      child: Transform.rotate(
        angle: (index.isEven ? 1 : -1) * .025 * lift,
        child: Transform.scale(
          key: ValueKey('sudoku-completion-scale-$index'),
          scale: 1 + .10 * lift,
          child: child,
        ),
      ),
    );
  }

  Widget _errorTile(int index, double extent, Widget child) {
    final t = _errorBuzz.value;
    final wave = index == _errorIndex && t < 1
        ? math.sin(t * math.pi * 10) * (1 - t)
        : 0.0;
    return Transform.translate(
      key: ValueKey('sudoku-error-buzz-$index'),
      offset: Offset(wave * (extent * .09).clamp(2.0, 4.0), 0),
      child: Transform.rotate(angle: wave * .035, child: child),
    );
  }

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1,
    child: AnimatedBuilder(
      animation: Listenable.merge([
        _expansion,
        _lesson,
        _errorBuzz,
        _completionWave,
      ]),
      builder: (context, _) => LayoutBuilder(
        builder: (context, constraints) {
          final centerOnly = widget.centerOnly;
          final cells = widget.cells;
          final selectedIndex = widget.selectedIndex;
          final onSelect = widget.onSelect;
          final highlightedIndices = widget.highlightedIndices;
          final conflictIndices = widget.conflictIndices;
          final fixedIndices = widget.fixedIndices;
          final highlightKey = widget.highlightKey;
          final padding = constraints.maxWidth * .045;
          final innerMargin = constraints.maxWidth * .008;
          final boardRadius = BorderRadius.circular(
            constraints.maxWidth * .033,
          );
          final count = centerOnly ? 3 : 9;
          final blockGap = centerOnly ? 0.0 : constraints.maxWidth * .007;
          final extent =
              (constraints.maxWidth -
                  padding * 2 -
                  innerMargin * 2 -
                  blockGap * 2) /
              count;
          double offset(int coordinate) {
            final local = coordinate - (centerOnly ? 3 : 0);
            return innerMargin + local * extent + (local ~/ 3) * blockGap;
          }

          final centralExtent =
              (constraints.maxWidth - padding * 2 - innerMargin * 2) / 3;
          final shrink = Curves.easeInOutCubic.transform(
            (_expansion.value * 1.5).clamp(0.0, 1.0),
          );
          double cellOffset(int coordinate, bool central) {
            final target = offset(coordinate);
            if (centerOnly || !central) return target;
            final start = innerMargin + (coordinate - 3) * centralExtent;
            return start + (target - start) * shrink;
          }

          final innerSize = constraints.maxWidth - padding * 2;
          final blockEdges = [
            0.0,
            innerMargin + extent * 3 + blockGap * .5,
            innerMargin + extent * 6 + blockGap * 1.5,
            innerSize,
          ];
          final visible = centerOnly
              ? _centerIndices
              : List.generate(81, (i) => i);
          return Stack(
            fit: StackFit.expand,
            children: [
              const UiSurfaceArt(
                UiSurface.goldTile,
                referenceSize: Size(110, 110),
              ),
              Padding(
                padding: EdgeInsets.all(padding),
                child: ClipRect(
                  clipBehavior: _completionWave.isAnimating
                      ? Clip.none
                      : Clip.hardEdge,
                  child: Material(
                    color: const Color(0xFFFFEB9C),
                    borderRadius: boardRadius,
                    child: FocusTraversalGroup(
                      child: Stack(
                        children: [
                          if (!centerOnly)
                            for (final block in [1, 3, 5, 7])
                              Positioned(
                                left: blockEdges[block % 3],
                                top: blockEdges[block ~/ 3],
                                width:
                                    blockEdges[block % 3 + 1] -
                                    blockEdges[block % 3],
                                height:
                                    blockEdges[block ~/ 3 + 1] -
                                    blockEdges[block ~/ 3],
                                child: const IgnorePointer(
                                  child: ColoredBox(color: Color(0xFFFFDB74)),
                                ),
                              ),
                          Positioned.fill(
                            child: IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: boardRadius,
                                  border: Border.all(
                                    color: const Color(0xFFE8BC4F),
                                    width: 1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          for (final index in visible)
                            Positioned(
                              key: ValueKey('sudoku-cell-$index'),
                              left: cellOffset(
                                index % 9,
                                _centerIndices.contains(index),
                              ),
                              top: cellOffset(
                                index ~/ 9,
                                _centerIndices.contains(index),
                              ),
                              width:
                                  !centerOnly && _centerIndices.contains(index)
                                  ? centralExtent +
                                        (extent - centralExtent) * shrink
                                  : extent,
                              height:
                                  !centerOnly && _centerIndices.contains(index)
                                  ? centralExtent +
                                        (extent - centralExtent) * shrink
                                  : extent,
                              child: _TileArrival(
                                index: index,
                                radialFromCenter: widget.dealProgress != null,
                                progress:
                                    widget.dealProgress ??
                                    (centerOnly ||
                                            _centerIndices.contains(index)
                                        ? 1
                                        : ((_expansion.value * 1500 - 1000) /
                                                  500)
                                              .clamp(0.0, 1.0)),
                                extent: extent,
                                child: _lessonTile(
                                  index,
                                  extent,
                                  TweenAnimationBuilder<double>(
                                    key: ValueKey('$highlightKey-$index'),
                                    tween: Tween(begin: 0, end: 1),
                                    duration:
                                        widget.reveal !=
                                                SudokuBoardReveal.none ||
                                            MediaQuery.disableAnimationsOf(
                                              context,
                                            ) ||
                                            MediaQuery.accessibleNavigationOf(
                                              context,
                                            )
                                        ? Duration.zero
                                        : const Duration(milliseconds: 1000),
                                    builder: (context, progress, _) =>
                                        _SudokuCell(
                                          index: index,
                                          value: cells[index],
                                          selected: selectedIndex == index,
                                          selectionOrigin: selectedIndex,
                                          inSelectedLine:
                                              !centerOnly &&
                                              onSelect != null &&
                                              selectedIndex != null &&
                                              (index ~/ 9 ==
                                                      selectedIndex ~/ 9 ||
                                                  index % 9 ==
                                                      selectedIndex % 9),
                                          matchingNumber:
                                              !centerOnly &&
                                              onSelect != null &&
                                              selectedIndex != null &&
                                              cells[selectedIndex] != null &&
                                              cells[index] ==
                                                  cells[selectedIndex],
                                          related:
                                              !widget.centerOnly &&
                                              onSelect != null &&
                                              selectedIndex != null &&
                                              (index ~/ 9 ==
                                                      selectedIndex ~/ 9 ||
                                                  index % 9 ==
                                                      selectedIndex % 9 ||
                                                  (index ~/ 27 ==
                                                          selectedIndex ~/ 27 &&
                                                      index % 9 ~/ 3 ==
                                                          selectedIndex %
                                                              9 ~/
                                                              3)),
                                          onSelect: onSelect,
                                          fixed: fixedIndices.contains(index),
                                          marked: fixedIndices.isNotEmpty,
                                          conflict: conflictIndices.contains(
                                            index,
                                          ),
                                          celebrating:
                                              _completionWave.isAnimating &&
                                              _waveCompletion?.origin == index,
                                          highlight:
                                              highlightedIndices.contains(index)
                                              ? ((progress * 1.5 -
                                                        highlightedIndices
                                                                .indexOf(
                                                                  index,
                                                                ) /
                                                            highlightedIndices
                                                                .length *
                                                            .5)
                                                    .clamp(0.0, 1.0))
                                              : 0,
                                        ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

/// Stable variation per cell prevents jitter when other tutorial state changes.
class _TileArrival extends StatelessWidget {
  const _TileArrival({
    required this.index,
    required this.progress,
    required this.extent,
    required this.child,
    this.animationKey,
    this.radialFromCenter = false,
  });

  final String? animationKey;
  final int index;
  final double progress;
  final double extent;
  final Widget child;
  final bool radialFromCenter;

  @override
  Widget build(BuildContext context) {
    final dx = index % 9 - 4;
    final dy = index ~/ 9 - 4;
    final distance = math.sqrt((dx * dx + dy * dy).toDouble());
    // The nearest outer cells begin first; the final corner lands at 500 ms.
    final delay =
        (radialFromCenter
            ? distance / math.sqrt(32)
            : ((distance - 2) / (math.sqrt(32) - 2)).clamp(0.0, 1.0)) *
        .55;
    final local = progress >= 1
        ? 1.0
        : ((progress - delay) / .45).clamp(0.0, 1.0);
    final settle = Curves.easeOutBack.transform(local);
    final variation = math.Random(index * 97 + 13);
    final shiftX = (variation.nextDouble() - .5) * extent * .3;
    final shiftY = -(.15 + variation.nextDouble() * .2) * extent;
    final angle = (variation.nextDouble() - .5) * .28;
    return IgnorePointer(
      ignoring: local < 1,
      child: ExcludeSemantics(
        excluding: local == 0,
        child: Opacity(
          key: ValueKey(animationKey ?? 'tile-arrival-$index'),
          opacity: (local * 4).clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(shiftX * (1 - settle), shiftY * (1 - settle)),
            child: Transform.rotate(
              angle: angle * (1 - settle),
              child: Transform.scale(
                scale: 1 + .16 * (1 - settle),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SudokuCell extends StatelessWidget {
  const _SudokuCell({
    required this.index,
    required this.value,
    required this.selected,
    required this.onSelect,
    required this.fixed,
    required this.marked,
    required this.conflict,
    required this.highlight,
    this.related = false,
    this.matchingNumber = false,
    this.inSelectedLine = false,
    this.celebrating = false,
    this.selectionOrigin,
  });

  final int index;
  final int? value;
  final bool selected;
  final ValueChanged<int>? onSelect;
  final bool fixed;
  final bool marked;
  final bool conflict;
  final double highlight;
  final bool related;
  final bool matchingNumber;
  final bool inSelectedLine;
  final bool celebrating;
  final int? selectionOrigin;

  @override
  Widget build(BuildContext context) => Semantics(
    label:
        'Fila ${index ~/ 9 + 1}, columna ${index % 9 + 1}, ${value ?? 'vacía'}${fixed ? ', pista fija' : ''}${conflict ? ', número por corregir' : ''}',
    button: true,
    enabled: onSelect != null,
    selected: selected,
    child: LayoutBuilder(
      builder: (context, bounds) {
        final radius = BorderRadius.circular(bounds.maxWidth * .11);
        final alternateBlock = (index ~/ 27 + (index % 9) ~/ 3).isOdd;
        final tint = conflict
            ? (selected ? const Color(0xFFFFBCCD) : const Color(0xFFFFD0DD))
            : selected
            ? const Color(0xFFCB8A16)
            : matchingNumber
            ? Colors.white
            : inSelectedLine
            ? const Color(0xFFFFF0AD)
            : related
            ? const Color(0xFFCDDDC3)
            : fixed
            ? (alternateBlock
                  ? const Color(0xFFF0E1C5)
                  : const Color(0xFFF8ECD5))
            : (alternateBlock ? const Color(0xFFFFFAED) : Colors.white);
        final appearance = _CellAppearance(
          tint: tint,
          gold: !conflict && (selected || matchingNumber) ? 1 : 0,
          digit: conflict
              ? (selected ? const Color(0xFF980A18) : const Color(0xFFD51B25))
              : selected
              ? Colors.white
              : homeNavy,
        );
        final origin = selectionOrigin;
        var delay = 0.0;
        if (origin != null && related && !matchingNumber && !selected) {
          final row = origin ~/ 9;
          final column = origin % 9;
          final radius = math.max(
            math.max(row, 8 - row),
            math.max(column, 8 - column),
          );
          final distance = math.sqrt(
            math.pow(index ~/ 9 - row, 2) + math.pow(index % 9 - column, 2),
          );
          delay = (distance / radius).clamp(0.0, 1.0) * .45;
        }
        return _AnimatedCellAppearance(
          appearance: appearance,
          delay: delay,
          builder: (context, appearance) => Padding(
            padding: EdgeInsets.all(bounds.maxWidth > 50 ? 1.2 : .55),
            child: ClipRRect(
              borderRadius: radius,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColorFiltered(
                    key: related && !selected
                        ? ValueKey('sudoku-peer-$index')
                        : null,
                    colorFilter: ColorFilter.mode(
                      appearance.tint,
                      BlendMode.modulate,
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (appearance.gold < 1)
                          UiSurfaceArt(
                            UiSurface.creamTile,
                            key: matchingNumber && appearance.gold == 0
                                ? ValueKey('sudoku-matching-number-$index')
                                : null,
                            referenceSize: Size.square(bounds.maxWidth),
                          ),
                        if (appearance.gold > 0)
                          Opacity(
                            key: ValueKey('sudoku-match-fade-$index'),
                            opacity: appearance.gold,
                            child: UiSurfaceArt(
                              UiSurface.goldTile,
                              key: matchingNumber
                                  ? ValueKey('sudoku-matching-number-$index')
                                  : null,
                              referenceSize: Size.square(bounds.maxWidth),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (highlight > 0 && !selected)
                    IgnorePointer(
                      child: ColoredBox(
                        color: Color.fromRGBO(255, 205, 0, .42 * highlight),
                      ),
                    ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: radius,
                      onTap: onSelect == null ? null : () => onSelect!(index),
                      canRequestFocus: onSelect != null,
                      focusColor: const Color(0x50082A62),
                      hoverColor: const Color(0x20F8B516),
                      child: value == null
                          ? const SizedBox.expand()
                          : Center(
                              child: TweenAnimationBuilder<double>(
                                key: ValueKey(value),
                                tween: Tween(begin: 0, end: 1),
                                duration:
                                    conflict ||
                                        celebrating ||
                                        MediaQuery.disableAnimationsOf(
                                          context,
                                        ) ||
                                        MediaQuery.accessibleNavigationOf(
                                          context,
                                        )
                                    ? Duration.zero
                                    : const Duration(milliseconds: 350),
                                builder: (_, opacity, child) =>
                                    Opacity(opacity: opacity, child: child),
                                child: SudokuDigit(
                                  value!,
                                  size: bounds.maxWidth * (marked ? .52 : .58),
                                  color: appearance.digit,
                                ),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

@immutable
class _CellAppearance {
  const _CellAppearance({
    required this.tint,
    required this.gold,
    required this.digit,
  });

  final Color tint;
  final double gold;
  final Color digit;

  static _CellAppearance lerp(_CellAppearance a, _CellAppearance b, double t) =>
      _CellAppearance(
        tint: Color.lerp(a.tint, b.tint, t)!,
        gold: a.gold + (b.gold - a.gold) * t,
        digit: Color.lerp(a.digit, b.digit, t)!,
      );

  @override
  bool operator ==(Object other) =>
      other is _CellAppearance &&
      tint == other.tint &&
      gold == other.gold &&
      digit == other.digit;

  @override
  int get hashCode => Object.hash(tint, gold, digit);
}

class _AnimatedCellAppearance extends StatefulWidget {
  const _AnimatedCellAppearance({
    required this.appearance,
    required this.delay,
    required this.builder,
  });

  final _CellAppearance appearance;
  final double delay;
  final Widget Function(BuildContext, _CellAppearance) builder;

  @override
  State<_AnimatedCellAppearance> createState() =>
      _AnimatedCellAppearanceState();
}

class _AnimatedCellAppearanceState extends State<_AnimatedCellAppearance>
    with SingleTickerProviderStateMixin {
  late final _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
    value: 1,
  );
  late _CellAppearance _from = widget.appearance;
  late _CellAppearance _to = widget.appearance;
  double _delay = 0;
  bool _reducedMotion = false;

  _CellAppearance get _current => _CellAppearance.lerp(
    _from,
    _to,
    Curves.easeOutCubic.transform(
      ((_animation.value - _delay) / (1 - _delay)).clamp(0.0, 1.0),
    ),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reducedMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    if (_reducedMotion) _animation.value = 1;
  }

  @override
  void didUpdateWidget(_AnimatedCellAppearance oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.appearance == _to) return;
    // Retarget from the visible colors when another selection interrupts a wave.
    _from = _current;
    _to = widget.appearance;
    // Equal-number highlights fade together, including those leaving a group.
    _delay = _from.gold != _to.gold ? 0 : widget.delay;
    if (_reducedMotion) {
      _animation.value = 1;
    } else {
      _animation.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _animation,
    builder: (context, _) => widget.builder(context, _current),
  );
}
