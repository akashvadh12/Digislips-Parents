import 'package:digislips/app/core/theme/app_colors.dart';
import 'package:digislips/app/modules/auth/controllers/Teacher_registration/teacher_model.dart';
import 'package:digislips/app/modules/auth/login/login_page.dart';
import 'package:digislips/app/modules/splash_screen/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TeacherRegistrationController extends GetxController {
  // Text Controllers
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController parentUidController = TextEditingController();

  // Department options
  final List<String> departments = [
    'CS',
    'IT',
    'ECE',
    'EEE',
    'MECH',
    'CIVIL',
    'CHEM',
    'BIO',
  ];

  // Observable variables
  var isLoading = false.obs;
  var isPasswordHidden = true.obs;
  var isConfirmPasswordHidden = true.obs;
  var selectedDepartment = Rxn<String>(); // Observable for selected department

  // Password validation observables
  var hasMinLength = false.obs;
  var hasUppercase = false.obs;
  var hasLowercase = false.obs;
  var hasNumber = false.obs;
  var hasSpecialChar = false.obs;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void onInit() {
    super.onInit();
    passwordController.addListener(_validatePasswordRequirements);
  }

  // Toggle password visibility
  void togglePasswordVisibility() {
    isPasswordHidden.value = !isPasswordHidden.value;
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordHidden.value = !isConfirmPasswordHidden.value;
  }

  // Department selection
  void selectDepartment(String? department) {
    selectedDepartment.value = department;
  }

  // Password validation
  void _validatePasswordRequirements() {
    String password = passwordController.text;

    hasMinLength.value = password.length >= 8;
    hasUppercase.value = password.contains(RegExp(r'[A-Z]'));
    hasLowercase.value = password.contains(RegExp(r'[a-z]'));
    hasNumber.value = password.contains(RegExp(r'[0-9]'));
    hasSpecialChar.value = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
  }

  bool get isPasswordStrong =>
      hasMinLength.value &&
      hasUppercase.value &&
      hasLowercase.value &&
      hasNumber.value &&
      hasSpecialChar.value;

  // Field validations
  String? validateFullName(String fullName) {
    if (fullName.isEmpty) {
      return 'Full name cannot be empty';
    }
    if (fullName.length < 3) {
      return 'Full name must be at least 3 characters long';
    }
    return null;
  }

  String? validateEmail(String email) {
    if (email.isEmpty) {
      return 'Email cannot be empty';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(email)) {
      return 'Invalid email format';
    }
    return null;
  }

  String? validatePhone(String phone) {
    if (phone.isEmpty) {
      return 'Phone number cannot be empty';
    }
    final phoneRegex = RegExp(r'^\d{10}$');
    if (!phoneRegex.hasMatch(phone)) {
      return 'Invalid phone number format (must be 10 digits)';
    }
    return null;
  }

  String? validateDepartment() {
    if (selectedDepartment.value == null || selectedDepartment.value!.isEmpty) {
      return 'Please select a department';
    }
    return null;
  }

  String? validatePassword(String password) {
    if (password.isEmpty) {
      return 'Password cannot be empty';
    }
    if (password.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character';
    }
    return null;
  }

  String? validateConfirmPassword(String confirmPassword) {
    if (confirmPassword.isEmpty) {
      return 'Confirm password cannot be empty';
    }
    if (confirmPassword != passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<bool> _isEmailExists(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('teachers')
          .where('email', isEqualTo: email.trim().toLowerCase())
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking email: $e');
      return false;
    }
  }

  // Future<bool> _isParentUidExists(String parentUid) async {
  //   try {
  //     final querySnapshot = await _firestore
  //         .collection('teachers')
  //         .where('parentUid', isEqualTo: parentUid.trim())
  //         .limit(1)
  //         .get();

  //     return querySnapshot.docs.isNotEmpty;
  //   } catch (e) {
  //     print('Error checking parent UID: $e');
  //     return false;
  //   }
  // }

  // Enhanced method to ensure complete sign out
  Future<void> _ensureSignedOut() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        await _auth.signOut();
        // Wait a bit to ensure sign out is complete
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } catch (e) {
      print('Error during sign out: $e');
    }
  }

  // Registration
  Future<void> registerTeacher() async {
    if (!_validateForm()) return;

    isLoading(true);

    try {
      // Ensure we start with a clean state
      await _ensureSignedOut();

      String email = emailController.text.trim().toLowerCase();
      String parentUid = parentUidController.text.trim();

      // Check if email exists in Firestore
      if (await _isEmailExists(email)) {
        isLoading(false);
        Get.snackbar(
          'Registration Failed',
          'An account with this email already exists',
          backgroundColor: AppColors.error,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );
        return;
      }

      // Check if parent UID exists
      // if (await _isParentUidExists(parentUid)) {
      //   isLoading(false);
      //   Get.snackbar(
      //     'Registration Failed',
      //     'This Parent UID is already registered',
      //     backgroundColor: AppColors.error,
      //     colorText: Colors.white,
      //     snackPosition: SnackPosition.TOP,
      //     margin: const EdgeInsets.all(16),
      //     borderRadius: 12,
      //   );
      //   return;
      // }

      // Create user in Firebase Auth
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: email,
            password: passwordController.text,
          );

      if (userCredential.user == null) {
        isLoading(false);
        Get.snackbar(
          'Registration Failed',
          'Failed to create user',
          backgroundColor: AppColors.error,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );
        return;
      }

      // Update display name
      try {
        await userCredential.user?.updateDisplayName(
          fullNameController.text.trim(),
        );
        await userCredential.user?.reload(); // Refresh user data
      } catch (e) {
        print('Failed to update display name: $e');
      }

      // Prepare teacher model - UID is automatically generated by Firebase Auth
      final teacher = Teacher(
        uid: userCredential.user!.uid, // Auto-generated by Firebase
        fullName: fullNameController.text.trim(),
        email: email,
        phone: phoneController.text.trim(),
        parentUid: parentUid,
        department: selectedDepartment.value!, // Add department
        profileComplete: true,
        profileImageUrl: null,
        isEmailVerified: false,
      );

      // Save to Firestore with transaction to ensure atomicity
      await _firestore.runTransaction((transaction) async {
        // Double-check if email exists within transaction
        final emailCheck = await _firestore
            .collection('teachers')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

        if (emailCheck.docs.isNotEmpty) {
          throw Exception('Email already exists');
        }

        // Double-check if parent UID exists within transaction
        // final parentUidCheck = await _firestore
        //     .collection('teachers')
        //     .where('parentUid', isEqualTo: parentUid)
        //     .limit(1)
        //     .get();

        // if (parentUidCheck.docs.isNotEmpty) {
        //   throw Exception('Parent UID already exists');
        // }

        // Set the document
        transaction.set(
          _firestore.collection('teachers').doc(teacher.uid),
          teacher.toMap(),
        );
      });

      // Send email verification
      try {
        await userCredential.user?.sendEmailVerification();
      } catch (e) {
        print('Failed to send email verification: $e');
      }

      // Save UID to SharedPreferences for future use
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('uid', teacher.uid);

      Get.snackbar(
        'Registration Successful!',
        'Please login to verify your account',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 5),
      );

      _clearForm();

      // Ensure complete sign out before navigation
      await _ensureSignedOut();

      // Navigate to splash screen
      Get.offAll(() => SplashScreen());
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'An account already exists with this email';
          break;
        case 'weak-password':
          errorMessage = 'Password is too weak';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Email registration not enabled';
          break;
        case 'network-request-failed':
          errorMessage = 'Network error. Please check your connection';
          break;
        default:
          errorMessage = 'Registration failed: ${e.message}';
      }
      Get.snackbar(
        'Registration Failed',
        errorMessage,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } catch (e) {
      // Handle transaction errors
      if (e.toString().contains('Email already exists')) {
        Get.snackbar(
          'Registration Failed',
          'An account with this email already exists',
          backgroundColor: AppColors.error,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );
      } else {
        Get.snackbar(
          'Registration Failed',
          'An unexpected error occurred: ${e.toString()}',
          backgroundColor: AppColors.error,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );
      }
    } finally {
      isLoading(false);
    }
  }

  bool _validateForm() {
    final validators = {
      'Full Name': validateFullName(fullNameController.text),
      'Email': validateEmail(emailController.text),
      'Phone': validatePhone(phoneController.text),
      'Department': validateDepartment(),
      'Password': validatePassword(passwordController.text),
      'Confirm Password': validateConfirmPassword(
        confirmPasswordController.text,
      ),
    };

    final firstError = validators.values.firstWhere(
      (v) => v != null,
      orElse: () => null,
    );

    if (firstError != null) {
      Get.snackbar(
        'Required fields are missing',
        firstError,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      return false;
    }
    return true;
  }

  void _clearForm() {
    fullNameController.clear();
    emailController.clear();
    phoneController.clear();
    parentUidController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    selectedDepartment.value = null;
  }

  @override
  void onClose() {
    fullNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    parentUidController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
