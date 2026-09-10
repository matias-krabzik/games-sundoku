import 'package:flutter/material.dart';

import '../theme.dart';

/// Shows a brief, non-interactive toast near the bottom of the screen.
void showToast(BuildContext context, String message) {
  final OverlayState overlay = Overlay.of(context);
  bool removed = false;
  late OverlayEntry entry;

  void remove() {
    if (removed) return;
    removed = true;
    entry.remove();
  }

  entry = OverlayEntry(
    builder: (BuildContext context) => Positioned(
      left: 0,
      right: 0,
      bottom: 96,
      child: IgnorePointer(
        child: Center(child: _Toast(message: message, onDone: remove)),
      ),
    ),
  );
  overlay.insert(entry);
}

class _Toast extends StatefulWidget {
  const _Toast({required this.message, required this.onDone});

  final String message;
  final VoidCallback onDone;

  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> {
  double _opacity = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _opacity = 1);
    });
    Future<void>.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _opacity = 0);
    });
    Future<void>.delayed(const Duration(milliseconds: 2000), widget.onDone);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _opacity,
      duration: const Duration(milliseconds: 220),
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: kSunFace.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            widget.message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
