import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../screens/home_screen.dart';
import '../theme.dart';

@Preview(name: 'Inicio · teléfono', group: 'SunDoku', size: Size(390, 844))
@Preview(name: 'Inicio · compacto', group: 'SunDoku', size: Size(320, 568))
@Preview(name: 'Inicio · horizontal', group: 'SunDoku', size: Size(844, 390))
Widget homePreview() => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: buildSunDokuTheme(),
  home: const HomeScreen(availableLevel: 4, unlockedLevels: 4),
);
