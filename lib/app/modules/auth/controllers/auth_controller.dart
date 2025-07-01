import 'package:digislips/app/core/theme/app_colors.dart';
import 'package:digislips/app/modules/auth/Registration/Registration.dart';
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

  // Role selection variables
  final selectedRole = Rx<String?>(null);
  final isParent = false.obs;
  final isTeacher = false.obs;

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

    final userRole = prefs.getString('userRole');
    print("this is user id😁😁👍 $uid");
    print("this is user role:😁😁👌 $userRole");

    if (uid != null && _auth.currentUser != null && userRole != null) {
      // If UID exists, session is valid, and role is stored
      selectedRole.value = userRole;
      _updateRoleFlags(userRole);
      Get.offAll(() => BottomNavBarWidget());
    }
  }

  // Role selection method
  void selectRole(String role) {
    selectedRole.value = role;
    _updateRoleFlags(role);
  }

  // Update role flags
  void _updateRoleFlags(String role) {
    isParent.value = role == 'Parent';
    isTeacher.value = role == 'Teacher';
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

  // Role validation
  String? validateRole() {
    if (selectedRole.value == null) {
      return 'Please select your role';
    }
    return null;
  }

  // Login method with form validation and role check
  Future<void> login() async {
    // Validate role first
    if (selectedRole.value == null) {
      _showSnackbar('Error', 'Please select your role (Parent or Teacher)');
      return;
    }

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

        // Store user role in SharedPreferences
        await prefs.setString('Email', email);
        await prefs.setString('userRole', selectedRole.value!);
        await prefs.setBool('isParent', isParent.value);
        await prefs.setBool('isTeacher', isTeacher.value);

        // 🎉 Print session info with emojis
        print("🔐✅ Login Successful!");
        print("😁👌👌 $email");
        print("🆔 UID: ${userCredential.user!.uid}");
        print("🧑‍💼 Role: ${selectedRole.value!}");
        print("👨‍👧 isParent: ${isParent.value}");
        print("👩‍🏫 isTeacher: ${isTeacher.value}");

        // Load user details from preferences (optional)
        getUserDetailsFromPrefs();

        // Navigate to dashboard and remove login from stack
        Get.offAllNamed(Routes.BOTTOM_NAVIGATION);

        _showSnackbar(
          'Success',
          'Login successful as ${selectedRole.value}!',
          isSuccess: true,
        );
      }
    } on FirebaseAuthException catch (e) {
      _handleFirebaseError(e);
    } finally {
      isLoading(false);
    }
  }

  // get user data
  Future<void> getUserDetailsFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    // Get stored values
    String? uid = prefs.getString('uid');
    String? userRole = prefs.getString('userRole');
    bool? isParent = prefs.getBool('isParent');
    bool? isTeacher = prefs.getBool('isTeacher');
    String? email = prefs.getString('Email');
    String? name = prefs.getString('name');

    // Print or use them
    print("email is 😁😁👌 $email");
    print('UID😁😁😁👍: $uid');
    print('Role😊👌👌: $userRole');
    print('Is Parent😁: $isParent');
    print('Is Teacher😁: $isTeacher');
    print('this is parents name $name');

    // Example: Navigate based on role
    // Safely handle route redirection
    if (userRole?.toLowerCase() == 'parent') {
      Get.offAllNamed('/parent-dashboard');
    } else if (userRole?.toLowerCase() == 'teacher') {
      Get.offAllNamed('/teacher-dashboard');
    } else {
      // Optional: fallback route or show error
      Get.snackbar("Error", "Unknown user role: $userRole");
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

  // Navigate to registration screen (only for parents)
  void navigateToSignUp() {
    if (isParent.value) {
      Get.to(() => RegistrationScreen());
    } else {
      _showSnackbar(
        'Info',
        'Only parents can sign up. Teachers should contact administration.',
      );
    }
  }

  // Check if signup should be visible (only for parents)
  bool get shouldShowSignup => isParent.value;

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
