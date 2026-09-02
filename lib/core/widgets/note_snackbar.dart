import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

/// Premium glassmorphism snackbar used across the entire app.
///
/// Wraps [Get.rawSnackbar] with a frosted-glass container, smooth
/// animations, haptic feedback, and clean iconography.
class GlassSnackbar {
  const GlassSnackbar._();

  static void show({
    required String message,
    bool isError = false,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 2),
  }) {
    // GetX's overlay is only configured once a GetMaterialApp mounts. Guard
    // so a snackbar fired before that (or off a non-Get route) degrades
    // gracefully instead of throwing.
    if (Get.key.currentState?.overlay == null) return;

    HapticFeedback.lightImpact();
    Get.rawSnackbar(
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.transparent,
      margin: EdgeInsets.only(bottom: 50.h, left: 30.w, right: 30.w),
      duration: duration,
      forwardAnimationCurve: Curves.easeOutBack,
      messageText: ClipRRect(
        borderRadius: BorderRadius.circular(25.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 20.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(25.r),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isError
                      ? Icons.info_outline_rounded
                      : Icons.check_circle_rounded,
                  color: isError ? Colors.orange[800] : Colors.green[800],
                  size: 24.sp,
                ),
                SizedBox(width: 12.w),
                Flexible(
                  child: Text(
                    message,
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (actionLabel != null && onAction != null) ...[
                  SizedBox(width: 12.w),
                  GestureDetector(
                    onTap: () {
                      Get.closeAllSnackbars();
                      onAction();
                    },
                    child: Text(
                      actionLabel,
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}