import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: AppColors.primaryBlue,
      scaffoldBackgroundColor: AppColors.scaffoldBackground,
      fontFamily: GoogleFonts.poppins().fontFamily,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: AppColors.blackText,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: AppColors.blackText,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: TextStyle(
          color: AppColors.grayText,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: AppColors.grayText,
          fontSize: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent, // Use Container gradient
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
        ),
      ),
    );
  }
}