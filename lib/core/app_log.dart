import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

class AppLog {
  static void logD(String className, String methodName, String content) {
    // 디버그 모드일 때만 로그 동작
    // if (!kDebugMode) return;

    final methodPart = methodName.isNotEmpty ? '[$methodName]' : '';
    final tag = "TAGWITH:[$className]$methodPart";
    
    // 긴 로그도 잘리지 않도록 message 파라미터에 content 전달
    developer.log(content, name: tag);
  }
}
