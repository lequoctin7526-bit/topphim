import 'package:flutter/material.dart';

class AppColors {
  // Brand Dark Cinema Theme
  static const Color background = Color(0xFF090909);
  static const Color surface = Color(0xFF151515);
  static const Color surfaceElevated = Color(0xFF212121);
  static const Color border = Color(0xFF292929);

  // Primary Brand Colors
  static const Color primary = Color(0xFFE50914);
  static const Color primaryDark = Color(0xFFB20710);
  static const Color accent = Color(0xFFFF242E);

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA3A3A3);
  static const Color textTertiary = Color(0xFF737373);

  // Status & Utility Colors
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF1E27), Color(0xFFB20710)],
  );

  static const LinearGradient posterVignette = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, Color(0xCC090909), Color(0xFF090909)],
    stops: [0.3, 0.8, 1.0],
  );
}
