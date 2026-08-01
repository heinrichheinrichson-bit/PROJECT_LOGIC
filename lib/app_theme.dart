import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const _lightSeed = Color(0xFF245E57);
  static const _darkSeed = Color(0xFF78C9B9);

  static const gameColors = <String, Color>{
    'binairo': Color(0xFF5367C7),
    'hashi': Color(0xFF168A91),
    'slitherlink': Color(0xFF7165B4),
    'futoshiki': Color(0xFFC47732),
    'hitori': Color(0xFF9A587E),
    'tents': Color(0xFF3D8A5D),
  };

  static ThemeData get light => _build(
        brightness: Brightness.light,
        seed: _lightSeed,
        background: const Color(0xFFF5F4EF),
        surface: const Color(0xFFFFFDF8),
      );

  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        seed: _darkSeed,
        background: const Color(0xFF101513),
        surface: const Color(0xFF171D1B),
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color seed,
    required Color background,
    required Color surface,
  }) {
    final base = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
    final scheme = base.copyWith(
      surface: surface,
      surfaceContainerLowest: brightness == Brightness.light
          ? const Color(0xFFFFFFFF)
          : const Color(0xFF0D1210),
      surfaceContainerLow: brightness == Brightness.light
          ? const Color(0xFFFAF8F2)
          : const Color(0xFF151B19),
      surfaceContainer: brightness == Brightness.light
          ? const Color(0xFFF0EEE7)
          : const Color(0xFF1C2320),
      surfaceContainerHigh: brightness == Brightness.light
          ? const Color(0xFFE9E7DF)
          : const Color(0xFF252D29),
      outlineVariant: brightness == Brightness.light
          ? const Color(0xFFD5D4CD)
          : const Color(0xFF3B4541),
    );
    final textTheme = ThemeData(brightness: brightness).textTheme.apply(
          bodyColor: scheme.onSurface,
          displayColor: scheme.onSurface,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      textTheme: textTheme.copyWith(
        headlineLarge: textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -1.1,
        ),
        headlineMedium: textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.7,
        ),
        headlineSmall:
            textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        titleLarge: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        titleMedium:
            textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .72)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 50),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 50),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          side: BorderSide(color: scheme.outline),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w500,
            )),
      ),
      switchTheme: SwitchThemeData(
        trackOutlineColor: WidgetStatePropertyAll(scheme.outlineVariant),
      ),
    );
  }
}
