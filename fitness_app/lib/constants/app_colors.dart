import 'package:flutter/material.dart';

class AppColors {
  // Primary Brand Colors (based on Blue/Purple gradients in design)
  static const Color primaryBlue = Color(0xFF92A3FD);
  static const Color primaryPurple = Color(0xFF9DCEFF);
  
  static const Color secondaryBlue = Color(0xFFC58BF2);
  static const Color secondaryPurple = Color(0xFFEEA4CE);

  // Text Colors
  static const Color blackText = Color(0xFF1D1617);
  static const Color grayText = Color(0xFF7B6F72);
  static const Color whiteText = Colors.white;

  // Backgrounds
  static const Color scaffoldBackground = Colors.white;
  static const Color borderColor = Color(0xFFF7F8F8);
  
  // Functional
  static const Color success = Color(0xFF42D742);
  static const Color warning = Color(0xFFFFD600);
  static const Color error = Color(0xFFFF0000);

  // Gradients
  static const LinearGradient blueGradient = LinearGradient(
    colors: [primaryBlue, primaryPurple],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  
  static const LinearGradient purpleGradient = LinearGradient(
    colors: [secondaryBlue, secondaryPurple],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}