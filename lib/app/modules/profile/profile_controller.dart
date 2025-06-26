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

  // User data observables
  var currentUser =
      Rxn<Map<String, dynamic>>(); // Changed to Map for better handling
  var userRole = ''.obs;
  var userUid = ''.obs;
  var userEmail = ''.obs;
  var isParent = false.obs;
  var isTeacher = false.obs;

  // Loading states
  var isLoading = false.obs;
  var isEditingProfile = false.obs;
  var isUploadingImage = false.obs;
  var hasError = false.obs;
  var errorMessage = ''.obs;

  // Edit form controllers
  final fullNameController = TextEditingController();
  final phoneController = TextEditingController();
  final departmentController = TextEditingController();
  final subjectController = TextEditingController();
 
  final childClassController = TextEditingController();
  final employeeIdController = TextEditingController();

  // Available departments and subjects (for teachers)
  final List<String> availableDepartments = [
    'Computer Science',
    'Information Technology',
    'Electronics',
    'Mechanical',
    'Civil',
    'Electrical',
    'Chemical',
    'Mathematics',
    'Physics',
    'Chemistry',
    'English',
    'Others',
  ];

  final List<String> availableSubjects = [
    'Programming',
    'Data Structures',
    'Database Management',
    'Web Development',
    'Mobile Development',
    'Mathematics',
    'Physics',
    'Chemistry',
    'English',
    'Others',
  ];

  // Getters for easy access to user data
  String get fullName => _getFullName();
  String get role => userRole.value.capitalize ?? 'User';
  String get department => _getDepartment();
  String get phone => _getPhone();
  String get email =>
      userEmail.value.isNotEmpty ? userEmail.value : 'Loading...';
  String? get profileImageUrl => _getProfileImageUrl();

  // Role-specific getters
  String get subject => _getSubject(); // For teachers
  String get employeeId => _getEmployeeId(); // For teachers
  String get childName => _getChildName(); // For parents
  String get childClass => _getChildClass(); // For parents

  @override
  void onInit() {
    super.onInit();
    getUserDetailsFromPrefs();
  }

  @override
  void onClose() {
    fullNameController.dispose();
    phoneController.dispose();
    departmentController.dispose();
    subjectController.dispose();
 
    childClassController.dispose();
    employeeIdController.dispose();
    super.onClose();
  }

  // Get user details from shared preferences
  Future<void> getUserDetailsFromPrefs() async {
    try {
      isLoading.value = true;
      final prefs = await SharedPreferences.getInstance();

      // Get stored values
      String? uid = prefs.getString('uid');
      String? role = prefs.getString('userRole');
      bool? parentFlag = prefs.getBool('isParent');
      bool? teacherFlag = prefs.getBool('isTeacher');
      String? emailPref = prefs.getString('Email');

      print("Email is 😁😁👌 $emailPref");
      print('UID😁😁😁👍: $uid');
      print('Role😊👌👌: $role');
      print('Is Parent😁: $parentFlag');
      print('Is Teacher😁: $teacherFlag');

      if (uid == null || uid.isEmpty) {
        throw Exception('No user ID found. Please login again.');
      }

      // Set observable values
      userUid.value = uid;
      userRole.value = role ?? '';
      userEmail.value = emailPref ?? '';
      isParent.value = parentFlag ?? false;
      isTeacher.value = teacherFlag ?? false;

      // Use the appropriate fetch method based on role
      if (isTeacher.value) {
        await fetchCurrentTeacherData();
      } else {
        await fetchCurrentUserData(); // This will handle parents and other roles
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString();
      print('Error getting user details from prefs: $e');
      _showErrorSnackbar('Error', 'Failed to load user data: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  // Fetch user data from Firestore based on role
  Future<void> fetchUserData() async {
    try {
      isLoading.value = true;
      hasError.value = false;

      if (userUid.value.isEmpty) {
        throw Exception('User not found. Please login again.');
      }

      print('Fetching data for UID: ${userUid.value}');
      print('User role: ${userRole.value}');
      print('Is Parent: ${isParent.value}');
      print('Is Teacher: ${isTeacher.value}');

      DocumentSnapshot? userDoc;

      // Try fetching from the appropriate collection based on role
      if (isTeacher.value) {
        print('Trying to fetch from teachers collection...');
        userDoc = await _firestore
            .collection('teachers')
            .doc(userUid.value)
            .get();

        print('Teachers collection - Document exists: ${userDoc.exists}');

        if (!userDoc.exists) {
          print('Not found in teachers, trying students collection...');
          userDoc = await _firestore
              .collection('students')
              .doc(userUid.value)
              .get();
          print('Students collection - Document exists: ${userDoc.exists}');
        }
      } else if (isParent.value) {
        print('Trying to fetch from parents collection...');
        userDoc = await _firestore
            .collection('parents')
            .doc(userUid.value)
            .get();

        print('Parents collection - Document exists: ${userDoc.exists}');

        if (!userDoc.exists) {
          print('Not found in parents, trying students collection...');
          userDoc = await _firestore
              .collection('students')
              .doc(userUid.value)
              .get();
          print('Students collection - Document exists: ${userDoc.exists}');
        }
      } else {
        // If role is unclear, try all collections
        print('Role unclear, trying all collections...');

        // Try teachers first
        userDoc = await _firestore
            .collection('teachers')
            .doc(userUid.value)
            .get();

        if (!userDoc.exists) {
          // Try students
          userDoc = await _firestore
              .collection('students')
              .doc(userUid.value)
              .get();
        }

        if (!userDoc.exists) {
          // Try parents
          userDoc = await _firestore
              .collection('parents')
              .doc(userUid.value)
              .get();
        }
      }

      if (userDoc != null && userDoc.exists && userDoc.data() != null) {
        // Store user data as Map
        Map<String, dynamic> userData = Map<String, dynamic>.from(
          userDoc.data() as Map<String, dynamic>,
        );

        print('Raw user data: $userData');

        // Add role information to user data
        userData['role'] = userRole.value;
        userData['uid'] = userUid.value;
        userData['email'] = userEmail.value;

        // Get profile image URL from Realtime Database
        try {
          final DatabaseReference dbRef = FirebaseDatabase.instance.ref().child(
            'profile_images/${userUid.value}',
          );
          final DataSnapshot snapshot = await dbRef.get();

          if (snapshot.exists && snapshot.value != null) {
            userData['profileImageUrl'] = snapshot.value.toString();
            print('Profile image URL found: ${userData['profileImageUrl']}');
          } else {
            print('No profile image found in Realtime Database');
          }
        } catch (e) {
          print('Error fetching profile image: $e');
          // Continue without profile image
        }

        currentUser.value = userData;
        print('✅ Current user loaded successfully: ${userData['fullName']}');

        _populateEditControllers();
      } else {
        throw Exception('User profile not found in any collection');
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString();
      print('❌ Error fetching user data: $e');
      _showErrorSnackbar(
        'Error',
        'Failed to load profile data: ${e.toString()}',
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Specific method to fetch teacher data (similar to your existing method)
  Future<void> fetchCurrentTeacherData() async {
    try {
      isLoading.value = true;

      if (userUid.value.isEmpty) {
        _showErrorSnackbar('Error', 'User not found. Please login again.');
        return;
      }

      // Fetch current teacher data from Firestore using UID
      final docSnapshot = await _firestore
          .collection('teachers')
          .doc(userUid.value)
          .get();

      if (docSnapshot.exists) {
        Map<String, dynamic> userData = Map<String, dynamic>.from(
          docSnapshot.data()!,
        );

        // Add additional info
        userData['role'] = 'teacher';
        userData['uid'] = userUid.value;
        userData['email'] = userEmail.value;

        currentUser.value = userData;
        print('✅ Current teacher loaded: ${userData['fullName']}');

        _populateEditControllers();
      } else {
        // If not found in teachers, try students collection
        final studentSnapshot = await _firestore
            .collection('students')
            .doc(userUid.value)
            .get();

        if (studentSnapshot.exists) {
          Map<String, dynamic> userData = Map<String, dynamic>.from(
            studentSnapshot.data()!,
          );

          userData['role'] = 'student';
          userData['uid'] = userUid.value;
          userData['email'] = userEmail.value;

          currentUser.value = userData;
          print('✅ Current user loaded from students: ${userData['fullName']}');

          _populateEditControllers();
        } else {
          _showErrorSnackbar('Error', 'User profile not found.');
        }
      }
    } catch (e) {
      _showErrorSnackbar('Error', 'Failed to load profile: $e');
      print('❌ Error fetching teacher data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Generic method to fetch current user data
  Future<void> fetchCurrentUserData() async {
    try {
      isLoading.value = true;

      if (userUid.value.isEmpty) {
        _showErrorSnackbar('Error', 'User not found. Please login again.');
        return;
      }

      // Try multiple collections to find user
      DocumentSnapshot? userDoc;

      // Try teachers first
      userDoc = await _firestore
          .collection('teachers')
          .doc(userUid.value)
          .get();

      if (!userDoc.exists) {
        // Try students
        userDoc = await _firestore
            .collection('students')
            .doc(userUid.value)
            .get();
      }

      if (!userDoc.exists) {
        // Try parents
        userDoc = await _firestore
            .collection('parents')
            .doc(userUid.value)
            .get();
      }

      if (userDoc.exists) {
        Map<String, dynamic> userData = Map<String, dynamic>.from(
          userDoc.data() as Map<String, dynamic>,
        );

        userData['uid'] = userUid.value;
        userData['email'] = userEmail.value;

        currentUser.value = userData;
        print('✅ Current user loaded: ${userData['fullName']}');

        _populateEditControllers();
      } else {
        _showErrorSnackbar('Error', 'User profile not found.');
      }
    } catch (e) {
      _showErrorSnackbar('Error', 'Failed to load profile: $e');
      print('❌ Error fetching user data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Populate edit form controllers with current data
  void _populateEditControllers() {
    if (currentUser.value != null) {
      Map<String, dynamic> userData = currentUser.value!;

      fullNameController.text = userData['fullName']?.toString() ?? '';
      phoneController.text = userData['phone']?.toString() ?? '';

      if (isTeacher.value) {
        departmentController.text = userData['department']?.toString() ?? '';
        subjectController.text = userData['subject']?.toString() ?? '';
        employeeIdController.text = userData['employeeId']?.toString() ?? '';
      } else if (isParent.value) {
       
        childClassController.text = userData['childClass']?.toString() ?? '';
      }

      print('Controllers populated successfully');
    }
  }

  // Start editing profile
  void startEditingProfile() {
    if (currentUser.value == null) {
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

  // Check if current user can edit child data
  bool canEditChildData() {
    return isParent.value;
  }

  // Validate email format
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Validate phone number format
  bool _isValidPhone(String phone) {
    return RegExp(r'^\+?[\d\s\-\(\)]{10,}$').hasMatch(phone);
  }

  // Save profile changes
  Future<void> saveProfileChanges() async {
    if (currentUser.value == null) return;

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
        _showErrorSnackbar(
          'Validation Error',
          'Please enter a valid phone number',
        );
        return;
      }

      // Role-specific validation
      if (isTeacher.value) {
        if (departmentController.text.trim().isEmpty) {
          _showErrorSnackbar('Validation Error', 'Department is required');
          return;
        }
        if (subjectController.text.trim().isEmpty) {
          _showErrorSnackbar('Validation Error', 'Subject is required');
          return;
        }
      } 

      await updateUserData();
      isEditingProfile.value = false;

      _showSuccessSnackbar('Success', 'Profile updated successfully!');
    } catch (e) {
      print('Error saving profile changes: $e');
      _showErrorSnackbar('Error', 'Failed to save changes: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  // Update user data in Firestore
  Future<void> updateUserData() async {
    try {
      Map<String, dynamic> userData = Map<String, dynamic>.from(
        currentUser.value!,
      );

      // Update common fields
      userData['fullName'] = fullNameController.text.trim();
      userData['phone'] = phoneController.text.trim();
      userData['updatedAt'] = FieldValue.serverTimestamp();

      // Update role-specific fields
      if (isTeacher.value) {
        userData['department'] = departmentController.text.trim();
        userData['subject'] = subjectController.text.trim();
        userData['employeeId'] = employeeIdController.text.trim();
      } else if (isParent.value) {
       
        userData['childClass'] = childClassController.text.trim();
      }

      String collection = isParent.value ? 'parents' : 'teachers';

      print('Updating user data in collection: $collection');
      print('Updated data: $userData');

      await _firestore
          .collection(collection)
          .doc(userUid.value)
          .update(userData);

      currentUser.value = userData;
      print('User data updated successfully');
    } catch (e) {
      print('Error updating user data: $e');
      _showErrorSnackbar('Error', 'Failed to update profile: ${e.toString()}');
      rethrow;
    }
  }

  // Refresh profile data
  Future<void> refreshProfile() async {
    if (isTeacher.value) {
      await fetchCurrentTeacherData();
    } else {
      await fetchCurrentUserData();
    }
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
                  await prefs.clear(); // Clear all preferences
                  currentUser.value = null;
                  userRole.value = '';
                  userUid.value = '';
                  userEmail.value = '';
                  isParent.value = false;
                  isTeacher.value = false;

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

  // Private helper methods for getters
  String _getFullName() {
    if (currentUser.value == null) return 'Loading...';
    return currentUser.value!['fullName']?.toString() ?? 'No Name';
  }

  String _getDepartment() {
    if (currentUser.value == null || !isTeacher.value) return 'N/A';
    return currentUser.value!['department']?.toString() ?? 'No Department';
  }

  String _getPhone() {
    if (currentUser.value == null) return 'Loading...';
    return currentUser.value!['phone']?.toString() ?? 'No Phone';
  }

  String? _getProfileImageUrl() {
    if (currentUser.value == null) return null;
    return currentUser.value!['profileImageUrl']?.toString();
  }

  String _getSubject() {
    if (currentUser.value == null || !isTeacher.value) return 'N/A';
    return currentUser.value!['subject']?.toString() ?? 'No Subject';
  }

  String _getEmployeeId() {
    if (currentUser.value == null || !isTeacher.value) return 'N/A';
    return currentUser.value!['employeeId']?.toString() ?? 'No Employee ID';
  }

  String _getChildName() {
    if (currentUser.value == null || !isParent.value) return 'N/A';
    return currentUser.value!['childName']?.toString() ?? 'No Child Name';
  }

  String _getChildClass() {
    if (currentUser.value == null || !isParent.value) return 'N/A';
    return currentUser.value!['childClass']?.toString() ?? 'No Class';
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
