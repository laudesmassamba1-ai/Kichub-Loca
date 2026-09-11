import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

class AppColors {
  static const deepNavy = Color(0xFF0B1020);
  static const midnight = Color(0xFF101828);
  static const softSlate = Color(0xFFEDF2F7);
  static const glacier = Color(0xFFE9F5FF);
  static const mint = Color(0xFF34D399);
  static const sky = Color(0xFF60A5FA);
  static const amber = Color(0xFFFBBF24);
  static const rose = Color(0xFFF87171);
  static const violet = Color(0xFFA78BFA);
  static const white = Color(0xFFFFFFFF);

  static Color statusColor(String statut) {
    switch (statut) {
      case 'accepte':
        return const Color(0xFF10B981);
      case 'refuse':
        return const Color(0xFFEF4444);
      case 'a_recontacter':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  static String statusLabel(String statut) {
    switch (statut) {
      case 'accepte':
        return 'Accepté';
      case 'refuse':
        return 'Refusé';
      case 'a_recontacter':
        return 'À recontacter';
      default:
        return 'Nouveau';
    }
  }
}

class AppTheme {
  static ThemeData light() {
    final compact = kIsWeb;

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF5F7FB),
      cardColor: Colors.white.withValues(alpha: 0.72),
      visualDensity: compact ? VisualDensity.compact : VisualDensity.adaptivePlatformDensity,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2F6DFF),
        brightness: Brightness.light,
      ),
      textTheme: (const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w800,
          color: AppColors.deepNavy,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: AppColors.deepNavy,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.deepNavy,
        ),
        titleMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.deepNavy,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF425466),
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFF425466),
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color(0xFF64748B),
        ),
      )).apply(fontSizeFactor: compact ? 0.9 : 1, fontSizeDelta: compact ? -1 : 0),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.deepNavy,
        toolbarHeight: compact ? 56 : null,
        titleTextStyle: TextStyle(
          fontSize: compact ? 18 : 22,
          fontWeight: FontWeight.w700,
          color: AppColors.deepNavy,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white.withValues(alpha: 0.92),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: Size.fromHeight(compact ? 44 : 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: TextStyle(
            fontSize: compact ? 14 : null,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        side: BorderSide.none,
      ),
    );

    return base.copyWith(
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.72),
        hintStyle: const TextStyle(color: Color(0xFF64748B)),
        contentPadding: EdgeInsets.symmetric(
          horizontal: compact ? 14 : 16,
          vertical: compact ? 12 : 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.sky, width: 1.5),
        ),
      ),
    );
  }
}
