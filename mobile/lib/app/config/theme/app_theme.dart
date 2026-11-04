// AI-generated (Claude), reviewed by the author.

import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:skillbit_rebirth/app/config/theme/app_colors.dart';
import 'package:skillbit_rebirth/app/config/theme/app_colors_extension.dart';

class AppTheme {
  new _();

  static final ThemeData light = _build(
    scheme: const ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.info,
      onSecondary: Colors.white,
      tertiary: AppColors.tertiary,
      onTertiary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      surface: AppColors.cardLight,
      onSurface: AppColors.textMainLight,
      onSurfaceVariant: AppColors.textSecondaryLight,
      outline: AppColors.border,
      outlineVariant: AppColors.cornerLight,
      shadow: AppColors.shadowLight,
    ),
    scaffold: AppColors.backgroundLight,
    extension: AppColorsExtension.light,
  );

  static final ThemeData dark = _build(
    scheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.info,
      onSecondary: Colors.white,
      tertiary: AppColors.tertiary,
      onTertiary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      surface: AppColors.cardDark,
      onSurface: AppColors.textMainDark,
      onSurfaceVariant: AppColors.textSecondaryDark,
      outline: AppColors.border,
      outlineVariant: AppColors.cornerDark,
      shadow: AppColors.shadowDark,
    ),
    scaffold: AppColors.backgroundDark,
    extension: AppColorsExtension.dark,
  );

  // One builder so light and dark can never drift apart
  static ThemeData _build({
    required ColorScheme scheme,
    required Color scaffold,
    required AppColorsExtension extension,
  }) {
    // Plain Material text styles first, then swap in the Google font
    // and color all text with the theme's main text color
    final base = ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
    );
    final myTextTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme)
        .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);

    return ThemeData(
      useMaterial3: true,
      textTheme: myTextTheme,
      brightness: scheme.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      extensions: [extension],
      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: extension.corner),
        ),
      ),
      dividerTheme: DividerThemeData(color: scheme.outline, thickness: 1),
      iconTheme: IconThemeData(color: scheme.onSurface),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.error),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: scheme.surface,
        selectedItemColor: scheme.primary,
        unselectedItemColor: extension.inactiveIcon,
        type: BottomNavigationBarType.fixed,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: extension.corner,
      ),
    );
  }
}
