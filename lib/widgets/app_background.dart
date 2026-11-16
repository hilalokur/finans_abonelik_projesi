import 'package:flutter/material.dart';

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
  Widget build(BuildContext context) {
    // Arka plan seçenekleri şimdilik devre dışı: her zaman koyu mor galaksi.
    return Stack(
      children: [
        Positioned.fill(child: Image.asset(imagePath, fit: BoxFit.cover)),
        Positioned.fill(
          child: DecoratedBox(decoration: BoxDecoration(color: overlayColor)),
        ),
        if (premiumDarkGradient)
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
  }
}
