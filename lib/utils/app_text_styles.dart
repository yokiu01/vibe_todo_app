import 'package:flutter/material.dart';

class AppTextStyles {
  // Typography Scale as per UI Improvement Plan

  // H1 (페이지 제목): 24px, Bold, #2C3E50
  static const TextStyle h1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Color(0xFF2C3E50),
    height: 1.3,
  );

  // H2 (섹션 제목): 20px, Semibold, #34495E
  static const TextStyle h2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: Color(0xFF34495E),
    height: 1.3,
  );

  // H3 (카드 제목): 18px, Medium, #2C3E50
  static const TextStyle h3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: Color(0xFF2C3E50),
    height: 1.4,
  );

  // Body (본문): 16px, Regular, #5D6D7E
  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: Color(0xFF5D6D7E),
    height: 1.5,
  );

  // Caption (부가정보): 14px, Regular, #95A5A6
  static const TextStyle caption = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Color(0xFF95A5A6),
    height: 1.4,
  );

  // State Typography variations

  // 완료된 항목: 취소선 + 50% 투명도
  static TextStyle get bodyCompleted => body.copyWith(
    decoration: TextDecoration.lineThrough,
    color: body.color?.withOpacity(0.5),
  );

  static TextStyle get h3Completed => h3.copyWith(
    decoration: TextDecoration.lineThrough,
    color: h3.color?.withOpacity(0.5),
  );

  // 오늘 마감: Bold + Primary Color
  static TextStyle get bodyToday => body.copyWith(
    fontWeight: FontWeight.bold,
    color: const Color(0xFF8B4513), // AppColors.primaryBrown
  );

  static TextStyle get h3Today => h3.copyWith(
    fontWeight: FontWeight.bold,
    color: const Color(0xFF8B4513), // AppColors.primaryBrown
  );

  // Utility methods for common variations
  static TextStyle bodyWithColor(Color color) => body.copyWith(color: color);
  static TextStyle h3WithColor(Color color) => h3.copyWith(color: color);
  static TextStyle captionWithColor(Color color) => caption.copyWith(color: color);

  // Button text styles
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  // Navigation and tab styles
  static const TextStyle tabLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.2,
  );

  static const TextStyle navTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Color(0xFF2C3E50),
    height: 1.2,
  );
}