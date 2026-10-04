import 'package:flutter/material.dart';

import 'home_art.dart';
import 'tutorial_story.dart';

/// Shared explanation artwork, typography and writing for tutorial lessons.
class TutorialLessonCard extends StatelessWidget {
  const TutorialLessonCard({
    super.key,
    required this.message,
    required this.messageKey,
    this.progress,
    this.footer,
    this.onFinished,
    this.controller,
    this.autoplay = true,
  });

  final String message;
  final String messageKey;
  final String? progress;
  final Widget? footer;
  final VoidCallback? onFinished;
  final TutorialStoryController? controller;
  final bool autoplay;

  static TextStyle get textStyle => homeText(20).copyWith(height: 1.3);

  @override
  Widget build(BuildContext context) => TutorialStory(
    key: ValueKey(messageKey),
    lines: [message, ?progress],
    tip: null,
    footer: footer,
    interactive: false,
    textStyle: textStyle,
    onFinished: onFinished,
    controller: controller,
    autoplay: autoplay,
  );
}
