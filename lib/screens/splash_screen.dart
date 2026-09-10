import 'dart:async';

import 'package:flutter/material.dart';

import '../routes.dart';

/// The original SunDoku logo against its own quiet morning landscape.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  late final Animation<double> _scale = Tween<double>(
    begin: 0.82,
    end: 1,
  ).animate(CurvedAnimation(parent: _intro, curve: Curves.easeOutCubic));
  late final Animation<double> _opacity = Tween<double>(
    begin: 0.9,
    end: 1,
  ).animate(CurvedAnimation(parent: _intro, curve: Curves.easeOut));
  Timer? _timer;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _intro.value = 1;
    } else {
      _intro.forward();
    }
    _timer = Timer(const Duration(milliseconds: 2600), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.home);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/splash-background.png',
            fit: BoxFit.cover,
            excludeFromSemantics: true,
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => Align(
                alignment: const Alignment(0, -0.18),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: FadeTransition(
                    opacity: _opacity,
                    child: ScaleTransition(
                      scale: _scale,
                      child: Image.asset(
                        'assets/images/sundoku-logo.png',
                        width: (constraints.maxWidth * 0.84).clamp(0, 460),
                        height: constraints.maxHeight * 0.3,
                        fit: BoxFit.contain,
                        semanticLabel: 'SunDoku',
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
