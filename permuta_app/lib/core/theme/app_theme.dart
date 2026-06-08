import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta cathira — vermelho-coral quente como primary, âmbar como accent,
/// slate escuro pra ink, fundo creme suave pra dar calor.
class AppColors {
  static const primary       = Color(0xFFF43F5E); // rose-500 mais vibrante
  static const primaryDeep   = Color(0xFFBE123C); // rose-700
  static const primarySoft   = Color(0xFFFDE7EB); // tint pra surfaces
  static const accent        = Color(0xFFF59E0B); // âmbar
  static const accentDeep    = Color(0xFFD97706);
  static const ink           = Color(0xFF0B1220); // slate-950 levemente azulado
  static const inkSoft       = Color(0xFF1F2937);
  static const surface       = Color(0xFFFCFAF7); // creme
  static const surfaceAlt    = Color(0xFFFDF3E7); // bege quente
  static const surfaceCard   = Colors.white;
  static const muted         = Color(0xFF64748B);
  static const mutedSoft     = Color(0xFFE2E8F0);
  static const success       = Color(0xFF10B981);
  static const warning       = Color(0xFFF59E0B);
  static const danger        = Color(0xFFEF4444);

  /// Hero gradiente principal — rosa-coral pra âmbar, com angle dinâmico.
  static const gradHero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF43F5E), Color(0xFFFB923C), Color(0xFFF59E0B)],
    stops: [0.0, 0.55, 1.0],
  );

  /// Gradiente sutil pra cards de fundo (areia clarinha).
  static const gradCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFF7ED), Color(0xFFFEE8D2)],
  );

  /// Para o CTA escuro do final da Home — ink com gleam sutil.
  static const gradInk = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0B1220), Color(0xFF1F2937)],
  );

  /// Resolve gradiente a partir da cor hex vinda da API. Adiciona um stop
  /// mais escuro pra dar profundidade.
  static LinearGradient gradientFromHex(String hex) {
    final base = _hexToColor(hex);
    final lighter = Color.lerp(base, Colors.white, 0.22)!;
    final darker = Color.lerp(base, Colors.black, 0.25)!;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [lighter, base, darker],
      stops: const [0.0, 0.5, 1.0],
    );
  }

  static Color colorFromHex(String hex) => _hexToColor(hex);

  static Color _hexToColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.surface,
    );
    final textTheme = _textTheme(base.textTheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.surface,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          textStyle: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700, fontSize: 15.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          foregroundColor: AppColors.ink,
          side: BorderSide(
              color: AppColors.ink.withValues(alpha: 0.18), width: 1.3),
          textStyle: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700, fontSize: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.ink,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              BorderSide(color: AppColors.primary.withValues(alpha: 0.6), width: 1.4),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        labelStyle: textTheme.bodyMedium?.copyWith(color: AppColors.muted),
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.muted),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: AppColors.ink.withValues(alpha: 0.06)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceAlt,
        labelStyle: textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.ink),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: const StadiumBorder(),
        side: BorderSide.none,
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.ink.withValues(alpha: 0.08),
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle:
            textTheme.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: 6,
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base) {
    // Display: Bebas Neue (condensada poster, alta legibilidade em tamanho gigante).
    // Body / labels: Plus Jakarta Sans (humana, legível).
    // Mono labels: JetBrains Mono (tabular figures).
    return GoogleFonts.plusJakartaSansTextTheme(base).copyWith(
      displayLarge: GoogleFonts.bebasNeue(
          fontSize: 56, color: AppColors.ink, letterSpacing: 0.5, height: 0.92),
      displayMedium: GoogleFonts.bebasNeue(
          fontSize: 46, color: AppColors.ink, letterSpacing: 0.4, height: 0.94),
      displaySmall: GoogleFonts.bebasNeue(
          fontSize: 36, color: AppColors.ink, letterSpacing: 0.3, height: 0.96),
      headlineMedium: GoogleFonts.bebasNeue(
          fontSize: 28, color: AppColors.ink, letterSpacing: 0.3),
      titleLarge: GoogleFonts.bebasNeue(
          fontSize: 22, color: AppColors.ink, letterSpacing: 0.4),
      titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink),
      bodyLarge: GoogleFonts.plusJakartaSans(
          fontSize: 16, color: AppColors.ink, height: 1.5),
      bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 14, color: AppColors.ink, height: 1.45),
      bodySmall: GoogleFonts.plusJakartaSans(
          fontSize: 12, color: AppColors.muted, height: 1.4),
      labelLarge: GoogleFonts.plusJakartaSans(
          fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink),
      labelMedium: GoogleFonts.plusJakartaSans(
          fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted),
      labelSmall: GoogleFonts.jetBrainsMono(
          fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.muted, letterSpacing: 1.6),
    );
  }

  /// Helper pra usar Bebas Neue inline (display).
  /// O parâmetro [weight] é aceito mas ignorado — Bebas Neue só tem 400.
  static TextStyle display(double size,
      {Color? color, double? letter, double? height, FontWeight? weight}) {
    return GoogleFonts.bebasNeue(
      fontSize: size,
      color: color ?? AppColors.ink,
      letterSpacing: letter ?? (size * 0.012),
      height: height ?? 0.92,
    );
  }

  /// JetBrains Mono pra números financeiros e labels técnicos (tabular figures).
  static TextStyle mono(double size, {Color? color, FontWeight? weight}) {
    return GoogleFonts.jetBrainsMono(
      fontSize: size,
      fontWeight: weight ?? FontWeight.w700,
      color: color ?? AppColors.ink,
      letterSpacing: -0.2,
    );
  }
}

/// Sombras reusáveis — sutis e quentes.
class AppShadows {
  static const soft = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 24,
      offset: Offset(0, 12),
    ),
  ];
  static const lift = [
    BoxShadow(
      color: Color(0x1F000000),
      blurRadius: 30,
      offset: Offset(0, 16),
    ),
  ];
}
