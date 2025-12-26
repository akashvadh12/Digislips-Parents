import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digislips/app/core/theme/app_colors.dart';
import 'package:digislips/app/modules/auth/Registration/Registration.dart';
import 'package:digislips/app/modules/auth/controllers/Teacher_registration/Teacher_registration.dart';
import 'package:digislips/app/routes/app_pages.dart';
import 'package:digislips/app/shared/widgets/Custom_Snackbar/Custom_Snackbar.dart';
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
  final department = ''.obs;

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
        final uid = userCredential.user!.uid;

        // Save basic session info
        await prefs.setString('uid', uid);
        await prefs.setString('Email', email);
        await prefs.setString('userRole', selectedRole.value!);
        await prefs.setBool('isParent', isParent.value);
        await prefs.setBool('isTeacher', isTeacher.value);

        print("🔐✅ Login Successful!");
        print("📧 Email: $email");
        print("🆔 UID: $uid");
        print("🧑‍💼 Role: ${selectedRole.value!}");

        // Fetch and store user details based on role
        String collection = selectedRole.value == 'Teacher'
            ? 'teachers'
            : 'parents';

        final doc = await FirebaseFirestore.instance
            .collection(collection)
            .doc(uid)
            .get();

        if (doc.exists) {
          final userData = doc.data()!;
          print("📄 ${selectedRole.value} Profile Data:");
          userData.forEach((key, value) {
            print("🔹 $key: $value");
          });

          // Store all user fields into SharedPreferences
          for (var entry in userData.entries) {
            if (entry.value is String) {
              await prefs.setString(entry.key, entry.value);
            } else if (entry.value is bool) {
              await prefs.setBool(entry.key, entry.value);
            } else if (entry.value is int) {
              await prefs.setInt(entry.key, entry.value);
            } else if (entry.value is double) {
              await prefs.setDouble(entry.key, entry.value);
            } else {
              // Convert other types to string
              await prefs.setString(entry.key, entry.value.toString());
            }
          }
        } else {
          print("❌ No ${selectedRole.value} data found for UID: $uid");
        }

        // Continue login
        getUserDetailsFromPrefs();
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

    // Retrieve all expected values
    String? uid = prefs.getString('uid');
    String? email = prefs.getString('email');
    String? userRole = prefs.getString('userRole');
    bool? isParent = prefs.getBool('isParent');
    bool? isTeacher = prefs.getBool('isTeacher');
    String? fullName = prefs.getString('fullName');
    String? phone = prefs.getString('phone');
    String? departmentFromPrefs = prefs.getString('department');
    String? profileImageUrl = prefs.getString('profileImageUrl');
    String? parentUid = prefs.getString('parentUid');
    bool? profileComplete = prefs.getBool('profileComplete');
    bool? isEmailVerified = prefs.getBool('isEmailVerified');
    String? createdAt = prefs.getString('createdAt');
    String? updatedAt = prefs.getString('updatedAt');

    // Set observable or use them in your app
    department.value = departmentFromPrefs ?? '';

    // Logging for debug
    print("📧 Email: $email");
    print("🆔 UID: $uid");
    print("🧑‍🏫 Role: $userRole");
    print("👨‍👧 Is Parent: $isParent");
    print("👩‍🏫 Is Teacher: $isTeacher");
    print("👤 Full Name: $fullName");
    print("📱 Phone: $phone");
    print("🏢 Department: $departmentFromPrefs");
    print("🖼️ Profile Image: $profileImageUrl");
    print("👪 Parent UID: $parentUid");
    print("✅ Profile Complete: $profileComplete");
    print("📨 Email Verified: $isEmailVerified");
    print("🕒 Created At: $createdAt");
    print("🕒 Updated At: $updatedAt");
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
      //Get.to(TeacherRegistrationPage());
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
    // emailController.dispose();
    // passwordController.dispose();
    super.onClose();
  }
}
