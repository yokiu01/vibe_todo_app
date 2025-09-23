import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primaryBrown = Color(0xFF8B4513);
  static const Color primaryBrownLight = Color(0xFFA0522D);
  static const Color primaryBrownDark = Color(0xFF654321);

  // Accent Colors (Extended 2030 Generation Palette)
  static const Color accentBlue = Color(0xFF4A90E2);
  static const Color accentGreen = Color(0xFF7ED321);
  static const Color accentOrange = Color(0xFFF5A623);

  // New 2030 Generation Colors
  static const Color mint = Color(0xFF7ED4AD);        // 완료 상태
  static const Color lavender = Color(0xFFA8A4FF);    // 계획 단계
  static const Color peach = Color(0xFFFFB4A1);       // 긴급 항목
  static const Color softBlue = Color(0xFF7FB3D3);    // 일반 항목

  // Neutral Colors
  static const Color gray50 = Color(0xFFFAFAFA);
  static const Color gray100 = Color(0xFFF5F5F5);
  static const Color gray200 = Color(0xFFEEEEEE);
  static const Color gray300 = Color(0xFFE0E0E0);
  static const Color gray400 = Color(0xFFBDBDBD);
  static const Color gray500 = Color(0xFF9E9E9E);
  static const Color gray600 = Color(0xFF757575);
  static const Color gray700 = Color(0xFF424242);
  static const Color gray800 = Color(0xFF212121);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Priority Colors (According to UI Improvement Plan)
  static const Color priorityUrgent = Color(0xFFFF6B6B);    // 긴급 (Coral Red)
  static const Color priorityImportant = Color(0xFF4ECDC4); // 중요 (Teal)
  static const Color priorityNormal = Color(0xFF95A5A6);    // 일반 (Gray)

  // State Colors
  static const Color completed = mint;                      // 완료 상태
  static const Color planning = lavender;                   // 계획 단계
  static const Color urgent = peach;                        // 긴급 항목
  static const Color normal = softBlue;                     // 일반 항목

  // Current theme colors (keeping existing ones for compatibility)
  static const Color background = Color(0xFFF5F1E8);
  static const Color cardBackground = Color(0xFFFDF6E3);
  static const Color borderColor = Color(0xFFDDD4C0);
  static const Color textPrimary = Color(0xFF3C2A21);
  static const Color textSecondary = Color(0xFF9C8B73);
  static const Color activeTab = Color(0xFF8B7355);
}