import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'game_feedback_scope.dart';
import 'home_art.dart';
import '../playables/playables_sdk.dart';

class ExternalLinkButton extends StatefulWidget {
  const ExternalLinkButton({super.key, required this.label, required this.url});
  final String label;
  final String url;

  @override
  State<ExternalLinkButton> createState() => _ExternalLinkButtonState();
}

class _ExternalLinkButtonState extends State<ExternalLinkButton> {
  bool _failed = false;

  Future<void> _open() async {
    GameFeedbackScope.tap(context);
    var opened = false;
    try {
      opened = await launchUrl(
        Uri.parse(widget.url),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      // Keep the selectable address available when no browser can be opened.
    }
    if (mounted) setState(() => _failed = !opened);
  }

  @override
  Widget build(BuildContext context) => youtubePlayablesBuild
      ? Text(widget.label, style: homeText(16))
      : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton.icon(
              onPressed: _open,
              icon: const Icon(Icons.open_in_new, size: 18),
              label: Text(widget.label, style: homeText(16)),
            ),
            if (_failed) ...[
              Text(
                'No pudimos abrir el enlace. Puedes copiar esta dirección:',
                style: homeText(
                  16,
                  weight: FontWeight.w500,
                ).copyWith(height: 1.35),
              ),
              SelectableText(
                widget.url,
                style: homeText(
                  16,
                  weight: FontWeight.w500,
                ).copyWith(height: 1.35),
              ),
            ],
          ],
        );
}
