import 'package:digislips/app/core/theme/app_colors.dart';
import 'package:digislips/app/modules/auth/login/login_page.dart';
import 'package:digislips/app/modules/splash_screen/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegistrationController extends GetxController {
  // Text Controllers
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  // Observable variables
  var isLoading = false.obs;
  var isPasswordHidden = true.obs;
  var isConfirmPasswordHidden = true.obs;
  var isVerifyingEmail =
      false.obs; // New observable for email verification loading

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

  @override
  void onClose() {
    // Dispose controllers to prevent memory leaks
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  // Toggle password visibility
  void togglePasswordVisibility() {
    isPasswordHidden.value = !isPasswordHidden.value;
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordHidden.value = !isConfirmPasswordHidden.value;
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
    if (fullName.length < 2) {
      return 'Full name must be at least 2 characters long';
    }
    if (fullName.length > 50) {
      return 'Full name cannot exceed 50 characters';
    }
    // Check for valid name format (only letters, spaces, apostrophes, and hyphens)
    if (!RegExp(r"^[a-zA-Z\s'-]+$").hasMatch(fullName)) {
      return 'Full name can only contain letters, spaces, apostrophes, and hyphens';
    }
    return null;
  }

  String? validateEmail(String email) {
    if (email.isEmpty) {
      return 'Email cannot be empty';
    }

    // More comprehensive email validation
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address';
    }

    if (email.length > 254) {
      return 'Email address is too long';
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
    if (password.length > 128) {
      return 'Password cannot exceed 128 characters';
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
      return 'Please confirm your password';
    }
    if (confirmPassword != passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  // Check if parent email exists in students collection
  Future<Map<String, dynamic>?> _verifyParentEmailInStudents(
    String parentEmail,
  ) async {
    try {
      isVerifyingEmail.value = true;

      print('🔍 Verifying parent email in students collection: $parentEmail');

      // Query students collection to find student with matching parent email
      final querySnapshot = await _firestore
          .collection('students')
          .where('parentEmail', isEqualTo: parentEmail.trim().toLowerCase())
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Found student(s) with matching parent email
        final studentData = querySnapshot.docs.first.data();
        studentData['studentId'] =
            querySnapshot.docs.first.id; // Add document ID

        print(
          '✅ Found student with matching parent email: ${studentData['fullName']}',
        );
        return studentData;
      } else {
        print('❌ No student found with parent email: $parentEmail');
        return null;
      }
    } catch (e) {
      print('❌ Error verifying parent email: $e');
      return null;
    } finally {
      isVerifyingEmail.value = false;
    }
  }

  // Check if email exists in parents collection
  Future<bool> _isEmailExists(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('parents')
          .where('email', isEqualTo: email.trim().toLowerCase())
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking email: $e');
      return false;
    }
  }

  // Form validation
  bool _validateForm() {
    final validators = <String, String?>{
      'Full Name': validateFullName(fullNameController.text.trim()),
      'Email': validateEmail(emailController.text.trim()),
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
      _showErrorSnackbar('Validation Error', firstError);
      return false;
    }
    return true;
  }

  // Main registration method with parent email verification
  Future<void> registerUser() async {
    if (!_validateForm()) return;

    isLoading(true);

    try {
      String email = emailController.text.trim().toLowerCase();
      String fullName = fullNameController.text.trim();
      String password = passwordController.text;

      // Step 1: Verify parent email exists in students collection
      print('🔐 Step 1: Verifying parent email authorization...');
      final studentData = await _verifyParentEmailInStudents(email);

      if (studentData == null) {
        _showErrorSnackbar(
          'Registration Not Authorized',
          'This email is not registered as a parent email for any student. Please contact the school administration.',
        );
        return;
      }

      // Step 2: Check if parent account already exists
      print('🔐 Step 2: Checking if parent account already exists...');
      if (await _isEmailExists(email)) {
        _showErrorSnackbar(
          'Registration Failed',
          'An account with this email already exists',
        );
        return;
      }

      // Step 3: Create user in Firebase Auth
      print('🔐 Step 3: Creating Firebase Auth account...');
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      if (userCredential.user == null) {
        _showErrorSnackbar(
          'Registration Failed',
          'Failed to create user account',
        );
        return;
      }

      // Step 4: Update display name
      await userCredential.user?.updateDisplayName(fullName);

      // Step 5: Send email verification
      await userCredential.user?.sendEmailVerification();

      // Step 6: Create parent document in Firestore with student reference
      print('🔐 Step 6: Creating parent document in Firestore...');
      final parentData = {
        'uid': userCredential.user!.uid,
        'fullName': fullName,
        'email': email,
        'role': 'parent',
        'isEmailVerified': false,
        'profileComplete': true,
        'registrationDate': FieldValue.serverTimestamp(),
        'lastLoginDate': null,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        // Additional fields for future use
        'phoneNumber': null,
        'profileImageUrl': null,
        'preferences': {
          'notifications': true,
          'emailNotifications': true,
          'theme': 'light',
        },
        // Student reference data
        'studentData': {
          'studentId': studentData['studentId'],
          'studentName': studentData['fullName'],
          'rollNumber': studentData['rollNumber'],
          'department': studentData['department'],
          'semester': studentData['semester'],
          'phone': studentData['phone'],
          'parentPhone': studentData['parentPhone'] ?? studentData['phone'],
        },
        'authorizedFor':
            studentData['studentId'], // Quick reference for student ID
      };

      // Save to Firestore parents collection
      await _firestore
          .collection('parents')
          .doc(userCredential.user!.uid)
          .set(parentData);

      // Step 7: Update student document to include parent UID reference
      print('🔐 Step 7: Updating student document with parent reference...');
      await _firestore
          .collection('students')
          .doc(studentData['studentId'])
          .update({
            'parentUid': userCredential.user!.uid,
            'parentAccountCreated': true,
            'parentAccountCreatedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // Step 8: Show success message and navigate
      _showSuccessAndNavigate(
        'Account created successfully!',
        'Your parent account has been created for student ${studentData['fullName']} (${studentData['rollNumber']}). Please check your email to verify your account.',
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = _getFirebaseAuthErrorMessage(e.code);
      _showErrorSnackbar('Registration Failed', errorMessage);
    } catch (e) {
      _showErrorSnackbar(
        'Registration Failed',
        'An unexpected error occurred. Please try again.',
      );
      print('Registration error: $e');
    } finally {
      isLoading(false);
    }
  }

  // Method to verify parent email (can be called from UI)
  Future<void> verifyParentEmail() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      _showErrorSnackbar('Email Required', 'Please enter your email address');
      return;
    }

    if (validateEmail(email) != null) {
      _showErrorSnackbar('Invalid Email', 'Please enter a valid email address');
      return;
    }

    final studentData = await _verifyParentEmailInStudents(email);

    if (studentData != null) {
      _showSuccessSnackbar(
        'Email Verified!',
        'This email is authorized for student ${studentData['fullName']} (${studentData['rollNumber']})',
      );
    } else {
      _showErrorSnackbar(
        'Email Not Authorized',
        'This email is not registered as a parent email. Please contact the school administration.',
      );
    }
  }

  // Get user-friendly error messages for Firebase Auth errors
  String _getFirebaseAuthErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists with that email.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      default:
        return 'Registration failed. Please try again.';
    }
  }

  // Helper method to show success message and navigate
  void _showSuccessAndNavigate(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 5),
      icon: Icon(Icons.check_circle, color: Colors.white),
    );

    _clearForm();

    // Sign out the user so they need to verify email first
    _auth.signOut();

    // Navigate to login page after a short delay
    Future.delayed(Duration(seconds: 3), () {
      Get.offAll(() => SplashScreen());
    });
  }

  // Helper method to show error snackbar
  void _showErrorSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 4),
      icon: Icon(Icons.error, color: Colors.white),
    );
  }

  // Helper method to show success snackbar
  void _showSuccessSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 3),
      icon: Icon(Icons.check_circle, color: Colors.white),
    );
  }

  // Clear form
  void _clearForm() {
    fullNameController.clear();
    emailController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
  }

  // Utility methods
  String formatEmail(String email) {
    return email.trim().toLowerCase();
  }

  String formatFullName(String fullName) {
    return fullName.trim();
  }

  // Method to resend email verification (for future use)
  Future<void> resendEmailVerification() async {
    try {
      User? user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        Get.snackbar(
          'Email Sent',
          'Verification email has been sent to ${user.email}',
          backgroundColor: Colors.blue,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );
      }
    } catch (e) {
      _showErrorSnackbar('Error', 'Failed to send verification email');
      print('Error sending verification email: $e');
    }
  }

  // Method to check if user exists and is verified (for future use)
  Future<bool> checkUserVerificationStatus(String email) async {
    try {
      final userDoc = await _firestore
          .collection('parents')
          .where('email', isEqualTo: email.toLowerCase())
          .get();

      if (userDoc.docs.isNotEmpty) {
        return userDoc.docs.first.data()['isEmailVerified'] ?? false;
      }
      return false;
    } catch (e) {
      print('Error checking verification status: $e');
      return false;
    }
  }

  // Update user verification status in Firestore (for future use)
  Future<void> updateEmailVerificationStatus(
    String uid,
    bool isVerified,
  ) async {
    try {
      await _firestore.collection('parents').doc(uid).update({
        'isEmailVerified': isVerified,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating verification status: $e');
    }
  }

  // Method to get student data for authorized parent (for future use)
  Future<Map<String, dynamic>?> getAuthorizedStudentData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString('uid');

      if (uid == null) return null;

      final parentDoc = await _firestore.collection('parents').doc(uid).get();

      if (parentDoc.exists) {
        final parentData = parentDoc.data()!;
        return parentData['studentData'];
      }
      return null;
    } catch (e) {
      print('Error getting authorized student data: $e');
      return null;
    }
  }
}
