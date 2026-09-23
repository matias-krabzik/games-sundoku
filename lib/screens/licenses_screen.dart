import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/audio_credits.dart';
import '../widgets/external_link_button.dart';
import '../widgets/game_feedback_scope.dart';
import '../widgets/home_art.dart';
import '../widgets/illustrated_action_button.dart';
import '../widgets/juicy_press.dart';
import '../widgets/settings_art.dart';
import '../widgets/ui_surface_art.dart';

Future<void> showLicensesMenu(BuildContext context) => _showLicenseDialog(
  context,
  title: 'Licencias',
  maxHeight: 420,
  child: Builder(
    builder: (context) => ListView(
      children: [
        _LicenseChoice(
          label: 'Flutter y bibliotecas',
          description: 'Tecnología y tipografías de SunDoku',
          onPressed: () => _showLicenseDialog(
            context,
            title: 'Flutter y bibliotecas',
            child: const _SoftwareLicenses(),
          ),
        ),
        const SizedBox(height: 14),
        _LicenseChoice(
          label: 'Música y sonidos',
          description: 'Autores, créditos y condiciones de uso',
          onPressed: () => _showLicenseDialog(
            context,
            title: 'Música y sonidos',
            child: const _AudioLicenses(),
          ),
        ),
      ],
    ),
  ),
);

Future<void> _showLicenseDialog(
  BuildContext context, {
  required String title,
  required Widget child,
  double maxHeight = 760,
}) => showDialog<void>(
  context: context,
  barrierLabel: 'Cerrar licencias',
  builder: (context) => Dialog(
    key: const ValueKey('licenses-dialog'),
    backgroundColor: Colors.transparent,
    insetPadding: const EdgeInsets.all(16),
    child: LayoutBuilder(
      builder: (context, bounds) => SizedBox(
        width: bounds.maxWidth.clamp(0.0, 640.0),
        height: bounds.maxHeight.clamp(0.0, maxHeight),
        child: SettingsPanelSurface(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  title,
                  maxLines: bounds.maxHeight < 400 ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: homeText(25),
                ),
                const SizedBox(height: 16),
                Expanded(child: child),
                const SizedBox(height: 12),
                SafeArea(
                  top: false,
                  child: IllustratedActionButton(
                    key: const ValueKey('licenses-back'),
                    label: 'Volver',
                    fontSize: 23,
                    compact: true,
                    showPlayIcon: false,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  ),
);

class _LicenseChoice extends StatelessWidget {
  const _LicenseChoice({
    required this.label,
    required this.onPressed,
    this.description,
  });
  final String label;
  final String? description;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => JuicyPress(
    label: label,
    onPressed: onPressed,
    onFeedback: () => GameFeedbackScope.tap(context),
    builder: (context, _) => UiSurfacePanel(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: homeText(20)),
                if (description != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    description!,
                    style: homeText(
                      16,
                      weight: FontWeight.w500,
                    ).copyWith(height: 1.2),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          const SettingsIcon(SettingsGlyph.chevron, size: 24),
        ],
      ),
    ),
  );
}

Future<Map<String, List<LicenseEntry>>> _loadSoftwareLicenses() async {
  final result = <String, List<LicenseEntry>>{};
  await for (final entry in LicenseRegistry.licenses) {
    for (final package in entry.packages) {
      (result[package] ??= []).add(entry);
    }
  }
  final fontLicense = await rootBundle.loadString(
    'assets/fonts/OFL-Baloo2.txt',
  );
  result['Baloo 2'] = [
    LicenseEntryWithLineBreaks(['Baloo 2'], fontLicense),
  ];
  return result;
}

class _SoftwareLicenses extends StatefulWidget {
  const _SoftwareLicenses();
  @override
  State<_SoftwareLicenses> createState() => _SoftwareLicensesState();
}

class _SoftwareLicensesState extends State<_SoftwareLicenses> {
  late Future<Map<String, List<LicenseEntry>>> _licenses =
      _loadSoftwareLicenses();

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: _licenses,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return _LicenseLoadError(
          onRetry: () => setState(() => _licenses = _loadSoftwareLicenses()),
        );
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final licenses = snapshot.data!;
      final names = licenses.keys.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      return ListView.separated(
        itemCount: names.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final name = names[index];
          return _LicenseChoice(
            label: name,
            onPressed: () => _showLicenseDialog(
              context,
              title: name,
              child: _LicenseText(
                text: licenses[name]!
                    .map(
                      (entry) =>
                          entry.paragraphs.map((p) => p.text).join('\n\n'),
                    )
                    .join('\n\n────────────────\n\n'),
              ),
            ),
          );
        },
      );
    },
  );
}

class _AudioLicenses extends StatelessWidget {
  const _AudioLicenses();

  @override
  Widget build(BuildContext context) => ListView.separated(
    itemCount: audioCredits.length,
    separatorBuilder: (_, _) => const SizedBox(height: 16),
    itemBuilder: (context, index) {
      final credit = audioCredits[index];
      return UiSurfacePanel(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(credit.title, style: homeText(23)),
            const SizedBox(height: 8),
            SelectableText(credit.author, style: homeText(19)),
            if (credit.description != null) ...[
              const SizedBox(height: 12),
              SelectableText(credit.description!, style: _bodyStyle),
            ],
            const SizedBox(height: 12),
            SelectableText('Licencia: ${credit.license}', style: _bodyStyle),
            ExternalLinkButton(
              label: 'Fuente: ${Uri.parse(credit.sourceUrl).host}',
              url: credit.sourceUrl,
            ),
            if (credit.licenseAsset != null) ...[
              const SizedBox(height: 14),
              IllustratedActionButton(
                key: ValueKey('license-${credit.sourceUrl}'),
                label: 'Ver licencia',
                fontSize: 20,
                compact: true,
                showPlayIcon: false,
                onPressed: () => _showLicenseDialog(
                  context,
                  title: credit.license,
                  child: _LicenseAsset(
                    asset: credit.licenseAsset!,
                    licenseUrl: credit.licenseUrl,
                  ),
                ),
              ),
            ] else ...[
              ExternalLinkButton(label: 'Ver licencia', url: credit.licenseUrl),
            ],
          ],
        ),
      );
    },
  );
}

TextStyle get _bodyStyle =>
    homeText(16, weight: FontWeight.w500).copyWith(height: 1.35);

class _LicenseText extends StatelessWidget {
  const _LicenseText({required this.text, this.licenseUrl});
  final String text;
  final String? licenseUrl;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (licenseUrl != null) ...[
          ExternalLinkButton(label: 'Licencia oficial', url: licenseUrl!),
          const SizedBox(height: 12),
        ],
        SelectableText(text, style: _bodyStyle),
      ],
    ),
  );
}

class _LicenseAsset extends StatefulWidget {
  const _LicenseAsset({required this.asset, required this.licenseUrl});
  final String asset;
  final String licenseUrl;
  @override
  State<_LicenseAsset> createState() => _LicenseAssetState();
}

class _LicenseAssetState extends State<_LicenseAsset> {
  late Future<String> _text = rootBundle.loadString(widget.asset);
  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: _text,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return _LicenseLoadError(
          onRetry: () =>
              setState(() => _text = rootBundle.loadString(widget.asset)),
        );
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      return _LicenseText(text: snapshot.data!, licenseUrl: widget.licenseUrl);
    },
  );
}

class _LicenseLoadError extends StatelessWidget {
  const _LicenseLoadError({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Column(
      children: [
        Text('No pudimos cargar las licencias.', style: _bodyStyle),
        const SizedBox(height: 16),
        IllustratedActionButton(
          label: 'Reintentar',
          fontSize: 22,
          compact: true,
          onPressed: onRetry,
        ),
      ],
    ),
  );
}
