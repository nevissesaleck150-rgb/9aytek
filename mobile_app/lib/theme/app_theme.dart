import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const primaryBlue = Color(0xFF1D4ED8);
  static const royalBlue = Color(0xFF1E3A8A);
  static const darkBlue = Color(0xFF1E40AF);
  static const lightBlue = Color(0xFFE8F0FF);
  static const pendingBlueBg = Color(0xFFEBF3FF);
  static const pendingBlueText = Color(0xFF1D4ED8);
  static const readyGreenBg = Color(0xFFEBF3FF);
  static const readyGreenText = Color(0xFF1D4ED8);
  static const dangerRedBg = Color(0xFFEBF3FF);
  static const dangerRedText = Color(0xFF1D4ED8);
  static const background = Color(0xFFF8FAFF);
  static const cardWhite = Colors.white;
  static const textPrimary = Colors.black;
  static const textMuted = Colors.black;
  static const success = primaryBlue;
  static const warning = primaryBlue;
}

class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryBlue,
        primary: AppColors.primaryBlue,
        onPrimary: Colors.white,
        surface: AppColors.background,
        onSurface: AppColors.textPrimary,
        secondary: AppColors.darkBlue,
        onSecondary: Colors.white,
        error: AppColors.primaryBlue,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerColor: AppColors.lightBlue,
    );

    return base.copyWith(
      textTheme: GoogleFonts.cairoTextTheme(base.textTheme).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      iconTheme: const IconThemeData(color: AppColors.primaryBlue),
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: const TextStyle(color: AppColors.textPrimary),
        hintStyle: const TextStyle(color: AppColors.textPrimary),
        prefixIconColor: AppColors.primaryBlue,
        suffixIconColor: AppColors.primaryBlue,
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.lightBlue),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.primaryBlue,
            width: 1.5,
          ),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.lightBlue,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        ),
        iconTheme: WidgetStatePropertyAll(
          IconThemeData(color: AppColors.primaryBlue),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.primaryBlue,
        contentTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
