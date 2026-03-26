import 'package:flutter/foundation.dart';

class AppLog {
  static void logD(String className, String methodName, String content) {
    final methodPart = methodName.isNotEmpty ? '[$methodName]' : '';
    final msg = "[TAGWITH][$className]$methodPart $content";

    if (kDebugMode) {
      debugPrint(msg);
    }
  }
}
