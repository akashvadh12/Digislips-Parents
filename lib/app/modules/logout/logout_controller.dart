import 'package:digislips/app/core/theme/app_colors.dart';
import 'package:digislips/app/modules/dashboard/dashboard_controller.dart';
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
  var uid = ''.obs;
  var userRole = ''.obs;
  var userEmail = ''.obs;
  var isParent = false.obs;
  var isTeacher = false.obs;

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
    slideAnimation = Tween<Offset>(begin: Offset(0, 0.3), end: Offset.zero)
        .animate(
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

    // Simulate logout progress
    for (int i = 0; i <= 100; i += 2) {
      logoutProgress.value = i / 100;
      await Future.delayed(Duration(milliseconds: 30));
    }

    try {
      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();
      final HomeController homeController = Get.put(HomeController());
      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      homeController.resetUserData();
      await Get.delete<HomeController>(force: true);
      // Get.delete<HomeController>();

      // Reset in-memory observables (local storage)
      uid.value = '';
      userRole.value = '';
      userEmail.value = '';
      isParent.value = false;
      isTeacher.value = false;

      // Re-set SharedPrefs defaults if required by app logic
      await prefs.setBool('isLoggedIn', false);
      await prefs.setString('userRole', '');
      await prefs.setString('uid', '');
      await prefs.setBool('isParent', false);
      await prefs.setBool('isTeacher', false);
      await prefs.setString('Email', '');

      // ✅ Print all cleared SharedPreferences
      print("✅ SharedPreferences after logout:");
      print("isLoggedIn: ${prefs.getBool('isLoggedIn')}");
      print("userRole: ${prefs.getString('userRole')}");
      print("uid: ${prefs.getString('uid')}");
      print("isParent: ${prefs.getBool('isParent')}");
      print("isTeacher: ${prefs.getBool('isTeacher')}");
      print("Email: ${prefs.getString('Email')}");

      // ✅ Print GetX reactive variables after clearing
      print("✅ Local reactive variables after logout:");
      print("uid: ${uid.value}");
      print("userRole: ${userRole.value}");
      print("Email: ${userEmail.value}");
      print("isParent: ${isParent.value}");
      print("isTeacher: ${isTeacher.value}");

      // Show logout success
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

      // Navigate to login screen
      await Future.delayed(Duration(seconds: 1));
      Get.offAllNamed('/login');
    } catch (e) {
      print('❌ Error during logout: $e');
      Get.snackbar(
        'Logout Failed',
        'Something went wrong while logging out.',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    } finally {
      isLoggingOut.value = false;
    }
  }

  void cancelLogout() {
    Get.back();
  }

  @override
  void onClose() {
    fadeController.dispose();
    slideController.dispose();
    pulseController.dispose();
    super.onClose();
  }
}
