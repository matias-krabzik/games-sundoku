import 'package:flutter/material.dart';

import '../widgets/app_version_label.dart';
import '../widgets/external_link_button.dart';
import '../widgets/home_art.dart';
import '../widgets/illustrated_action_button.dart';
import '../widgets/settings_art.dart';

Future<void> showSunDokuAbout(BuildContext context) => showDialog<void>(
  context: context,
  barrierLabel: 'Cerrar acerca de SunDoku',
  builder: (context) => const _AboutDialog(),
);

class _AboutDialog extends StatelessWidget {
  const _AboutDialog();

  @override
  Widget build(BuildContext context) => Dialog(
    key: const ValueKey('about-dialog'),
    backgroundColor: Colors.transparent,
    insetPadding: const EdgeInsets.all(16),
    child: LayoutBuilder(
      builder: (context, bounds) => SizedBox(
        width: bounds.maxWidth.clamp(0.0, 460.0),
        height: bounds.maxHeight.clamp(0.0, 650.0),
        child: SettingsPanelSurface(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, contentBounds) => SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: contentBounds.maxHeight,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/sundoku-logo.png',
                              width: 250,
                              height: 105,
                              fit: BoxFit.contain,
                              semanticLabel: 'SunDoku',
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Un número a la vez, un nuevo logro.',
                              textAlign: TextAlign.center,
                              style: homeText(24),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Juega con los números, descubre patrones y resuelve '
                              'sudokus a tu ritmo. Con un poco de atención y práctica, '
                              'cada desafío se vuelve una nueva conquista.',
                              textAlign: TextAlign.center,
                              style: homeText(
                                18,
                                weight: FontWeight.w500,
                              ).copyWith(height: 1.3),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Creado por',
                              style: homeText(16, weight: FontWeight.w500),
                            ),
                            const SizedBox(height: 10),
                            Image.asset(
                              'assets/images/krabzik-games-logo-pixel.png',
                              width: 210,
                              fit: BoxFit.contain,
                              semanticLabel: 'Krabzik Games',
                            ),
                            const ExternalLinkButton(
                              key: ValueKey('about-studio-link'),
                              label: 'games.krabzik.com',
                              url: 'https://games.krabzik.com',
                            ),
                            const SizedBox(height: 8),
                            AppVersionLabel(
                              style: homeText(15, weight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SafeArea(
                  top: false,
                  child: IllustratedActionButton(
                    key: const ValueKey('about-back'),
                    label: 'Volver',
                    compact: true,
                    showPlayIcon: false,
                    fontSize: 25,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
