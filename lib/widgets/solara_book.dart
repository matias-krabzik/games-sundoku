import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/tutorial_book.dart';
import 'book_illustration.dart';
import 'book_pagination.dart';
import 'book_print_material.dart';
import 'game_feedback_scope.dart';
import 'home_art.dart';
import 'illustrated_action_button.dart';
import 'juicy_press.dart';
import 'map_art.dart';
import 'ui_surface_art.dart';

/// A single-page book with authored editorial sheets and no vertical scrolling.
class SolaraBook extends StatefulWidget {
  const SolaraBook({
    super.key,
    required this.onOpenSummary,
    required this.onClose,
    this.sections = bookSections,
    this.initialLesson = BookLesson.rules,
  });
  final Future<void> Function(BookLesson lesson) onOpenSummary;
  final VoidCallback onClose;
  final List<BookSection> sections;
  final BookLesson initialLesson;

  @override
  State<SolaraBook> createState() => _SolaraBookState();
}

class _SolaraBookState extends State<SolaraBook> {
  PageController _pages = PageController(keepPage: false);
  List<BookLeaf> _leaves = [];
  Object? _layout;
  int _layoutVersion = 0;
  int _page = 0;
  bool _opening = false;

  void _paginate(Size size, bool large) {
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    final signature = (size, large, scaler, direction, widget.sections);
    if (_layout == signature) return;
    final anchor = _leaves.isEmpty ? null : _leaves[_page];
    final next = paginateBook(
      sections: widget.sections,
      width: math.max(1, size.width - 4),
      height: math.max(1, size.height - 2),
      large: large,
      scaler: scaler,
      direction: direction,
    );
    var target = 0;
    if (anchor == null) {
      final first = next.indexWhere(
        (leaf) => widget.sections[leaf.section].lesson == widget.initialLesson,
      );
      if (first >= 0) target = first;
    }
    if (anchor != null) {
      for (var i = 0; i < next.length; i++) {
        if (next[i].section == anchor.section &&
            (next[i].block < anchor.block ||
                next[i].block == anchor.block &&
                    next[i].offset <= anchor.offset)) {
          target = i;
        }
      }
    }
    final previous = _pages;
    _pages = PageController(initialPage: target, keepPage: false);
    _leaves = next;
    _page = target;
    _layout = signature;
    _layoutVersion++;
    WidgetsBinding.instance.addPostFrameCallback((_) => previous.dispose());
  }

  void _turn(int page) {
    if (page < 0 || page >= _leaves.length || page == _page) return;
    GameFeedbackScope.tap(context);
    final reduced =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    if (reduced) {
      _pages.jumpToPage(page);
    } else {
      _pages.animateToPage(
        page,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _openSummary(BookLesson lesson) async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      await widget.onOpenSummary(lesson);
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Widget _paper(bool large) => LayoutBuilder(
    builder: (context, bounds) {
      _paginate(
        Size(bounds.maxWidth, math.max(1.0, bounds.maxHeight - 60)),
        large,
      );
      final version = _layoutVersion;
      return Column(
        children: [
          Expanded(
            child: KeyedSubtree(
              key: ValueKey(_layoutVersion),
              child: PageView.builder(
                key: const ValueKey('book-pages'),
                controller: _pages,
                itemCount: _leaves.length,
                onPageChanged: (page) {
                  if (version == _layoutVersion && page < _leaves.length) {
                    setState(() => _page = page);
                  }
                },
                itemBuilder: (context, page) => _LeafPage(
                  leaf: _leaves[page],
                  section: widget.sections[_leaves[page].section],
                  onOpenSummary: _opening
                      ? null
                      : () => _openSummary(
                          widget.sections[_leaves[page].section].lesson,
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const _GoldRule(),
          SizedBox(
            height: 48,
            child: Row(
              children: [
                _PageArrow(
                  key: const ValueKey('book-previous'),
                  forward: false,
                  onPressed: _page == 0 ? null : () => _turn(_page - 1),
                ),
                Expanded(
                  child: Semantics(
                    liveRegion: true,
                    label: 'Página ${_page + 1} de ${_leaves.length}',
                    excludeSemantics: true,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: BookPrintedInk(
                        child: Text(
                          '${_page + 1} / ${_leaves.length}',
                          key: const ValueKey('book-page-number'),
                          style: bookText(17),
                        ),
                      ),
                    ),
                  ),
                ),
                _PageArrow(
                  key: const ValueKey('book-next'),
                  forward: true,
                  onPressed: _page >= _leaves.length - 1
                      ? null
                      : () => _turn(_page + 1),
                ),
              ],
            ),
          ),
        ],
      );
    },
  );

  @override
  Widget build(BuildContext context) => BookPrintMaterial(
    child: Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
          child: LayoutBuilder(
            builder: (context, bounds) {
              final width = math.min(bounds.maxWidth, 620.0);
              final short = bounds.maxHeight < 450;
              final paperPadding = EdgeInsets.fromLTRB(
                76,
                short ? 16 : 32,
                48,
                short ? 28 : 76,
              );
              const exitPadding = EdgeInsets.symmetric(vertical: 4);
              final exitHeight =
                  math.max(
                    70.0,
                    bookTextHeight(
                          'Salir',
                          homeText(22),
                          width,
                          MediaQuery.textScalerOf(context),
                          Directionality.of(context),
                        ) +
                        27,
                  ) +
                  exitPadding.vertical;
              return Center(
                child: SizedBox(
                  width: width,
                  height: math.min(
                    bounds.maxHeight,
                    width * 1.5 + exitHeight + 8,
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: CallbackShortcuts(
                          bindings: {
                            const SingleActivator(
                              LogicalKeyboardKey.arrowLeft,
                            ): () =>
                                _turn(_page - 1),
                            const SingleActivator(
                              LogicalKeyboardKey.arrowRight,
                            ): () =>
                                _turn(_page + 1),
                            const SingleActivator(LogicalKeyboardKey.escape):
                                widget.onClose,
                          },
                          child: Focus(
                            autofocus: true,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                const IgnorePointer(
                                  child: UiSurfaceArt(UiSurface.solaraBook),
                                ),
                                Padding(
                                  padding: paperPadding,
                                  child: const BookPaperGrain(),
                                ),
                                Padding(
                                  padding: paperPadding,
                                  child: _paper(width >= 500 && !short),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      IllustratedActionButton(
                        key: const ValueKey('book-exit'),
                        label: 'Salir',
                        compact: true,
                        fontSize: 22,
                        showPlayIcon: false,
                        fitToLabel: true,
                        hitPadding: exitPadding,
                        onPressed: widget.onClose,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    ),
  );
}

class _LeafPage extends StatelessWidget {
  const _LeafPage({
    required this.leaf,
    required this.section,
    required this.onOpenSummary,
  });
  final BookLeaf leaf;
  final BookSection section;
  final Future<void> Function()? onOpenSummary;

  List<Widget> _content(Iterable<BookLeafPart> parts) => [
    for (final part in parts) ...[
      if (part.gap > 0) SizedBox(height: part.gap),
      if (part.kind == BookBlockKind.illustration)
        SizedBox(
          height: part.height,
          child: BookIllustration(lesson: section.lesson),
        )
      else if (part.kind == BookBlockKind.summary)
        Align(
          alignment: Alignment.center,
          child: SizedBox.square(
            dimension: part.height,
            child: _SummaryPicture(
              lesson: section.lesson,
              onPressed: onOpenSummary,
            ),
          ),
        )
      else
        BookPrintedInk(
          child: Text(
            part.text,
            style: part.style,
            textAlign:
                part.kind == BookBlockKind.coverTitle ||
                    part.kind == BookBlockKind.eyebrow
                ? TextAlign.center
                : TextAlign.start,
          ),
        ),
    ],
  ];

  @override
  Widget build(BuildContext context) {
    final headings = leaf.parts
        .takeWhile(
          (part) => switch (part.kind) {
            BookBlockKind.eyebrow ||
            BookBlockKind.coverTitle ||
            BookBlockKind.title => true,
            _ => false,
          },
        )
        .toList();
    return Semantics(
      key: ValueKey('book-section-${leaf.section + 1}'),
      label: section.title,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ..._content(headings),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _content(leaf.parts.skip(headings.length)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryPicture extends StatelessWidget {
  const _SummaryPicture({required this.lesson, required this.onPressed});
  final BookLesson lesson;
  final Future<void> Function()? onPressed;

  @override
  Widget build(BuildContext context) => JuicyPress(
    key: const ValueKey('book-summary'),
    label: lesson == BookLesson.notes
        ? 'Ver el resumen animado de las anotaciones'
        : 'Ver el resumen animado de las reglas del sudoku',
    onPressed: onPressed,
    onFeedback: () => GameFeedbackScope.tap(context),
    builder: (context, _) => Padding(
      padding: const EdgeInsets.all(8),
      child: Transform.rotate(
        angle: -.035,
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            DecoratedBox(
              decoration: const BoxDecoration(
                color: Color(0xFFFFFCF0),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x333C2B13),
                    blurRadius: 7,
                    offset: Offset(1, 3),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    Expanded(
                      child: Stack(
                        fit: StackFit.expand,
                        alignment: Alignment.center,
                        children: [
                          Positioned.fill(
                            child: ClipRect(
                              child: BookIllustration(
                                lesson: lesson,
                                softEdges: false,
                              ),
                            ),
                          ),
                          Center(
                            child: _BookRoundArt(
                              size: 48,
                              icon: Transform.translate(
                                // Balance the visual weight of the triangle.
                                offset: const Offset(1, 0),
                                child: const HomeIcon(HomeGlyph.play, size: 20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 7),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Ver resumen',
                        maxLines: 1,
                        style: homeText(18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 10,
              top: -3,
              child: Transform.rotate(
                angle: -.22,
                child: Container(
                  width: 42,
                  height: 13,
                  decoration: BoxDecoration(
                    color: const Color(0xBBDDCA93),
                    border: Border.all(
                      color: const Color(0x55937A46),
                      width: .5,
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
}

class _GoldRule extends StatelessWidget {
  const _GoldRule();
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 1,
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFD5AD5B).withValues(alpha: 0),
            const Color(0xFFCB9C41),
            const Color(0xFFD5AD5B).withValues(alpha: 0),
          ],
        ),
      ),
    ),
  );
}

class _PageArrow extends StatelessWidget {
  const _PageArrow({super.key, required this.forward, this.onPressed});
  final bool forward;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: forward ? 'Página siguiente' : 'Página anterior',
    onPressed: onPressed,
    iconSize: 44,
    alignment: Alignment.center,
    visualDensity: VisualDensity.standard,
    constraints: const BoxConstraints.tightFor(width: 48, height: 48),
    padding: const EdgeInsets.all(2),
    icon: Opacity(
      opacity: onPressed == null ? .25 : 1,
      child: _BookRoundArt(
        size: 44,
        icon: Transform.flip(
          flipX: !forward,
          child: const MapIcon(MapGlyph.chevron, size: 20),
        ),
      ),
    ),
  );
}

class _BookRoundArt extends StatelessWidget {
  const _BookRoundArt({required this.size, required this.icon});
  final double size;
  final Widget icon;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: Stack(
      fit: StackFit.expand,
      children: [
        const UiSurfaceArt(UiSurface.goldRound),
        Center(child: icon),
      ],
    ),
  );
}
