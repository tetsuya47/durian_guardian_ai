import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Core Colors (Constant across themes)
  static const Color primary = Color(0xFF2E7D32);
  static const Color secondary = Color(0xFF66BB6A);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFF9A825);
  static const Color error = Color(0xFFD32F2F);

  // Light Theme Colors
  static const Color lightBackground = Color(0xFFF7F9F8);
  static const Color lightCard = Colors.white;
  static const Color lightTextPrimary = Color(0xFF263238);
  static const Color lightTextSecondary = Color(0xFF607D8B);
  static const Color lightBorder = Color(0xFFCFD8DC);

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkCard = Color(0xFF1E1E1E);
  static const Color darkTextPrimary = Color(0xFFECEFF1);
  static const Color darkTextSecondary = Color(0xFFB0BEC5);
  static const Color darkBorder = Color(0xFF37474F);

  // Helper colors
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color transparent = Colors.transparent;
}
