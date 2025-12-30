import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomSnackbar {
  static void showSuccess(String title, String message) {
    _showSnack(
      title: title,
      message: message,
      backgroundColor: Colors.green.shade600,
      icon: const Icon(Icons.check_circle, color: Colors.white),
    );
  }

  static void showError(String title, String message, {IconData? icon}) {
    _showSnack(
      title: title,
      message: message,
      backgroundColor: Colors.red.shade600,
      icon: Icon(icon ?? Icons.error, color: Colors.white),
    );
  }

  static void showWarning(String title, String message) {
    _showSnack(
      title: title,
      message: message,
      backgroundColor: Colors.orange.shade600,
      icon: const Icon(Icons.warning, color: Colors.white),
    );
  }

  static void showInfo(String title, String message) {
    _showSnack(
      title: title,
      message: message,
      backgroundColor: Colors.blue.shade600,
      icon: const Icon(Icons.info, color: Colors.white),
    );
  }

  static Future<void> _showSnack({
    required String title,
    required String message,
    required Color backgroundColor,
    required Widget icon,
  }) async {
    // Delay briefly to let overlay settle after dialog closes
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      final overlayContext = Get.overlayContext;
      if (overlayContext == null) {
        if (kDebugMode) {
          debugPrint('⚠️ Snackbar skipped: no overlay context');
        }
        return;
      }

      // Check if overlay exists without throwing
      try {
        Overlay.of(overlayContext);
      } catch (_) {
        if (kDebugMode) {
          debugPrint('⚠️ Snackbar skipped: overlay not found');
        }
        return;
      }

      Get.showSnackbar(
        GetSnackBar(
          titleText: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          messageText: Text(
            message,
            style: const TextStyle(color: Colors.white),
          ),
          icon: icon,
          backgroundColor: backgroundColor,
          margin: const EdgeInsets.all(12),
          borderRadius: 10,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 2),
          barBlur: 10,
          overlayBlur: 2,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Snackbar failed to show: $e');
      }
    }
  }
}
