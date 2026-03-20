import 'package:flutter/material.dart';

/// App theme configuration for the Music Player app.
/// Redesigned to match the "MusicStore" aesthetic with primary yellow and dark themes.
class AppTheme {
  AppTheme._();

  // ============================================================
  // Color Palette - Yellow & Dark Theme
  // ============================================================

  static const Color primaryColor = Color(0xFFFFFF00); // Bright Yellow
  static const Color accentColor = Color(0xFFFFFF00);
  
  // Backgrounds
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color cardDark = Color(0xFF282828);
  
  // Text
  static const Color textPrimaryDark = Colors.white;
  static const Color textSecondaryDark = Color(0xFFB3B3B3);

  // Additional Colors (Restored as aliases for compatibility)
  static const Color errorColor = Color(0xFFEF4444);
  static const Color successColor = Color(0xFF22C55E);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFFFF00), Color(0xFFFFD700)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkBackgroundGradient = LinearGradient(
    colors: [Color(0xFF121212), Color(0xFF000000)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Compatibility Gradient Aliases (Mapping old gradients to new dark/yellow aesthetic)
  static const LinearGradient auroraGradient = LinearGradient(
    colors: [Color(0xFFFFFF00), Color(0xFF888800)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient deepSpaceGradient = LinearGradient(
    colors: [Color(0xFF121212), Color(0xFF000000)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient sunsetGlowGradient = LinearGradient(
    colors: [Color(0xFFFFFF00), Color(0xFFB3B3B3), Color(0xFF121212)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ============================================================
  // Dark Theme (Main Theme)
  // ============================================================

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: accentColor,
        surface: surfaceDark,
        background: backgroundDark,
        onPrimary: Colors.black,
        onSurface: Colors.white,
        error: errorColor,
      ),
      scaffoldBackgroundColor: backgroundDark,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimaryDark,
        titleTextStyle: TextStyle(
          color: textPrimaryDark,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: cardDark,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryColor,
        inactiveTrackColor: Colors.white.withOpacity(0.2),
        thumbColor: primaryColor,
        overlayColor: primaryColor.withOpacity(0.2),
        trackHeight: 4,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: backgroundDark,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondaryDark,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: textPrimaryDark),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: textPrimaryDark),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: textPrimaryDark),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimaryDark),
        bodyLarge: TextStyle(fontSize: 16, color: textPrimaryDark),
        bodyMedium: TextStyle(fontSize: 14, color: textSecondaryDark),
      ),
    );
  }

  // Light theme for compatibility (though app is primarily dark)
  static ThemeData get lightTheme => darkTheme.copyWith(
    brightness: Brightness.light,
  );
}
