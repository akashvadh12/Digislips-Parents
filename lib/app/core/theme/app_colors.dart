import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF5B67CA);
  static const Color primaryDark = Color(0xFF4A56B8);
  static const Color secondary = Color(0xFF00D4AA);
  static const Color background = Color(0xFFF8FAFC);
  static const Color cardBackground = Colors.white;
  static const Color error = Color(0xFFFF6B6B);
  static const Color success = Color(0xFF51CF66);
  static const Color warning = Color(0xFFFFD93D);
  static const Color whiteColor = Colors.white;
  static const Color blackColor = Color(0xFF1A1A1A);
  static const Color greyColor = Color(0xFF6B7280);
  static const Color lightGrey = Color(0xFFF3F4F6);
  static const Color borderColor = Color(0xFFE5E7EB);
  static const Color textGrey = Color(0xFF9CA3AF);
  static const Color greenColor = Color(0xFF10B981);

  // Status colors
  static const Color pendingColor = Color(0xFF8B5CF6);
  static const Color approvedColor = Color(0xFF10B981);
  static const Color rejectedColor = Color(0xFFEF4444);

  // Gradient colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF5B67CA), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
