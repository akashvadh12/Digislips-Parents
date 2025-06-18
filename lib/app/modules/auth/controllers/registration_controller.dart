import 'package:digislips/app/core/theme/app_colors.dart';
import 'package:digislips/app/modules/auth/login/login_page.dart';
import 'package:digislips/app/modules/auth/models/user_model.dart';
import 'package:digislips/app/modules/splash_screen/splash_screen.dart';
import 'package:digislips/app/shared/widgets/bottomnavigation/bottomnavigation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegistrationController extends GetxController {
  // Text Controllers
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController rollNumberController = TextEditingController();
  final TextEditingController studentRollNumberController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  // Observable variables
  var selectedRole = ''.obs;
  var selectedDepartment = ''.obs;
  var isLoading = false.obs;
  var isPasswordHidden = true.obs;
  var isConfirmPasswordHidden = true.obs;

  // Password validation observables
  var hasMinLength = false.obs;
  var hasUppercase = false.obs;
  var hasLowercase = false.obs;
  var hasNumber = false.obs;
  var hasSpecialChar = false.obs;

  final List<String> roles = ['Teacher', 'Parent', 'Student'];
  
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
    phoneController.dispose();
    rollNumberController.dispose();
    studentRollNumberController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  // Handle role change
  void onRoleChanged(String role) {
    selectedRole.value = role;
    // Clear department selection when role changes
    selectedDepartment.value = '';
    // Clear student roll number when switching from parent to teacher
    if (role == 'Teacher') {
      studentRollNumberController.clear();
    }
    // Clear roll number when switching from student to other roles
    if (role != 'Student') {
      rollNumberController.clear();
    }
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
    if (fullName.length < 3) {
      return 'Full name must be at least 3 characters long';
    }
    // Check for valid name format (only letters and spaces)
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(fullName)) {
      return 'Full name can only contain letters and spaces';
    }
    return null;
  }

  String? validateRole() {
    if (selectedRole.value.isEmpty) {
      return 'Please select your role';
    }
    return null;
  }

  String? validateDepartment() {
    if ((selectedRole.value == 'Teacher' || selectedRole.value == 'Student') && 
        selectedDepartment.value.isEmpty) {
      return 'Please select department';
    }
    return null;
  }

  String? validateStudentRollNumber(String rollNumber) {
    if (selectedRole.value == 'Parent') {
      if (rollNumber.isEmpty) {
        return 'Student roll number cannot be empty';
      }
      if (rollNumber.length < 5) {
        return 'Student roll number must be at least 5 characters long';
      }
    }
    return null;
  }

  String? validateRollNumber(String rollNumber) {
    if (selectedRole.value == 'Student') {
      if (rollNumber.isEmpty) {
        return 'Roll number cannot be empty';
      }
      if (rollNumber.length < 5) {
        return 'Roll number must be at least 5 characters long';
      }
    }
    return null;
  }

  String? validateEmailOrPhone(String input) {
    if (input.isEmpty) {
      return 'Email or phone cannot be empty';
    }
    
    // Check if it's an email
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    // Check if it's a phone number (10 digits)
    final phoneRegex = RegExp(r'^\d{10}$');
    
    if (!emailRegex.hasMatch(input) && !phoneRegex.hasMatch(input)) {
      return 'Enter a valid email or 10-digit phone number';
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
      return 'Phone number must be exactly 10 digits';
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

  // Check if email exists in any collection
  Future<bool> _isEmailExists(String email) async {
    try {
      // Check in students collection
      final studentQuery = await _firestore
          .collection('students')
          .where('email', isEqualTo: email.trim().toLowerCase())
          .get();

      // Check in teachers collection
      final teacherQuery = await _firestore
          .collection('teachers')
          .where('email', isEqualTo: email.trim().toLowerCase())
          .get();

      // Check in parents collection
      final parentQuery = await _firestore
          .collection('parents')
          .where('email', isEqualTo: email.trim().toLowerCase())
          .get();

      return studentQuery.docs.isNotEmpty || 
             teacherQuery.docs.isNotEmpty || 
             parentQuery.docs.isNotEmpty;
    } catch (e) {
      print('Error checking email: $e');
      return false;
    }
  }

  // Check if student roll number exists
  Future<bool> _isStudentRollNumberExists(String rollNumber) async {
    try {
      final querySnapshot = await _firestore
          .collection('students')
          .where('rollNumber', isEqualTo: rollNumber.trim().toUpperCase())
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking student roll number: $e');
      return false;
    }
  }

  // Check if roll number exists in specific department
  Future<bool> _isRollNumberExists(String rollNumber, String department) async {
    try {
      final querySnapshot = await _firestore
          .collection('students')
          .where('rollNumber', isEqualTo: rollNumber.trim().toUpperCase())
          .where('department', isEqualTo: department)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking roll number: $e');
      return false;
    }
  }

  // Check if teacher with same email and department exists
  Future<bool> _isTeacherExists(String email, String department) async {
    try {
      final querySnapshot = await _firestore
          .collection('teachers')
          .where('email', isEqualTo: email.trim().toLowerCase())
          .where('department', isEqualTo: department)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking teacher: $e');
      return false;
    }
  }

  // Main registration method that handles all user types
  Future<void> registerUser() async {
    if (!_validateForm()) return;

    isLoading(true);

    try {
      String emailOrPhone = emailController.text.trim();
      
      // Determine if input is email or phone
      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
      bool isEmail = emailRegex.hasMatch(emailOrPhone);
      
      String email = '';
      String phone = '';
      
      if (isEmail) {
        email = emailOrPhone.toLowerCase();
      } else {
        phone = emailOrPhone;
        // For phone registration, create a dummy email
        email = '${phone}@digislips.temp';
      }

      // Role-specific registrations
      switch (selectedRole.value) {
        case 'Teacher':
          await _registerTeacher(email, phone);
          break;
        case 'Parent':
          await _registerParent(email, phone);
          break;
        case 'Student':
          await _registerStudent(email, phone);
          break;
        default:
          throw Exception('Invalid role selected');
      }

    } catch (e) {
      _showErrorSnackbar('Registration Failed', 'An unexpected error occurred: ${e.toString()}');
    } finally {
      isLoading(false);
    }
  }

  // Register Teacher
  Future<void> _registerTeacher(String email, String phone) async {
    // Check if teacher already exists
    if (await _isTeacherExists(email, selectedDepartment.value)) {
      _showErrorSnackbar('Registration Failed', 
          'A teacher with this email already exists in ${selectedDepartment.value} department');
      return;
    }

    // Create user in Firebase Auth
    UserCredential userCredential = await _createUserWithAuth(email, phone);
    if (userCredential.user == null) return;

    // Update display name
    await userCredential.user?.updateDisplayName(fullNameController.text.trim());

    // Create teacher model
    final teacher = {
      'uid': userCredential.user!.uid,
      'fullName': fullNameController.text.trim(),
      'email': email,
      'phone': phone,
      'department': selectedDepartment.value,
      'role': 'teacher',
      'isEmailVerified': false,
      'profileComplete': true,
      'registrationDate': FieldValue.serverTimestamp(),
      'status': 'active',
    };

    // Save to Firestore teachers collection
    await _firestore
        .collection('teachers')
        .doc(teacher['uid'] as String)
        .set(teacher);

    _showSuccessAndNavigate('Teacher registered successfully!');
  }

  // Register Parent
  Future<void> _registerParent(String email, String phone) async {
    String studentRollNumber = studentRollNumberController.text.trim().toUpperCase();

    // Check if student exists
    if (!await _isStudentRollNumberExists(studentRollNumber)) {
      _showErrorSnackbar('Registration Failed', 
          'Student with roll number $studentRollNumber not found');
      return;
    }

    // Get student details
    final studentQuery = await _firestore
        .collection('students')
        .where('rollNumber', isEqualTo: studentRollNumber)
        .get();

    if (studentQuery.docs.isEmpty) {
      _showErrorSnackbar('Registration Failed', 'Student not found');
      return;
    }

    final studentData = studentQuery.docs.first.data();

    // Create user in Firebase Auth
    UserCredential userCredential = await _createUserWithAuth(email, phone);
    if (userCredential.user == null) return;

    // Update display name
    await userCredential.user?.updateDisplayName(fullNameController.text.trim());

    // Create parent model
    final parent = {
      'uid': userCredential.user!.uid,
      'fullName': fullNameController.text.trim(),
      'email': email,
      'phone': phone,
      'role': 'parent',
      'studentInfo': {
        'rollNumber': studentRollNumber,
        'studentName': studentData['fullName'],
        'department': studentData['department'],
        'studentUid': studentData['uid'],
      },
      'isEmailVerified': false,
      'profileComplete': true,
      'registrationDate': FieldValue.serverTimestamp(),
      'status': 'active',
    };

    // Save to Firestore parents collection
    await _firestore
        .collection('parents')
        .doc(parent['uid'] as String)
        .set(parent);

    _showSuccessAndNavigate('Parent registered successfully!');
  }

  // Register Student
  Future<void> _registerStudent(String email, String phone) async {
    String rollNumber = rollNumberController.text.trim().toUpperCase();

    // Check if roll number already exists in the same department
    if (await _isRollNumberExists(rollNumber, selectedDepartment.value)) {
      _showErrorSnackbar('Registration Failed', 
          'A student with roll number $rollNumber already exists in ${selectedDepartment.value} department');
      return;
    }

    // Check if email already exists
    if (await _isEmailExists(email)) {
      _showErrorSnackbar('Registration Failed', 
          'A user with this email already exists');
      return;
    }

    // Create user in Firebase Auth
    UserCredential userCredential = await _createUserWithAuth(email, phone);
    if (userCredential.user == null) return;

    // Update display name
    await userCredential.user?.updateDisplayName(fullNameController.text.trim());

    // Create student model
    final student = {
      'uid': userCredential.user!.uid,
      'fullName': fullNameController.text.trim(),
      'email': email,
      'phone': phone,
      'rollNumber': rollNumber,
      'department': selectedDepartment.value,
      'role': 'student',
      'isEmailVerified': false,
      'profileComplete': true,
      'registrationDate': FieldValue.serverTimestamp(),
      'status': 'active',
      'academicYear': DateTime.now().year.toString(),
    };

    // Save to Firestore students collection
    await _firestore
        .collection('students')
        .doc(student['uid'] as String)
        .set(student);

    _showSuccessAndNavigate('Student registered successfully!');
  }

  // Helper method to create user with Firebase Auth
  Future<UserCredential> _createUserWithAuth(String email, String phone) async {
    UserCredential userCredential;
    
    if (phone.isNotEmpty) {
      // For phone registration, use a temporary email
      userCredential = await _auth.createUserWithEmailAndPassword(
        email: '${phone}@digislips.temp',
        password: 'TempPass123!', // Temporary password for phone users
      );
    } else {
      userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: passwordController.text,
      );
    }

    if (userCredential.user == null) {
      _showErrorSnackbar('Registration Failed', 'Failed to create user');
      throw Exception('Failed to create user');
    }

    return userCredential;
  }

  // Helper method to show success message and navigate
  void _showSuccessAndNavigate(String message) {
    Get.snackbar(
      'Registration Successful!',
      message,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 3),
    );

    _clearForm();

    // Sign out and navigate to splash
    FirebaseAuth.instance.signOut();
    Get.offAll(() => SplashScreen());
  }

  // Helper method to show error snackbar
  void _showErrorSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: AppColors.error,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  // Form validation
  bool _validateForm() {
    // Basic field validations
    final validators = <String, String?>{
      'Role': validateRole(),
      'Full Name': validateFullName(fullNameController.text),
      'Email or Phone': validateEmailOrPhone(emailController.text),
      'Department': validateDepartment(),
      'Student Roll Number': validateStudentRollNumber(studentRollNumberController.text),
      'Roll Number': validateRollNumber(rollNumberController.text),
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

  // Student form validation (for legacy support)
  bool _validateStudentForm() {
    final validators = <String, String?>{
      'Role': validateRole(),
      'Full Name': validateFullName(fullNameController.text),
      'Email': validateEmail(emailController.text),
      'Phone': validatePhone(phoneController.text),
      'Roll Number': validateRollNumber(rollNumberController.text),
      'Department': validateDepartment(),
      'Password': validatePassword(passwordController.text),
      'Confirm Password': validateConfirmPassword(confirmPasswordController.text),
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

  // Clear form
  void _clearForm() {
    fullNameController.clear();
    emailController.clear();
    phoneController.clear();
    rollNumberController.clear();
    studentRollNumberController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    selectedRole.value = '';
    selectedDepartment.value = '';
  }

  // Legacy student registration method (for backward compatibility)
  Future<void> registerStudent() async {
    if (!_validateStudentForm()) return;

    isLoading(true);

    try {
      String email = emailController.text.trim().toLowerCase();
      String phone = phoneController.text.trim();
      String rollNumber = rollNumberController.text.trim().toUpperCase();

      // Check if roll number already exists in the same department
      if (await _isRollNumberExists(rollNumber, selectedDepartment.value)) {
        _showErrorSnackbar('Registration Failed', 
            'A student with roll number $rollNumber already exists in ${selectedDepartment.value} department');
        return;
      }

      // Check if email already exists
      if (await _isEmailExists(email)) {
        _showErrorSnackbar('Registration Failed', 
            'A user with this email already exists');
        return;
      }

      // Create user in Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: passwordController.text,
      );

      if (userCredential.user == null) {
        _showErrorSnackbar('Registration Failed', 'Failed to create user');
        return;
      }

      // Update display name
      await userCredential.user?.updateDisplayName(fullNameController.text.trim());

      // Create student model
      final student = {
        'uid': userCredential.user!.uid,
        'fullName': fullNameController.text.trim(),
        'email': email,
        'phone': phone,
        'rollNumber': rollNumber,
        'department': selectedDepartment.value,
        'role': 'student',
        'isEmailVerified': false,
        'profileComplete': true,
        'registrationDate': FieldValue.serverTimestamp(),
        'status': 'active',
        'academicYear': DateTime.now().year.toString(),
      };

      // Save to Firestore students collection
      await _firestore
          .collection('students')
          .doc(student['uid'] as String)
          .set(student);

      _showSuccessAndNavigate('Student registered successfully!');

    } catch (e) {
      _showErrorSnackbar('Registration Failed', 'An unexpected error occurred: ${e.toString()}');
    } finally {
      isLoading(false);
    }
  }

  // Utility method to format roll number
  String formatRollNumber(String rollNumber) {
    return rollNumber.trim().toUpperCase();
  }

  // Utility method to format email
  String formatEmail(String email) {
    return email.trim().toLowerCase();
  }

  // Method to check internet connectivity (optional)
  Future<bool> _hasInternetConnection() async {
    try {
      // Simple check - you might want to use connectivity_plus package for better checking
      return true;
    } catch (e) {
      return false;
    }
  }
}