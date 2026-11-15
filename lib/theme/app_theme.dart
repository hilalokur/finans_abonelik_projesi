import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF09051B);
  static const surface = Color(0xDD17102B);
  static const surfaceSolid = Color(0xFF17102B);
  static const surfaceAlt = Color(0x668B5CF6);
  static const primary = Color(0xFF8B5CF6);
  static const primaryLight = Color(0xFFC4B5FD);
  static const lavender = Color(0xFFE9D5FF);
  static const text = Color(0xFFFFFFFF);
  static const muted = Color(0xFFB8B2CC);
  static const cyan = Color(0xFFC4B5FD);
  static const success = Color(0xFFC4B5FD);
  static const danger = Color(0xFFE9D5FF);
  static const warning = Color(0xFFC4B5FD);
}

class AppTheme {
  static ThemeData get darkTheme => darkThemeWith(AppColors.primaryLight);

  static ThemeData darkThemeWith(
    Color accent, {
    bool animationsEnabled = true,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primary,
        secondary: accent,
        surface: AppColors.surfaceSolid,
        error: AppColors.lavender,
        onPrimary: AppColors.text,
        onSecondary: AppColors.background,
        onSurface: AppColors.text,
      ),
      iconTheme: const IconThemeData(color: AppColors.primaryLight),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: AppColors.surfaceAlt),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: Color(0x99C4B5FD)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: AppColors.lavender),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: AppColors.lavender, width: 1.5),
        ),
        hintStyle: const TextStyle(color: AppColors.muted),
        labelStyle: const TextStyle(color: AppColors.muted),
        prefixIconColor: AppColors.primaryLight,
        suffixIconColor: AppColors.primaryLight,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: AppColors.text,
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 0,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          foregroundColor: AppColors.text,
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.lavender,
          side: const BorderSide(color: Color(0x99C4B5FD)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.lavender),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.text,
        elevation: 0,
        centerTitle: false,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceSolid,
        selectedItemColor: AppColors.primaryLight,
        unselectedItemColor: AppColors.muted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.primary.withValues(alpha: .38),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceSolid,
        contentTextStyle: const TextStyle(color: AppColors.text),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceSolid,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: AppColors.primary.withValues(alpha: .42)),
        ),
      ),
    );

    return base.copyWith(
      pageTransitionsTheme: animationsEnabled
          ? const PageTransitionsTheme()
          : PageTransitionsTheme(
              builders: {
                for (final platform in TargetPlatform.values)
                  platform: _NoAnimationPageTransitionsBuilder(),
              },
            ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.text,
        displayColor: AppColors.text,
      ),
    );
  }
}

class _NoAnimationPageTransitionsBuilder extends PageTransitionsBuilder {
  const _NoAnimationPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}
