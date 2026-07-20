import 'package:flutter/material.dart';

class AppRadius {
  AppRadius._();

  // Raw double values
  static const double small = 8.0;
  static const double medium = 12.0;
  static const double large = 20.0;

  // BorderRadius widgets
  static final BorderRadius borderSmall = BorderRadius.circular(small);
  static final BorderRadius borderMedium = BorderRadius.circular(medium);
  static final BorderRadius borderLarge = BorderRadius.circular(large);

  // Radius widgets
  static const Radius radiusSmall = Radius.circular(small);
  static const Radius radiusMedium = Radius.circular(medium);
  static const Radius radiusLarge = Radius.circular(large);
}
