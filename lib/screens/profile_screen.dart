import 'dart:ui';

import 'package:flutter/material.dart';

import '../data/repositories/game_repository.dart';
import '../widgets/game_feedback_scope.dart';
import '../widgets/home_art.dart';
import '../widgets/juicy_press.dart';
import '../widgets/settings_art.dart';

class ProfileRoute extends RawDialogRoute<void> {
  ProfileRoute({required GameRepository repository, super.settings})
    : super(
        barrierColor: const Color(0x65082045),
        barrierDismissible: true,
        barrierLabel: 'Cerrar perfil',
        transitionDuration: const Duration(milliseconds: 420),
        pageBuilder: (context, animation, secondaryAnimation) =>
            ProfileScreen(repository: repository),
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          final reduced = MediaQuery.disableAnimationsOf(context);
          final entering = animation.status != AnimationStatus.reverse;
          final curve = entering ? Curves.easeOutBack : Curves.easeInCubic;
          final progress = reduced ? 1.0 : curve.transform(animation.value);
          return Stack(
            fit: StackFit.expand,
            children: [
              IgnorePointer(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 2 * animation.value,
                    sigmaY: 2 * animation.value,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
              FadeTransition(
                opacity: animation,
                child: Transform.translate(
                  offset: Offset(0, (1 - progress) * 28),
                  child: Transform.scale(
                    scale: .88 + .12 * progress,
                    child: child,
                  ),
                ),
              ),
            ],
          );
        },
      );

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 210);
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.repository});

  final GameRepository repository;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _name = TextEditingController(
    text: widget.repository.state.player.nameChosen
        ? widget.repository.state.player.name
        : '',
  );
  bool _saving = false;
  bool _closing = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _close() {
    if (_saving || _closing) return;
    _closing = true;
    Navigator.of(context).pop();
  }

  Future<void> _save() async {
    if (_saving || _closing) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository.setPlayerName(_name.text);
      if (!mounted) return;
      setState(() => _saving = false);
      GameFeedbackScope.tap(context);
      _close();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'No pudimos guardar tu nombre. Volvé a intentarlo.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: SafeArea(
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: LayoutBuilder(
          builder: (context, viewport) => Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: (viewport.maxWidth - 24).clamp(0, 440),
                maxHeight: (viewport.maxHeight - 24).clamp(0, double.infinity),
              ),
              child: Semantics(
                scopesRoute: true,
                explicitChildNodes: true,
                namesRoute: true,
                label: 'Tu perfil',
                child: Material(
                  type: MaterialType.transparency,
                  child: SettingsPanelSurface(
                    child: SingleChildScrollView(
                      key: const ValueKey('profile-scroll'),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const HomeIcon(HomeGlyph.user, size: 38),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Tu perfil',
                                  style: _text(28, weight: FontWeight.w800),
                                ),
                              ),
                              SizedBox.square(
                                dimension: 46,
                                child: JuicyPress(
                                  key: const ValueKey('profile-close'),
                                  label: 'Cerrar perfil',
                                  onPressed: _saving ? null : _close,
                                  onFeedback: () =>
                                      GameFeedbackScope.tap(context),
                                  builder: (context, depression) =>
                                      SettingsGoldSurface(
                                        circular: true,
                                        depression: depression,
                                        child: const SettingsIcon(
                                          SettingsGlyph.close,
                                          size: 28,
                                        ),
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Text('¿Cómo te llamás?', style: _text(20)),
                          const SizedBox(height: 12),
                          TextField(
                            key: const ValueKey('profile-name'),
                            controller: _name,
                            enabled: !_saving,
                            style: _text(22, weight: FontWeight.w700),
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _save(),
                            decoration: InputDecoration(
                              labelText: 'Nombre',
                              hintText: 'Jugador',
                              filled: true,
                              fillColor: const Color(0xFFFFFEF9),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 18,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE3BD74),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE3BD74),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Si lo dejás vacío, te llamaremos Jugador.',
                            style: _text(15),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Semantics(
                              liveRegion: true,
                              child: Text(
                                _error!,
                                style: _text(15)
                                    .copyWith(color: const Color(0xFF9A401B)),
                              ),
                            ),
                          ],
                          const SizedBox(height: 22),
                          SizedBox(
                            height: 66,
                            child: JuicyPress(
                              key: const ValueKey('profile-save'),
                              label: _saving ? 'Guardando nombre' : 'Guardar',
                              onPressed: _saving ? null : _save,
                              builder: (context, depression) =>
                                  SettingsGoldSurface(
                                    depression: depression,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const SettingsIcon(
                                          SettingsGlyph.check,
                                          size: 30,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          _saving ? 'Guardando…' : 'Guardar',
                                          style: _text(
                                            30,
                                            weight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  TextStyle _text(double size, {FontWeight weight = FontWeight.w600}) =>
      TextStyle(
        color: settingsNavy,
        fontFamily: 'Baloo2',
        fontSize: size,
        fontWeight: weight,
      );
}
