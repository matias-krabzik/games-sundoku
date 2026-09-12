import 'dart:math' as math;

import 'package:flutter/material.dart';

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
    this.fixedIndices = const {},
    this.highlightKey,
    this.reveal = SudokuBoardReveal.none,
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
  final Set<int> fixedIndices;
  final Object? highlightKey;
  final SudokuBoardReveal reveal;

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
    duration: const Duration(milliseconds: 500),
    value: 1,
  );
  SudokuBoard? _previousLesson;
  Set<int> _incoming = {};
  Set<int> _outgoing = {};
  bool _reducedMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reducedMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    if (_reducedMotion) {
      _expansion.value = 1;
      _lesson.value = 1;
    }
  }

  @override
  void didUpdateWidget(SudokuBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reveal != widget.reveal) {
      _previousLesson = oldWidget;
      final highlighted = widget.highlightedIndices.toSet();
      _incoming = switch (widget.reveal) {
        SudokuBoardReveal.row || SudokuBoardReveal.column =>
          highlighted.difference(oldWidget.highlightedIndices.toSet()),
        SudokuBoardReveal.remaining => {
          for (var i = 0; i < 81; i++)
            if (!_centerIndices.contains(i) && i ~/ 9 != 4 && i % 9 != 4) i,
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
    super.dispose();
  }

  Widget _lessonTile(int index, double extent, Widget child) {
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
    return Stack(
      fit: StackFit.expand,
      children: [
        if (incoming)
          ExcludeSemantics(
            child: IgnorePointer(child: oldCell(highlighted: false)),
          )
        else
          child,
        ExcludeSemantics(
          child: IgnorePointer(
            child: _TileArrival(
              index: index,
              progress: incoming ? _lesson.value : 1 - _lesson.value,
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

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1,
    child: AnimatedBuilder(
      animation: Listenable.merge([_expansion, _lesson]),
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
                  child: Material(
                    color: const Color(0xFFEBDAB6),
                    borderRadius: boardRadius,
                    child: FocusTraversalGroup(
                      child: Stack(
                        children: [
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
                                progress:
                                    centerOnly || _centerIndices.contains(index)
                                    ? 1
                                    : ((_expansion.value * 1500 - 1000) / 500)
                                          .clamp(0.0, 1.0),
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
                                          onSelect: onSelect,
                                          fixed: fixedIndices.contains(index),
                                          marked: fixedIndices.isNotEmpty,
                                          conflict: conflictIndices.contains(
                                            index,
                                          ),
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
                          Positioned.fill(
                            child: IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: boardRadius,
                                  border: Border.all(
                                    color: const Color(0xFFD4B77D),
                                    width: 1,
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
  });

  final String? animationKey;
  final int index;
  final double progress;
  final double extent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dx = index % 9 - 4;
    final dy = index ~/ 9 - 4;
    final distance = math.sqrt((dx * dx + dy * dy).toDouble());
    // The nearest outer cells begin first; the final corner lands at 500 ms.
    final delay = ((distance - 2) / (math.sqrt(32) - 2)).clamp(0.0, 1.0) * .55;
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
  });

  final int index;
  final int? value;
  final bool selected;
  final ValueChanged<int>? onSelect;
  final bool fixed;
  final bool marked;
  final bool conflict;
  final double highlight;

  @override
  Widget build(BuildContext context) => Semantics(
    label:
        'Fila ${index ~/ 9 + 1}, columna ${index % 9 + 1}, ${value ?? 'vacía'}${fixed ? ', pista fija' : ''}',
    button: true,
    enabled: onSelect != null,
    selected: selected,
    child: LayoutBuilder(
      builder: (context, bounds) {
        final radius = BorderRadius.circular(bounds.maxWidth * .11);
        return Padding(
          padding: EdgeInsets.all(bounds.maxWidth > 50 ? 1.2 : .55),
          child: ClipRRect(
            borderRadius: radius,
            child: Stack(
              fit: StackFit.expand,
              children: [
                UiSurfaceArt(
                  selected ? UiSurface.goldTile : UiSurface.creamTile,
                  referenceSize: Size.square(bounds.maxWidth),
                ),
                if (highlight > 0 && !selected)
                  IgnorePointer(
                    child: ColoredBox(
                      color: Color.fromRGBO(255, 205, 0, .42 * highlight),
                    ),
                  ),
                if (conflict)
                  IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFFDB7000),
                          width: 3,
                        ),
                        borderRadius: radius,
                      ),
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
                                  MediaQuery.disableAnimationsOf(context) ||
                                      MediaQuery.accessibleNavigationOf(context)
                                  ? Duration.zero
                                  : const Duration(milliseconds: 350),
                              builder: (_, opacity, child) =>
                                  Opacity(opacity: opacity, child: child),
                              child: SudokuDigit(
                                value!,
                                size: bounds.maxWidth * (marked ? .64 : .72),
                              ),
                            ),
                          ),
                  ),
                ),
                if (marked && !fixed && value != null)
                  Positioned(
                    bottom: 3,
                    left: bounds.maxWidth * .32,
                    right: bounds.maxWidth * .32,
                    child: const IgnorePointer(
                      child: SizedBox(
                        height: 2,
                        child: ColoredBox(color: homeNavy),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
