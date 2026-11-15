import 'package:flutter/material.dart';

import '../services/app_preferences.dart';
import '../theme/app_theme.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({
    super.key,
    required this.child,
    this.imagePath = 'assets/images/4.jpg',
    this.overlayColor = const Color(0x9909051B),
    this.premiumDarkGradient = false,
  });

  final Widget child;
  final String imagePath;
  final Color overlayColor;
  final bool premiumDarkGradient;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: AppPreferences.instance,
    builder: (context, _) {
      final choice = AppPreferences.instance.background;
      final asset = switch (choice) {
        'blueGalaxy' => 'assets/images/s3.jpg',
        'pinkGalaxy' => 'assets/images/login1.jpg',
        'purpleGalaxy' => imagePath,
        _ => null,
      };
      return Stack(
        children: [
          Positioned.fill(
            child: asset == null
                ? const ColoredBox(color: AppColors.background)
                : Image.asset(asset, fit: BoxFit.cover),
          ),
          if (asset != null)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(color: overlayColor),
              ),
            ),
          if (asset != null && premiumDarkGradient)
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0, .52, 1],
                    colors: [
                      Color(0x66050312),
                      Color(0x55050312),
                      Color(0x1A050312),
                    ],
                  ),
                ),
              ),
            ),
          Positioned.fill(child: child),
        ],
      );
    },
  );
}
