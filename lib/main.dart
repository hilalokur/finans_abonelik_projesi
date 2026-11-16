import 'dart:async';

import 'package:flutter/material.dart';

import 'package:finans_abonelik_projesi/screens/auth/splash_screen.dart';
import 'package:finans_abonelik_projesi/services/currency_service.dart';
import 'package:finans_abonelik_projesi/services/app_preferences.dart';
import 'package:finans_abonelik_projesi/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppPreferences.instance.loadLastAccent();
  unawaited(() async {
    await CurrencyService.instance.loadCache();
    await CurrencyService.instance.refreshRates();
  }());
  runApp(const SubtrackApp());
}

class SubtrackApp extends StatelessWidget {
  const SubtrackApp({super.key});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: AppPreferences.instance,
    builder: (context, _) {
      final accent = AppPreferences.instance.accentColor;
      return MaterialApp(
        title: 'Abonelik ve Finans Takip Sistemi',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkThemeWith(
          accent,
          animationsEnabled: AppPreferences.instance.animations,
        ),
        builder: (context, child) =>
            _AccentRebuilder(child: child ?? const SizedBox.shrink()),
        home: const SplashScreen(),
      );
    },
  );
}

/// Vurgu rengi değiştiğinde, rengi doğrudan `AppColors.primaryLight` üzerinden
/// okuyan (const önbellekli) widget'ların da anında yenilenmesini sağlar.
class _AccentRebuilder extends StatefulWidget {
  const _AccentRebuilder({required this.child});

  final Widget child;

  @override
  State<_AccentRebuilder> createState() => _AccentRebuilderState();
}

class _AccentRebuilderState extends State<_AccentRebuilder> {
  late Color _accent = AppPreferences.instance.accentColor;

  @override
  void initState() {
    super.initState();
    AppPreferences.instance.addListener(_onPreferencesChanged);
  }

  @override
  void dispose() {
    AppPreferences.instance.removeListener(_onPreferencesChanged);
    super.dispose();
  }

  void _onPreferencesChanged() {
    final accent = AppPreferences.instance.accentColor;
    if (accent == _accent || !mounted) return;
    _accent = accent;
    void rebuild(Element element) {
      element.markNeedsBuild();
      element.visitChildren(rebuild);
    }

    (context as Element).visitChildren(rebuild);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
