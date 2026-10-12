import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../theme.dart';
import '../data/tutorial_book.dart';
import '../widgets/solara_book.dart';

@Preview(name: 'Libro · teléfono', group: 'SunDoku', size: Size(390, 844))
@Preview(name: 'Libro · compacto', group: 'SunDoku', size: Size(320, 568))
@Preview(name: 'Libro · horizontal', group: 'SunDoku', size: Size(844, 390))
@Preview(name: 'Libro · iPad', group: 'SunDoku', size: Size(834, 1210))
Widget bookPreview() => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: buildSunDokuTheme(),
  home: ColoredBox(
    color: const Color(0xFF263848),
    child: SolaraBook(onOpenSummary: (_) async {}, onClose: () {}),
  ),
);

@Preview(
  name: 'Libro · notas · teléfono',
  group: 'SunDoku',
  size: Size(390, 844),
)
@Preview(name: 'Libro · notas · iPad', group: 'SunDoku', size: Size(834, 1210))
Widget notesBookPreview() => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: buildSunDokuTheme(),
  home: ColoredBox(
    color: const Color(0xFF263848),
    child: SolaraBook(
      sections: const [...bookSections, ...notesBookSections],
      initialLesson: BookLesson.notes,
      onOpenSummary: (_) async {},
      onClose: () {},
    ),
  ),
);
