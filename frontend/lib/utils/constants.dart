import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFFF7F27); // Vibrant Orange
  static const Color background = Color(0xFF121212); // Very Dark
  static const Color surface = Color(0xFF1E1E1E); // Dark Grey Card
  static const Color text = Colors.white;
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color error = Color(0xFFCF6679);
  static const Color success = Color(0xFF4CAF50);
}

class AppConstants {
  // Use 10.0.2.2 for Android Emulator to access localhost
  static const String baseUrl = 'http://10.0.2.2:3000/api';
}
