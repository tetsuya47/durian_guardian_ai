import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyle {
  AppTextStyle._();

  // Base TextStyle function using Inter
  static TextStyle _baseStyle({
    required double fontSize,
    required FontWeight fontWeight,
    required double height,
    required Color color,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      color: color,
    );
  }

  // Generate text styles for specific themes
  static TextTheme textTheme(Color primaryColor, Color secondaryColor) {
    return TextTheme(
      // Display Styles
      displayLarge: _baseStyle(fontSize: 48, fontWeight: FontWeight.bold, height: 1.1, color: primaryColor),
      displayMedium: _baseStyle(fontSize: 40, fontWeight: FontWeight.bold, height: 1.15, color: primaryColor),
      displaySmall: _baseStyle(fontSize: 32, fontWeight: FontWeight.bold, height: 1.2, color: primaryColor),

      // Headline Styles
      headlineLarge: _baseStyle(fontSize: 28, fontWeight: FontWeight.w700, height: 1.25, color: primaryColor),
      headlineMedium: _baseStyle(fontSize: 24, fontWeight: FontWeight.w700, height: 1.3, color: primaryColor),
      headlineSmall: _baseStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.35, color: primaryColor),

      // Title Styles
      titleLarge: _baseStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.4, color: primaryColor),
      titleMedium: _baseStyle(fontSize: 16, fontWeight: FontWeight.w500, height: 1.4, color: primaryColor),
      titleSmall: _baseStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.43, color: primaryColor),

      // Body Styles
      bodyLarge: _baseStyle(fontSize: 16, fontWeight: FontWeight.normal, height: 1.5, color: primaryColor),
      bodyMedium: _baseStyle(fontSize: 14, fontWeight: FontWeight.normal, height: 1.43, color: secondaryColor),
      bodySmall: _baseStyle(fontSize: 12, fontWeight: FontWeight.normal, height: 1.33, color: secondaryColor),

      // Label Styles
      labelLarge: _baseStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.43, color: primaryColor),
      labelMedium: _baseStyle(fontSize: 12, fontWeight: FontWeight.w500, height: 1.33, color: secondaryColor),
      labelSmall: _baseStyle(fontSize: 10, fontWeight: FontWeight.w500, height: 1.4, color: secondaryColor),
    );
  }
}
