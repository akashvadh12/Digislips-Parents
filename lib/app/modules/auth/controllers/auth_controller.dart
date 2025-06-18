import 'package:digislips/app/core/theme/app_colors.dart';
import 'package:digislips/app/modules/auth/StudentRegistration/StudentRegistration.dart';
import 'package:digislips/app/routes/app_pages.dart';
import 'package:digislips/app/shared/widgets/bottomnavigation/bottomnavigation.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final formKey = GlobalKey<FormState>();
  final isLoading = false.obs;
  final isPasswordVisible = false.obs;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void onInit() {
    super.onInit();
    _checkIfLoggedIn(); // Check on startup
  }

  // Auto-login check
  Future<void> _checkIfLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('uid');

    if (uid != null && _auth.currentUser != null) {
      // If UID exists and session is valid
      Get.offAll(() => BottomNavBarWidget());
    }
  }

  // Toggle password visibility
  void togglePasswordVisibility() {
    isPasswordVisible.toggle();
  }

  // Email validation
  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    if (!GetUtils.isEmail(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  // Password validation
  String? validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Password is required';
    }
    if (value.trim().length < 6) {
      return 'Password must be at least 6 characters long';
    }
    return null;
  }

  // Login method with form validation
  Future<void> login() async {
    if (!formKey.currentState!.validate()) return;

    isLoading(true);
    try {
      final email = emailController.text.trim();
      final password = passwordController.text.trim();

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('uid', userCredential.user!.uid);

        // Navigate to dashboard and remove login from stack
        Get.offAllNamed(Routes.BOTTOM_NAVIGATION);

        _showSnackbar('Success', 'Login successful!', isSuccess: true);
      }
    } on FirebaseAuthException catch (e) {
      _handleFirebaseError(e);
    } finally {
      isLoading(false);
    }
  }

  // Forgot password logic
  Future<void> forgotPassword() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      _showSnackbar('Error', 'Please enter your email address first');
      return;
    }

    if (!GetUtils.isEmail(email)) {
      _showSnackbar('Error', 'Enter a valid email address');
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: email);
      _showSnackbar('Success', 'Password reset email sent!', isSuccess: true);
    } on FirebaseAuthException catch (e) {
      _handleFirebaseError(e);
    } catch (e) {
      _showSnackbar('Error', 'Unexpected error: ${e.toString()}');
    }
  }

  // Navigate to registration screen
  void navigateToSignUp() {
    Get.to(() => RegistrationScreen());
  }

  // Error display helper
  void _showSnackbar(String title, String message, {bool isSuccess = false}) {
    Get.snackbar(
      title,
      message,
      backgroundColor: isSuccess ? AppColors.greenColor : AppColors.error,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(12),
    );
  }

  // FirebaseAuth error mapping
  void _handleFirebaseError(FirebaseAuthException e) {
    final Map<String, String> errorMessages = {
      'user-not-found': 'No user found with this email.',
      'wrong-password': 'Incorrect password. Try again.',
      'invalid-email': 'Invalid email address.',
      'user-disabled': 'This account has been disabled.',
      'too-many-requests': 'Too many attempts. Try again later.',
      'network-request-failed': 'Network error. Check your connection.',
    };

    final errorMessage =
        errorMessages[e.code] ?? (e.message ?? 'Login failed. Try again.');
    _showSnackbar(
      'Login error',
      'Please check your credentials and try again.',
    );
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
