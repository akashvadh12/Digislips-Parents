import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digislips/app/modules/auth/models/user_model.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:digislips/app/core/theme/app_colors.dart';
import 'package:digislips/app/core/theme/app_text_styles.dart';
import 'package:digislips/app/modules/splash_screen/splash_screen.dart';
import 'package:digislips/app/routes/app_rout.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class ProfileController extends GetxController {
  // Firestore and Storage instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
 
  // Observable student data
  var student = Rxn<Student>();

  // Loading states
  var isLoading = false.obs;
  var isEditingProfile = false.obs;
  var isUploadingImage = false.obs;
  var hasError = false.obs;
  var errorMessage = ''.obs;

  // Edit form controllers
  final fullNameController = TextEditingController();
  final phoneController = TextEditingController();
  final parentPhoneController = TextEditingController();
  final parentEmailController = TextEditingController();
  final departmentController = TextEditingController();
  var selectedSemester = '1st Semester'.obs;

  // Available semesters
  final List<String> availableSemesters = [
    '1st Semester',
    '2nd Semester',
    '3rd Semester',
    '4th Semester',
    '5th Semester',
    '6th Semester',
    '7th Semester',
    '8th Semester',
  ];

  // Available departments (you can customize this)
  final List<String> availableDepartments = [
    'Computer Science',
    'Information Technology',
    'Electronics',
    'Mechanical',
    'Civil',
    'Electrical',
    'Chemical',
    'Others',
  ];

  // Getters for easy access to student data
  String get fullName => student.value?.fullName ?? 'Loading...';
  String get role => 'Student';
  String get department => student.value?.department ?? 'Loading...';
  String get studentId => student.value?.rollNumber ?? 'Loading...';
  String get email => student.value?.email ?? 'Loading...';
  String get phone => student.value?.phone ?? 'Loading...';
  String get parentPhone => student.value?.parentPhone ?? 'Not provided';
  String get parentEmail => student.value?.parentEmail ?? 'Not provided';
  String get semester => student.value?.semester ?? '1st Semester';
  String? get profileImageUrl => student.value?.profileImageUrl;

  @override
  void onInit() {
    super.onInit();
    fetchStudentData();
  }

  @override
  void onClose() {
    fullNameController.dispose();
    phoneController.dispose();
    parentPhoneController.dispose();
    parentEmailController.dispose();
    departmentController.dispose();
    super.onClose();
  }

  // Fetch student data from Firestore
  Future<void> fetchStudentData() async {
    try {
      isLoading.value = true;
      hasError.value = false;

      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString('uid');

      if (uid == null || uid.isEmpty) {
        throw Exception('No user ID found. Please login again.');
      }

      // Get profile data from Firestore
      final doc = await _firestore.collection('students').doc(uid).get();

      if (doc.exists && doc.data() != null) {
        Student firestoreStudent = Student.fromMap(doc.data()!);

        // Get profile image URL from Realtime Database
        final DatabaseReference dbRef = FirebaseDatabase.instance.ref().child(
          'profile_images/$uid',
        );
        final DataSnapshot snapshot = await dbRef.get();

        String? imageUrl;
        if (snapshot.exists && snapshot.value != null) {
          imageUrl = snapshot.value.toString();
        }

        // Update student model with image URL from Realtime DB
        student.value = firestoreStudent.copyWith(profileImageUrl: imageUrl);

        _populateEditControllers();
      } else {
        throw Exception('Student data not found');
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString();
      print('Error fetching student data: $e');
      _showErrorSnackbar(
        'Error',
        'Failed to load profile data: ${e.toString()}',
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Populate edit form controllers with current data
  void _populateEditControllers() {
    if (student.value != null) {
      fullNameController.text = student.value!.fullName;
      phoneController.text = student.value!.phone;
      parentPhoneController.text = student.value!.parentPhone ?? '';
      parentEmailController.text = student.value!.parentEmail ?? '';
      departmentController.text = student.value!.department;
      selectedSemester.value = student.value!.semester;
    }
  }

  // Start editing profile
  void startEditingProfile() {
    if (student.value == null) {
      _showErrorSnackbar('Error', 'Profile data not loaded yet');
      return;
    }

    _populateEditControllers();
    isEditingProfile.value = true;
  }

  // Cancel editing
  void cancelEditing() {
    isEditingProfile.value = false;
    _populateEditControllers(); // Reset to original values
  }

  // Validate email format
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Validate phone number format (basic validation)
  bool _isValidPhone(String phone) {
    return RegExp(r'^\+?[\d\s\-\(\)]{10,}$').hasMatch(phone);
  }

  // Save profile changes
  Future<void> saveProfileChanges() async {
    if (student.value == null) return;

    try {
      isLoading.value = true;

      // Validate required fields
      if (fullNameController.text.trim().isEmpty) {
        _showErrorSnackbar('Validation Error', 'Full name is required');
        return;
      }

      if (phoneController.text.trim().isEmpty) {
        _showErrorSnackbar('Validation Error', 'Phone number is required');
        return;
      }

      // Validate phone number format
      if (!_isValidPhone(phoneController.text.trim())) {
        _showErrorSnackbar('Validation Error', 'Please enter a valid phone number');
        return;
      }

      // Validate parent phone if provided
      if (parentPhoneController.text.trim().isNotEmpty && 
          !_isValidPhone(parentPhoneController.text.trim())) {
        _showErrorSnackbar('Validation Error', 'Please enter a valid parent phone number');
        return;
      }

      // Validate parent email if provided
      if (parentEmailController.text.trim().isNotEmpty && 
          !_isValidEmail(parentEmailController.text.trim())) {
        _showErrorSnackbar('Validation Error', 'Please enter a valid parent email address');
        return;
      }

      // Create updated student object
      final updatedStudent = student.value!.copyWith(
        fullName: fullNameController.text.trim(),
        phone: phoneController.text.trim(),
        parentPhone: parentPhoneController.text.trim().isEmpty 
            ? null 
            : parentPhoneController.text.trim(),
        parentEmail: parentEmailController.text.trim().isEmpty 
            ? null 
            : parentEmailController.text.trim(),
        department: departmentController.text.trim().isEmpty
            ? selectedSemester.value
            : departmentController.text.trim(),
        semester: selectedSemester.value,
      );

      await updateStudentData(updatedStudent);
      isEditingProfile.value = false;
      
      _showSuccessSnackbar('Success', 'Profile updated successfully!');
    } catch (e) {
      print('Error saving profile changes: $e');
      _showErrorSnackbar('Error', 'Failed to save changes: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  // Update student data in Firestore
  Future<void> updateStudentData(Student updatedStudent) async {
    try {
      final dataToUpdate = updatedStudent.toMap();
      dataToUpdate['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection('students')
          .doc(updatedStudent.uid)
          .update(dataToUpdate);

      student.value = updatedStudent;
    } catch (e) {
      print('Error updating student data: $e');
      _showErrorSnackbar('Error', 'Failed to update profile: ${e.toString()}');
      rethrow;
    }
  }

  // Update only parent information
  Future<void> updateParentInfo({
    required String parentPhone,
    required String parentEmail,
  }) async {
    if (student.value == null) return;

    try {
      isLoading.value = true;

      // Validate parent phone if provided
      if (parentPhone.trim().isNotEmpty && !_isValidPhone(parentPhone.trim())) {
        _showErrorSnackbar('Validation Error', 'Please enter a valid parent phone number');
        return;
      }

      // Validate parent email if provided
      if (parentEmail.trim().isNotEmpty && !_isValidEmail(parentEmail.trim())) {
        _showErrorSnackbar('Validation Error', 'Please enter a valid parent email address');
        return;
      }

      final updatedStudent = student.value!.copyWith(
        parentPhone: parentPhone.trim().isEmpty ? null : parentPhone.trim(),
        parentEmail: parentEmail.trim().isEmpty ? null : parentEmail.trim(),
      );

      await updateStudentData(updatedStudent);
      _showSuccessSnackbar('Success', 'Parent information updated successfully!');
    } catch (e) {
      print('Error updating parent info: $e');
      _showErrorSnackbar('Error', 'Failed to update parent information: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  // Refresh profile from Realtime Database
  Future<void> refreshProfile() async {
    await fetchStudentData(); // Make sure fetchStudentData() pulls from Realtime DB
  }

  void changePassword() {
    Get.snackbar(
      'Change Password',
      'Navigating to change password...',
      backgroundColor: AppColors.secondary.withOpacity(0.1),
      colorText: AppColors.secondary,
      snackPosition: SnackPosition.TOP,
      margin: EdgeInsets.all(16),
      borderRadius: 12,
      duration: Duration(seconds: 2),
    );
  }

  void logout() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: EdgeInsets.all(24),
        contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        actionsPadding: EdgeInsets.all(16),
        title: Row(
          children: [
            Icon(Icons.logout, color: AppColors.error, size: 24),
            SizedBox(width: 12),
            Text('Logout', style: AppTextStyles.title),
          ],
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel', style: AppTextStyles.linkText),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.error, AppColors.error.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              onPressed: () async {
                Get.back();

                try {
                  await FirebaseAuth.instance.signOut();
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('uid');
                  student.value = null;

                  Get.snackbar(
                    'Logged Out',
                    'You have been successfully logged out',
                    backgroundColor: AppColors.error.withOpacity(0.1),
                    colorText: AppColors.error,
                    snackPosition: SnackPosition.TOP,
                    margin: EdgeInsets.all(16),
                    borderRadius: 12,
                  );

                  await Future.delayed(Duration(milliseconds: 500));
                  Get.offAll(
                    () => SplashScreen(),
                    transition: Transition.fadeIn,
                  );
                } catch (e) {
                  print('Error during logout: $e');
                  _showErrorSnackbar('Error', 'Failed to logout properly');
                }
              },
              child: Text(
                'Logout',
                style: AppTextStyles.buttonText.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for showing snackbars
  void _showSuccessSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: AppColors.success.withOpacity(0.1),
      colorText: AppColors.success,
      snackPosition: SnackPosition.TOP,
      margin: EdgeInsets.all(16),
      borderRadius: 12,
      duration: Duration(seconds: 3),
      icon: Icon(Icons.check_circle, color: AppColors.success),
    );
  }

  void _showErrorSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: AppColors.error.withOpacity(0.1),
      colorText: AppColors.error,
      snackPosition: SnackPosition.TOP,
      margin: EdgeInsets.all(16),
      borderRadius: 12,
      duration: Duration(seconds: 4),
      icon: Icon(Icons.error, color: AppColors.error),
    );
  }
}