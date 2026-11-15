import 'dart:async';

import 'package:flutter/material.dart';

import 'package:finans_abonelik_projesi/screens/auth/splash_screen.dart';
import 'package:finans_abonelik_projesi/services/currency_service.dart';
import 'package:finans_abonelik_projesi/services/app_preferences.dart';
import 'package:finans_abonelik_projesi/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
      final accent = switch (AppPreferences.instance.accent) {
        'silver' => const Color(0xFFD1D5DB),
        'violet' => const Color(0xFFA78BFA),
        'pinkLavender' => const Color(0xFFE9D5FF),
        _ => const Color(0xFFC4B5FD),
      };
      return MaterialApp(
        title: 'SUBTRACK',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkThemeWith(
          accent,
          animationsEnabled: AppPreferences.instance.animations,
        ),
        home: const SplashScreen(),
      );
    },
  );
}
