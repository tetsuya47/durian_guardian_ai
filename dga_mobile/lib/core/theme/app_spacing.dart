import 'package:flutter/material.dart';

class AppSpacing {
  AppSpacing._();

  // Spacing values
  static const double xs = 4.0;
  static const double s = 8.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
  static const double huge = 40.0;
  static const double giant = 48.0;

  // Pre-defined vertical spacing widgets
  static const Widget v4 = SizedBox(height: xs);
  static const Widget v8 = SizedBox(height: s);
  static const Widget v12 = SizedBox(height: md);
  static const Widget v16 = SizedBox(height: lg);
  static const Widget v20 = SizedBox(height: xl);
  static const Widget v24 = SizedBox(height: xxl);
  static const Widget v32 = SizedBox(height: xxxl);
  static const Widget v40 = SizedBox(height: huge);
  static const Widget v48 = SizedBox(height: giant);

  // Pre-defined horizontal spacing widgets
  static const Widget h4 = SizedBox(width: xs);
  static const Widget h8 = SizedBox(width: s);
  static const Widget h12 = SizedBox(width: md);
  static const Widget h16 = SizedBox(width: lg);
  static const Widget h20 = SizedBox(width: xl);
  static const Widget h24 = SizedBox(width: xxl);
  static const Widget h32 = SizedBox(width: xxxl);
  static const Widget h40 = SizedBox(width: huge);
  static const Widget h48 = SizedBox(width: giant);
}
