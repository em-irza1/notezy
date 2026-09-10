import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Notesy's soft, "pinteresty" color + type system.
/// Warm cream background, dusty-rose accents, teddy-brown highlights —
/// matches the home screen you already built.
class AppColors {
  AppColors._();

  static const Color background = Color(0xFFFBF6EF); // warm cream
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSoft = Color(0xFFFFF9F2);
  static const Color card = Color(0xFFFFF3E9);

  static const Color rose = Color(0xFFF0C9CE); // soft dusty rose (border/icons)
  static const Color roseDeep = Color(0xFFE3A9B4);
  static const Color brown = Color(0xFF8B5E3C); // teddy brown
  static const Color brownDeep = Color(0xFF6B4426);

  static const Color ink = Color(0xFF3E332C); // primary text, warm near-black
  static const Color inkSoft = Color(0xFF8A7C71); // secondary text

  static const Color highlightYellow = Color(0xFFFFE79A);
  static const Color highlightPink = Color(0xFFFAD1DC);
  static const Color highlightMint = Color(0xFFCFEBD8);
  static const Color highlightLavender = Color(0xFFE3D8F5);
  static const Color highlightPeach = Color(0xFFFFE1C4);

  static const List<Color> noteAccents = [
    rose,
    highlightMint,
    highlightLavender,
    highlightPeach,
    highlightYellow,
  ];

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFDF9), Color(0xFFFBF1E6)],
  );
}

class AppRadii {
  AppRadii._();
  static const double sm = 12;
  static const double md = 18;
  static const double lg = 26;
  static const double xl = 32;
}

class AppShadows {
  AppShadows._();

  static List<BoxShadow> soft = [
    BoxShadow(
      color: AppColors.brown.withOpacity(0.08),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> floating = [
    BoxShadow(
      color: AppColors.brown.withOpacity(0.14),
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
  ];
}

class AppTheme {
  AppTheme._();

  // Headings use a friendly rounded/handwritten feel (Pinterest vibe),
  // body text stays highly legible.
  static TextTheme _textTheme(TextTheme base) {
    return base
        .copyWith(
          displaySmall: GoogleFonts.caveat(
            fontSize: 34,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
          headlineMedium: GoogleFonts.quicksand(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
          titleLarge: GoogleFonts.quicksand(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
          titleMedium: GoogleFonts.quicksand(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
          bodyLarge: GoogleFonts.nunito(
            fontSize: 17,
            height: 1.5,
            color: AppColors.ink,
          ),
          bodyMedium: GoogleFonts.nunito(
            fontSize: 15,
            height: 1.5,
            color: AppColors.ink,
          ),
          labelLarge: GoogleFonts.quicksand(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.brownDeep,
          ),
        )
        .apply(bodyColor: AppColors.ink, displayColor: AppColors.ink);
  }

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.brown,
        secondary: AppColors.rose,
        surface: AppColors.surface,
      ),
      textTheme: _textTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.brownDeep),
        titleTextStyle: GoogleFonts.quicksand(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.brownDeep),
      splashColor: AppColors.rose.withOpacity(0.2),
      highlightColor: AppColors.rose.withOpacity(0.1),
    );
  }
}
