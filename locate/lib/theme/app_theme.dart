import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // light palette
  static const Color lightDarkest = Color(0xFF3F3368);
  static const Color lightDark = Color(0xFF6B5BA0);
  static const Color lightMedium = Color(0xFF927FBD);
  static const Color lightLight = Color(0xFFB8AADB);
  static const Color lightLightest = Color(0xFFE8E4F3);

  // dark palette
  static const Color darkDarkest = Color(0xFF0B0A1A);
  static const Color darkDark = Color(0xFF251A50);
  static const Color darkMedium = Color(0xFF7B6FD9);
  static const Color darkLight = Color(0xFFA79FFF);
  static const Color darkLightest = Color(0xFFD9CEFF);

  // light theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: lightDark,
        onPrimary: Colors.white,
        primaryContainer: lightLightest,
        onPrimaryContainer: lightDarkest,
        secondary: lightMedium,
        onSecondary: Colors.white,
        secondaryContainer: lightLightest.withAlpha(128),
        onSecondaryContainer: lightDarkest,
        surface: const Color(0xFFF5F9FF),
        onSurface: lightDarkest,
        surfaceContainerHighest: Colors.white,
        outline: lightLight.withAlpha(128),
      ),
      scaffoldBackgroundColor: const Color(0xFFF5F9FF),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF052659),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: lightLightest,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: lightDark,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            );
          }
          return TextStyle(color: lightDarkest.withAlpha(153), fontSize: 12);
        }),
      ),
      searchBarTheme: SearchBarThemeData(
        elevation: const WidgetStatePropertyAll(0),
        backgroundColor: const WidgetStatePropertyAll(Colors.white),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: lightLight.withAlpha(77)),
          ),
        ),
        hintStyle: WidgetStatePropertyAll(
          TextStyle(color: lightDarkest.withAlpha(100)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: lightLightest,
        checkmarkColor: lightDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide(color: lightLight.withAlpha(100)),
        labelStyle: const TextStyle(color: lightDarkest),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: lightDark,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  // dark theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: darkMedium,
        onPrimary: darkDarkest,
        primaryContainer: darkDarkest,
        onPrimaryContainer: darkLightest,
        secondary: darkDark,
        onSecondary: Colors.white,
        secondaryContainer: darkDark.withAlpha(77),
        onSecondaryContainer: darkLightest,
        surface: const Color(0xFF010B20),
        onSurface: darkLightest,
        surfaceContainerHighest: const Color(0xFF0A1A3A),
        outline: darkDark.withAlpha(77),
      ),
      scaffoldBackgroundColor: const Color(0xFF010B20),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0A1A3A),
        foregroundColor: Color(0xFFCAF0F8),
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: const Color(0xFF0A1A3A),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: darkDark.withAlpha(77),
        backgroundColor: const Color(0xFF0A1A3A),
        surfaceTintColor: Colors.transparent,
      ),
      searchBarTheme: SearchBarThemeData(
        elevation: const WidgetStatePropertyAll(0),
        backgroundColor: const WidgetStatePropertyAll(Color(0xFF0A1A3A)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: darkDark.withAlpha(77)),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF0A1A3A),
        selectedColor: darkDark.withAlpha(77),
        checkmarkColor: darkMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide(color: darkDark.withAlpha(77)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: darkDark,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
