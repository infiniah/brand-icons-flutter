import 'package:flutter/material.dart';

/// The same palette the iOS and Android samples use, so Marks is one product on four platforms.
abstract final class Palette {
  static const canvasLight = Color(0xFFF4F4F2);
  static const canvasDark = Color(0xFF0E0F11);
  static const cardLight = Color(0xFFFFFFFF);
  static const cardDark = Color(0xFF191B1E);
  static const hairlineLight = Color(0xFFE6E5E1);
  static const hairlineDark = Color(0xFF2A2D31);
  static const titleLight = Color(0xFF14161A);
  static const titleDark = Color(0xFFF4F4F2);
  static const secondaryLight = Color(0xFF6C7076);
  static const secondaryDark = Color(0xFF9AA0A6);

  /// The accent that seeds the scheme, so the app stays itself rather than becoming stock.
  static const accent = Color(0xFF1C66DE);

  static ThemeData theme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      brightness: brightness,
      useMaterial3: true,
      scaffoldBackgroundColor: isDark ? canvasDark : canvasLight,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        brightness: brightness,
      ).copyWith(
        surface: isDark ? cardDark : cardLight,
        onSurface: isDark ? titleDark : titleLight,
        onSurfaceVariant: isDark ? secondaryDark : secondaryLight,
        outlineVariant: isDark ? hairlineDark : hairlineLight,
      ),
    );
  }
}
