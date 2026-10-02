import 'dart:async';

import 'package:flutter/material.dart';

import 'illustrated_action_button.dart';

/// Secondary tutorial exit using the existing blue surface and separate icon.
class SkipTutorialButton extends StatelessWidget {
  const SkipTutorialButton({super.key, required this.onPressed});

  final FutureOr<void> Function()? onPressed;

  @override
  Widget build(BuildContext context) => IllustratedActionButton(
    label: 'Saltar tutorial',
    fontSize: 20,
    secondary: true,
    showPlayIcon: false,
    leadingIcon: Image.asset(
      'assets/images/tutorial/skip-tutorial-icon.png',
      width: 32,
      height: 28,
      fit: BoxFit.contain,
      excludeFromSemantics: true,
    ),
    contentPadding: const EdgeInsets.fromLTRB(19, 6, 19, 12),
    onPressed: onPressed,
  );
}
