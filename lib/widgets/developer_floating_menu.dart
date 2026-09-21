import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

class DeveloperMenuAction {
  const DeveloperMenuAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.key,
  });

  final String label;
  final IconData icon;
  final FutureOr<void> Function() onPressed;
  final Key? key;
}

/// Movable development control shared by the home, map and tutorial screens.
class DeveloperFloatingMenu extends StatefulWidget {
  const DeveloperFloatingMenu({
    super.key,
    required this.actions,
    this.title = 'Herramientas DEV',
  });

  final List<DeveloperMenuAction> actions;
  final String title;

  @override
  State<DeveloperFloatingMenu> createState() => _DeveloperFloatingMenuState();
}

class _DeveloperFloatingMenuState extends State<DeveloperFloatingMenu> {
  static const _size = 48.0;
  static const _margin = 16.0;
  Offset? _position;

  Offset _clamp(Offset value, BoxConstraints bounds) {
    final maxX = math.max(_margin, bounds.maxWidth - _size - _margin);
    final maxY = math.max(_margin, bounds.maxHeight - _size - _margin);
    return Offset(
      value.dx.clamp(_margin, maxX).toDouble(),
      value.dy.clamp(_margin, maxY).toDouble(),
    );
  }

  Future<void> _openMenu() async {
    final selected = await showDialog<DeveloperMenuAction>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        key: const ValueKey('dev-menu-dialog'),
        backgroundColor: const Color(0xFFF0F1F2),
        surfaceTintColor: Colors.transparent,
        title: Text(widget.title),
        contentPadding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final action in widget.actions)
              ListTile(
                key: action.key,
                leading: Icon(action.icon, color: const Color(0xFF555A60)),
                title: Text(action.label),
                onTap: () => Navigator.of(dialogContext).pop(action),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
    if (selected != null) await selected.onPressed();
  }

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: SafeArea(
      child: LayoutBuilder(
        builder: (context, bounds) {
          final initial = Offset(
            bounds.maxWidth - _size - _margin,
            bounds.maxHeight - _size - _margin,
          );
          final position = _clamp(_position ?? initial, bounds);
          return Stack(
            children: [
              Positioned(
                left: position.dx,
                top: position.dy,
                width: _size,
                height: _size,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      _position = _clamp(position + details.delta, bounds);
                    });
                  },
                  child: Material(
                    key: const ValueKey('dev-floating-button'),
                    color: const Color(0xB05B6066),
                    shape: const CircleBorder(
                      side: BorderSide(color: Color(0x996F747A)),
                    ),
                    elevation: 4,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _openMenu,
                      child: const Center(
                        child: Text(
                          'DEV',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
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
