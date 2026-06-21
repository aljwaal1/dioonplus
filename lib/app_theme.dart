import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Centralized brand palette and styling tokens for a premium,
/// finance-grade look: deep navy/teal base with a warm gold accent.
class AppColors {
  AppColors._();

  static const navyDark = Color(0xFF0A2229);
  static const navy = Color(0xFF0E3840);
  static const teal = Color(0xFF146069);
  static const tealLight = Color(0xFF1C7A82);

  static const gold = Color(0xFFD8A648);
  static const goldLight = Color(0xFFF0C975);
  static const goldDark = Color(0xFFB5852E);

  static const success = Color(0xFF1F8A6F);
  static const successSoft = Color(0xFFE4F4EE);
  static const danger = Color(0xFFC1453B);
  static const dangerSoft = Color(0xFFFBEAE8);

  static const background = Color(0xFFF3F6F7);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF7FAFA);

  static const textPrimary = Color(0xFF112227);
  static const textSecondary = Color(0xFF5C7077);
  static const textFaint = Color(0xFF93A4A9);

  static const divider = Color(0xFFE6EDEE);
}

class AppGradients {
  AppGradients._();

  static const header = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [AppColors.navyDark, AppColors.navy, AppColors.teal],
    stops: [0.0, 0.55, 1.0],
  );

  static const gold = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.goldLight, AppColors.gold],
  );

  static const goldPressed = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.gold, AppColors.goldDark],
  );

  static const successTile = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF22987B), Color(0xFF1A7561)],
  );

  static const dangerTile = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD15B51), Color(0xFFA8362D)],
  );
}

class AppShadows {
  AppShadows._();

  static List<BoxShadow> card = [
    BoxShadow(
      color: AppColors.navyDark.withValues(alpha: 0.06),
      blurRadius: 18,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: AppColors.navyDark.withValues(alpha: 0.03),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> floating = [
    BoxShadow(
      color: AppColors.navyDark.withValues(alpha: 0.18),
      blurRadius: 22,
      offset: const Offset(0, 10),
    ),
  ];

  static List<BoxShadow> gold = [
    BoxShadow(
      color: AppColors.gold.withValues(alpha: 0.35),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> header = [
    BoxShadow(
      color: AppColors.navyDark.withValues(alpha: 0.22),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
  ];
}

ThemeData buildAppTheme() {
  const seed = AppColors.teal;
  final base = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: 'Roboto',
    colorScheme: ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
      primary: AppColors.teal,
      secondary: AppColors.gold,
      surface: AppColors.surface,
    ),
    splashFactory: InkRipple.splashFactory,
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      systemOverlayStyle: SystemUiOverlayStyle.light,
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.divider),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceMuted,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.teal, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.2),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.teal,
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.navy,
        side: const BorderSide(color: AppColors.navy, width: 1.4),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.navyDark,
      contentTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 6,
    ),
    dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1),
    textTheme: const TextTheme().apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    ),
  );
  return base;
}
