import 'dart:ui';

import 'package:flutter/material.dart';

import '../data/repositories/game_repository.dart';
import '../domain/models/player_profile.dart';
import '../widgets/game_feedback_scope.dart';
import '../widgets/juicy_press.dart';
import '../widgets/settings_art.dart';
import '../widgets/ui_surface_art.dart';

/// A non-opaque route keeps the actual home screen visible behind the panel.
class SettingsRoute extends RawDialogRoute<void> {
  SettingsRoute({required GameRepository repository, super.settings})
    : super(
        barrierColor: const Color(0x65082045),
        barrierDismissible: true,
        barrierLabel: 'Cerrar configuración',
        transitionDuration: const Duration(milliseconds: 420),
        pageBuilder: (context, animation, secondaryAnimation) =>
            SettingsScreen(repository: repository),
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

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.repository});
  final GameRepository repository;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  GameSettings? _optimistic;
  bool _saving = false;
  bool _closing = false;
  String? _error;

  Future<void> _save({bool? sound, bool? music, bool? vibration}) async {
    if (_saving) return;
    final old = widget.repository.state.settings;
    setState(() {
      _saving = true;
      _error = null;
      _optimistic = GameSettings(
        sound: sound ?? old.sound,
        music: music ?? old.music,
        vibration: vibration ?? old.vibration,
        extra: old.extra,
      );
    });
    try {
      await widget.repository.updateSettings(
        sound: sound,
        music: music,
        vibration: vibration,
      );
      if (mounted) GameFeedbackScope.tap(context);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'No pudimos guardar el ajuste. Volvé a intentarlo.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
          _optimistic = null;
        });
      }
    }
  }

  void _close() {
    if (_saving || _closing) return;
    _closing = true;
    Navigator.of(context).pop();
  }

  void _about() {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: SettingsPanelSurface(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: DefaultTextStyle(
                  style: _text(18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/sundoku-logo.png',
                        width: 210,
                        height: 88,
                        fit: BoxFit.contain,
                        semanticLabel: 'SunDoku',
                      ),
                      Text(
                        'Un poquito de sol,\nun nuevo desafío.',
                        textAlign: TextAlign.center,
                        style: _text(22, weight: FontWeight.w800),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Resolvé sudokus y acompañá a Doku en su aventura.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text('Versión 1.0.0', style: _text(15)),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 64,
                        width: double.infinity,
                        child: JuicyPress(
                          label: 'Volver a configuración',
                          onPressed: () => Navigator.of(context).pop(),
                          onFeedback: () => GameFeedbackScope.tap(context),
                          builder: (context, depression) => SettingsGoldSurface(
                            depression: depression,
                            child: Text(
                              'Volver',
                              style: _text(27, weight: FontWeight.w800),
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
    );
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: SafeArea(
      child: LayoutBuilder(
        builder: (context, viewport) {
          final narrow = viewport.maxWidth < 360;
          final short = viewport.maxHeight < 600;
          final panelWidth = (viewport.maxWidth * .93).clamp(0.0, 520.0);
          final panelHeight = (viewport.maxHeight * .86).clamp(0.0, 820.0);
          final inset = narrow ? 13.0 : 19.0;
          return Center(
            child: SizedBox(
              width: panelWidth,
              height: panelHeight,
              child: Semantics(
                scopesRoute: true,
                explicitChildNodes: true,
                namesRoute: true,
                label: 'Configuración',
                child: Material(
                  type: MaterialType.transparency,
                  child: SettingsPanelSurface(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        inset,
                        short ? 14 : 22,
                        inset,
                        short ? 10 : 16,
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              SettingsIcon(
                                SettingsGlyph.gear,
                                size: narrow ? 29 : 36,
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Configuración',
                                    style: _text(30, weight: FontWeight.w800),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox.square(
                                dimension: 46,
                                child: JuicyPress(
                                  key: const ValueKey('settings-close'),
                                  label: 'Cerrar configuración',
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
                          SizedBox(height: short ? 3 : 7),
                          Text(
                            'A tu manera, a tu ritmo',
                            textAlign: TextAlign.center,
                            style: _text(
                              narrow ? 15 : 17,
                              weight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: short ? 10 : 19),
                          Expanded(
                            child: ListenableBuilder(
                              listenable: widget.repository,
                              builder: (context, _) {
                                final settings =
                                    _optimistic ??
                                    widget.repository.state.settings;
                                return LayoutBuilder(
                                  builder: (context, body) =>
                                      SingleChildScrollView(
                                        key: const ValueKey('settings-scroll'),
                                        child: ConstrainedBox(
                                          constraints: BoxConstraints(
                                            minHeight: body.maxHeight,
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              _group('SONIDO', [
                                                _toggle(
                                                  'Música',
                                                  SettingsGlyph.music,
                                                  settings.music,
                                                  () => _save(
                                                    music: !settings.music,
                                                  ),
                                                ),
                                                _toggle(
                                                  'Efectos de sonido',
                                                  SettingsGlyph.sound,
                                                  settings.sound,
                                                  () => _save(
                                                    sound: !settings.sound,
                                                  ),
                                                ),
                                              ]),
                                              _group('PREFERENCIAS', [
                                                _toggle(
                                                  'Vibración',
                                                  SettingsGlyph.vibration,
                                                  settings.vibration,
                                                  () => _save(
                                                    vibration:
                                                        !settings.vibration,
                                                  ),
                                                ),
                                              ]),
                                              const Padding(
                                                padding: EdgeInsets.only(
                                                  bottom: 10,
                                                ),
                                                child: Divider(
                                                  height: 1,
                                                  color: Color(0xFFE9CFA4),
                                                ),
                                              ),
                                              _settingRow(
                                                label: 'Acerca de SunDoku',
                                                icon: SettingsGlyph.info,
                                                onPressed: _about,
                                                trailing: const SettingsIcon(
                                                  SettingsGlyph.chevron,
                                                  size: 25,
                                                ),
                                              ),
                                              if (_error != null)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 8,
                                                      ),
                                                  child: Semantics(
                                                    liveRegion: true,
                                                    child: Text(
                                                      _error!,
                                                      style: _text(14).copyWith(
                                                        color: const Color(
                                                          0xFF9A401B,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              const SizedBox(height: 8),
                                            ],
                                          ),
                                        ),
                                      ),
                                );
                              },
                            ),
                          ),
                          SizedBox(height: short ? 8 : 16),
                          SizedBox(
                            width: double.infinity,
                            height: short ? 60 : 72,
                            child: JuicyPress(
                              key: const ValueKey('settings-done'),
                              label: 'Listo',
                              onPressed: _saving ? null : _close,
                              onFeedback: () => GameFeedbackScope.tap(context),
                              builder: (context, depression) =>
                                  SettingsGoldSurface(
                                    depression: depression,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const SettingsIcon(
                                          SettingsGlyph.check,
                                          size: 36,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Listo',
                                          style: _text(
                                            short ? 31 : 36,
                                            weight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                            ),
                          ),
                          SizedBox(height: short ? 4 : 8),
                          Text(
                            'SunDoku · v1.0.0',
                            style: _text(13).copyWith(
                              color: settingsNavy.withValues(alpha: .75),
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
        },
      ),
    ),
  );

  Widget _group(String title, List<Widget> rows) => Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 5, bottom: 9),
          child: Text(
            title,
            style: _text(
              17,
              weight: FontWeight.w800,
            ).copyWith(letterSpacing: .4),
          ),
        ),
        for (var i = 0; i < rows.length; i++) ...[
          if (i != 0) const SizedBox(height: 10),
          rows[i],
        ],
      ],
    ),
  );

  Widget _toggle(
    String label,
    SettingsGlyph icon,
    bool enabled,
    VoidCallback action,
  ) => _settingRow(
    label: label,
    icon: icon,
    toggled: enabled,
    onPressed: _saving ? null : action,
    trailing: _SunSwitch(value: enabled),
  );

  Widget _settingRow({
    required String label,
    required SettingsGlyph icon,
    required Widget trailing,
    required VoidCallback? onPressed,
    bool? toggled,
  }) => JuicyPress(
    key: ValueKey('setting-$label'),
    label: label,
    toggled: toggled,
    onPressed: onPressed,
    onFeedback: toggled == null ? () => GameFeedbackScope.tap(context) : null,
    builder: (context, depression) => UiSurfacePanel(
      constraints: const BoxConstraints(minHeight: 67),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          SettingsIcon(icon, size: 34),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: _text(19, weight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    ),
  );
}

TextStyle _text(double size, {FontWeight weight = FontWeight.w600}) =>
    TextStyle(
      fontFamily: 'Baloo2',
      fontSize: size,
      fontWeight: weight,
      height: 1.15,
      color: settingsNavy,
    );

class _SunSwitch extends StatelessWidget {
  const _SunSwitch({required this.value});
  final bool value;

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 260);
    return AnimatedContainer(
      duration: duration,
      width: 68,
      height: 37,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: value ? const Color(0xFFFAC01D) : const Color(0xFFB1A791),
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: value
              ? [const Color(0xFFFFE344), const Color(0xFFFFBD09)]
              : [const Color(0xFFBEB5A3), const Color(0xFFD8CFBE)],
        ),
      ),
      child: AnimatedAlign(
        duration: duration,
        curve: Curves.easeOutBack,
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 29,
          height: 29,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFFFFE), Color(0xFFFFEDCC)],
            ),
            border: Border.all(color: const Color(0xFFFFFEF5)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x55A56808),
                blurRadius: 3,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              value ? 'I' : 'O',
              style: _text(
                10,
                weight: FontWeight.w800,
              ).copyWith(color: const Color(0xFF8B754C)),
            ),
          ),
        ),
      ),
    );
  }
}
