import 'package:flutter/material.dart';

/// High-contrast colors reserved for the interactive puzzle canvas.
///
/// The surrounding app deliberately stays calm. Boards may be more vivid so
/// that every game keeps its own character and state changes remain obvious.
class GameBoardPalette {
  const GameBoardPalette({
    required this.accent,
    required this.accentAlt,
    required this.glow,
    required this.board,
    required this.cell,
    required this.cellStrong,
    required this.foreground,
    required this.muted,
  });

  final Color accent;
  final Color accentAlt;
  final Color glow;
  final Color board;
  final Color cell;
  final Color cellStrong;
  final Color foreground;
  final Color muted;
}

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

  static GameBoardPalette boardPalette(
    String game,
    Brightness brightness,
  ) {
    final dark = brightness == Brightness.dark;
    return switch (game) {
      'hashi' => GameBoardPalette(
          accent: dark ? const Color(0xFF55F0D4) : const Color(0xFF007F82),
          accentAlt: dark ? const Color(0xFF57C8FF) : const Color(0xFF176BA0),
          glow: dark ? const Color(0x8055F0D4) : const Color(0x33007F82),
          board: dark ? const Color(0xFF071310) : const Color(0xFFF2FAF8),
          cell: dark ? const Color(0xFF0A2925) : const Color(0xFFD9EFEB),
          cellStrong: dark ? const Color(0xFF0A4640) : const Color(0xFFB9E3DD),
          foreground: dark ? const Color(0xFFE6FFFA) : const Color(0xFF063B3B),
          muted: dark ? const Color(0xFF64857F) : const Color(0xFF6E8883),
        ),
      'slitherlink' => GameBoardPalette(
          accent: dark ? const Color(0xFF67D8FF) : const Color(0xFF087DB0),
          accentAlt: dark ? const Color(0xFFB29AFF) : const Color(0xFF6752B8),
          glow: dark ? const Color(0x7067D8FF) : const Color(0x30087DB0),
          board: dark ? const Color(0xFF091119) : const Color(0xFFF3F7FC),
          cell: dark ? const Color(0xFF111B28) : const Color(0xFFE7EEF8),
          cellStrong: dark ? const Color(0xFF172B41) : const Color(0xFFD4E5F5),
          foreground: dark ? const Color(0xFFF3F7FF) : const Color(0xFF17243A),
          muted: dark ? const Color(0xFF718093) : const Color(0xFF758195),
        ),
      'binairo' => GameBoardPalette(
          accent: dark ? const Color(0xFF35D6EA) : const Color(0xFF087FA2),
          accentAlt: dark ? const Color(0xFFA18AFF) : const Color(0xFF6550C2),
          glow: dark ? const Color(0x6035D6EA) : const Color(0x30087FA2),
          board: dark ? const Color(0xFF0B1020) : const Color(0xFFF3F5FC),
          cell: dark ? const Color(0xFF151C2B) : const Color(0xFFE9ECF5),
          cellStrong: dark ? const Color(0xFF25334B) : const Color(0xFFD7DEEF),
          foreground: dark ? const Color(0xFFF3F7FF) : const Color(0xFF172139),
          muted: dark ? const Color(0xFF758198) : const Color(0xFF727C92),
        ),
      'futoshiki' => GameBoardPalette(
          accent: dark ? const Color(0xFFFFB45E) : const Color(0xFFB85B00),
          accentAlt: dark ? const Color(0xFFFFD07C) : const Color(0xFFD17B18),
          glow: dark ? const Color(0x60FFB45E) : const Color(0x30B85B00),
          board: dark ? const Color(0xFF171109) : const Color(0xFFFFF8EE),
          cell: dark ? const Color(0xFF241C13) : const Color(0xFFFFF1DE),
          cellStrong: dark ? const Color(0xFF3B2C1B) : const Color(0xFFF5D9B6),
          foreground: dark ? const Color(0xFFFFF8EC) : const Color(0xFF3E250D),
          muted: dark ? const Color(0xFF9E8970) : const Color(0xFF8D7761),
        ),
      'hitori' => GameBoardPalette(
          accent: dark ? const Color(0xFFFF79C6) : const Color(0xFFA83278),
          accentAlt: dark ? const Color(0xFFBF9CFF) : const Color(0xFF7250B5),
          glow: dark ? const Color(0x60FF79C6) : const Color(0x30A83278),
          board: dark ? const Color(0xFF130D13) : const Color(0xFFFFF7FC),
          cell: dark ? const Color(0xFF29242B) : const Color(0xFFF3EAF1),
          cellStrong: dark ? const Color(0xFF3A2B38) : const Color(0xFFE7D2E1),
          foreground: dark ? const Color(0xFFFFF7FC) : const Color(0xFF32172A),
          muted: dark ? const Color(0xFF8E7B8A) : const Color(0xFF88717F),
        ),
      'tents' => GameBoardPalette(
          accent: dark ? const Color(0xFF63D7FF) : const Color(0xFF087BA5),
          accentAlt: dark ? const Color(0xFF54E18B) : const Color(0xFF21844B),
          glow: dark ? const Color(0x5063D7FF) : const Color(0x30087BA5),
          board: dark ? const Color(0xFF091510) : const Color(0xFFF4FAF5),
          cell: dark ? const Color(0xFF17221D) : const Color(0xFFEAF2EB),
          cellStrong: dark ? const Color(0xFF164A2E) : const Color(0xFFCDEBD6),
          foreground: dark ? const Color(0xFFF2FFF7) : const Color(0xFF153524),
          muted: dark ? const Color(0xFF71897B) : const Color(0xFF718076),
        ),
      _ => throw ArgumentError.value(game, 'game'),
    };
  }

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
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
        iconColor: scheme.onSurfaceVariant,
        titleTextStyle: textTheme.titleMedium?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
        subtitleTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
          height: 1.3,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      expansionTileTheme: ExpansionTileThemeData(
        iconColor: scheme.primary,
        collapsedIconColor: scheme.onSurfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        collapsedShape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
        childrenPadding: const EdgeInsets.only(bottom: 8),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHigh,
        linearMinHeight: 7,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: TextStyle(color: scheme.onInverseSurface),
        waitDuration: const Duration(milliseconds: 650),
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
