import 'package:flutter/material.dart';
import '../../core/theme.dart';

class AppLoadingOverlay {
  static OverlayEntry? _overlay;

  static void show(BuildContext context) {
    if (_overlay != null) return;

    _overlay = OverlayEntry(
      builder: (context) => Material(
        color: Colors.black.withValues(alpha: 0.35), // 배경을 살짝 더 어둡게 조정
        child: Stack(
          children: [
            // 터치 방지 레이어
            const ModalBarrier(dismissible: false, color: Colors.transparent),
            Center(
              child: const CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 3,
              ),
            ),
          ],
        ),
      ),
    );

    Overlay.of(context).insert(_overlay!);
  }

  static void hide() {
    _overlay?.remove();
    _overlay = null;
  }
}
