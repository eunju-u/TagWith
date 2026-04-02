import 'package:flutter/material.dart';

class AppSnackBar {
  static void show(BuildContext context, String message) {
    final theme = Theme.of(context);
    
    // 이전 스낵바가 있다면 제거
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    
    final isDarkMode = theme.brightness == Brightness.dark;
    
    // 다크모드 대응을 위한 배경색/글자색 동적 설정
    final backgroundColor = isDarkMode ? const Color(0xFF374151) : const Color(0xFFF8F9FA);
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(20),
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
