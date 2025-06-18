import 'package:digislips/app/core/theme/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LogoutController extends GetxController with GetTickerProviderStateMixin {
  late AnimationController fadeController;
  late AnimationController slideController;
  late AnimationController pulseController;

  late Animation<double> fadeAnimation;
  late Animation<Offset> slideAnimation;
  late Animation<double> pulseAnimation;

  var isLoggingOut = false.obs;
  var logoutProgress = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    // Fade animation for main content
    fadeController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: fadeController, curve: Curves.easeInOut));

    // Slide animation for cards
    slideController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: slideController, curve: Curves.elasticOut),
    );

    // Pulse animation for logout icon
    pulseController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );
    pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: pulseController, curve: Curves.easeInOut),
    );

    // Start animations
    fadeController.forward();
    slideController.forward(from: 0.0);
    pulseController.repeat(reverse: true);
  }

  Future<void> confirmLogout() async {
    isLoggingOut.value = true;

    // Simulate logout process with progress
    for (int i = 0; i <= 100; i += 2) {
      logoutProgress.value = i / 100;
      await Future.delayed(Duration(milliseconds: 30));
    }

    // Show success message
    Get.snackbar(
      'Success',
      'You have been logged out successfully',
      backgroundColor: AppColors.success.withOpacity(0.1),
      colorText: AppColors.success,
      snackPosition: SnackPosition.TOP,
      margin: EdgeInsets.all(16),
      borderRadius: 12,
      duration: Duration(seconds: 2),
      icon: Icon(Icons.check_circle, color: AppColors.success),
    );

    await FirebaseAuth.instance.signOut();

    //Clear UID from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('uid');
    // Navigate to login screen after delay
    await Future.delayed(Duration(seconds: 1));
    Get.offAllNamed('/login'); // Replace with your login route
  }

  void cancelLogout() {
    Get.back();
    Get.snackbar(
      'Cancelled',
      'Logout cancelled',
      backgroundColor: AppColors.greyColor.withOpacity(0.1),
      colorText: AppColors.greyColor,
      snackPosition: SnackPosition.TOP,
      margin: EdgeInsets.all(16),
      borderRadius: 12,
      duration: Duration(seconds: 1),
    );
  }

  @override
  void onClose() {
    fadeController.dispose();
    slideController.dispose();
    pulseController.dispose();
    super.onClose();
  }
}
