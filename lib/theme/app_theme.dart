import 'package:flutter/material.dart';

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.brand,
    required this.brandSoft,
    required this.textPrimary,
    required this.textSecondary,
    required this.outline,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.success,
    required this.error,
    required this.onBrand,
  });

  final Color background;
  final Color surface;
  final Color surfaceRaised;
  final Color brand;
  final Color brandSoft;
  final Color textPrimary;
  final Color textSecondary;
  final Color outline;
  final Color protein;
  final Color carbs;
  final Color fat;
  final Color success;
  final Color error;
  final Color onBrand;

  @override
  AppPalette copyWith({
    Color? background,
    Color? surface,
    Color? surfaceRaised,
    Color? brand,
    Color? brandSoft,
    Color? textPrimary,
    Color? textSecondary,
    Color? outline,
    Color? protein,
    Color? carbs,
    Color? fat,
    Color? success,
    Color? error,
    Color? onBrand,
  }) =>
      AppPalette(
        background: background ?? this.background,
        surface: surface ?? this.surface,
        surfaceRaised: surfaceRaised ?? this.surfaceRaised,
        brand: brand ?? this.brand,
        brandSoft: brandSoft ?? this.brandSoft,
        textPrimary: textPrimary ?? this.textPrimary,
        textSecondary: textSecondary ?? this.textSecondary,
        outline: outline ?? this.outline,
        protein: protein ?? this.protein,
        carbs: carbs ?? this.carbs,
        fat: fat ?? this.fat,
        success: success ?? this.success,
        error: error ?? this.error,
        onBrand: onBrand ?? this.onBrand,
      );

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      brand: Color.lerp(brand, other.brand, t)!,
      brandSoft: Color.lerp(brandSoft, other.brandSoft, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      protein: Color.lerp(protein, other.protein, t)!,
      carbs: Color.lerp(carbs, other.carbs, t)!,
      fat: Color.lerp(fat, other.fat, t)!,
      success: Color.lerp(success, other.success, t)!,
      error: Color.lerp(error, other.error, t)!,
      onBrand: Color.lerp(onBrand, other.onBrand, t)!,
    );
  }
}

extension AppThemeContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}

abstract final class AppSpace {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

abstract final class AppRadius {
  static const double sm = 12;
  static const double md = 18;
  static const double lg = 26;
  static const double pill = 999;
}

class AppTheme {
  AppTheme._();

  static const lightPalette = AppPalette(
    background: Color(0xFFF7F7FB),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFF0F3F4),
    brand: Color(0xFF00A987),
    brandSoft: Color(0xFFE2FBF5),
    textPrimary: Color(0xFF101214),
    textSecondary: Color(0xFF687176),
    outline: Color(0xFFDDE2E3),
    protein: Color(0xFF5778B8),
    carbs: Color(0xFFC38A28),
    fat: Color(0xFFC96F65),
    success: Color(0xFF00A987),
    error: Color(0xFFBA4F49),
    onBrand: Color(0xFFFFFFFF),
  );

  static const darkPalette = AppPalette(
    background: Color(0xFF121411),
    surface: Color(0xFF1B1E1A),
    surfaceRaised: Color(0xFF252923),
    brand: Color(0xFFD5EA8A),
    brandSoft: Color(0xFF2B3423),
    textPrimary: Color(0xFFF1F2E9),
    textSecondary: Color(0xFFA1A59B),
    outline: Color(0xFF30352F),
    protein: Color(0xFF82A0D8),
    carbs: Color(0xFFE1AF58),
    fat: Color(0xFFDE897F),
    success: Color(0xFF91C49A),
    error: Color(0xFFE88B80),
    onBrand: Color(0xFF20231B),
  );

  // Kept as aliases while older screen widgets are migrated to context.palette.
  static const background = Color(0xFF121411);
  static const surface = Color(0xFF1B1E1A);
  static const surfaceAlt = Color(0xFF252923);
  static const accent = Color(0xFFD5EA8A);
  static const accentGlow = Color(0xFFE8F5B8);
  static const green = Color(0xFF91C49A);
  static const textPrimary = Color(0xFFF1F2E9);
  static const textSecondary = Color(0xFFA1A59B);
  static const proteinColor = Color(0xFF82A0D8);
  static const carbsColor = Color(0xFFE1AF58);
  static const fatColor = Color(0xFFDE897F);
  static const errorColor = Color(0xFFE88B80);

  static ThemeData get light => _build(Brightness.light, lightPalette);
  static ThemeData get dark => _build(Brightness.dark, darkPalette);

  static ThemeData _build(Brightness brightness, AppPalette p) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: p.brand,
      onPrimary: p.onBrand,
      secondary: p.protein,
      onSecondary: Colors.white,
      error: p.error,
      onError: Colors.white,
      surface: p.surface,
      onSurface: p.textPrimary,
      surfaceContainerHighest: p.surfaceRaised,
      outline: p.outline,
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.background,
      fontFamily: 'Inter',
      extensions: [p],
    );
    final text = base.textTheme;
    return base.copyWith(
      textTheme: text.copyWith(
        headlineLarge: text.headlineLarge
            ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -1.2),
        headlineMedium: text.headlineMedium
            ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.7),
        titleLarge: text.titleLarge
            ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.4),
        titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        bodyMedium: text.bodyMedium?.copyWith(height: 1.4),
        bodySmall: text.bodySmall?.copyWith(height: 1.35),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        foregroundColor: p.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.brand,
          foregroundColor: p.onBrand,
          elevation: 0,
          minimumSize: const Size(0, 54),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surfaceRaised,
        hintStyle: TextStyle(color: p.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: p.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: p.brand, width: 1.5),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.surfaceRaised,
        contentTextStyle: TextStyle(color: p.textPrimary),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md)),
        behavior: SnackBarBehavior.floating,
      ),
      bottomAppBarTheme: BottomAppBarThemeData(color: p.surface, elevation: 0),
      dividerTheme: DividerThemeData(color: p.outline, thickness: 1, space: 1),
    );
  }
}
