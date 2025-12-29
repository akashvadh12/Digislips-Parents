import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digislips/app/core/theme/app_colors.dart';
import 'package:digislips/app/core/theme/app_text_styles.dart';
import 'package:digislips/app/modules/auth/models/user_model.dart';
import 'package:digislips/app/modules/dashboard/dashboard_controller.dart';
import 'package:digislips/app/modules/splash_screen/splash_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends GetxController {
  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
  var hasError = false.obs;
  var errorMessage = ''.obs;

  // Settings observables
  var notificationsEnabled = true.obs;
  var darkModeEnabled = false.obs;
  var biometricEnabled = false.obs;

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

  // Legacy getters for backward compatibility (if needed)
  String get studentId => _getStudentId();
  String get parentPhone => _getParentPhone();
  String get parentEmail => _getParentEmail();
  String get semester => _getSemester();

  @override
  void onInit() {
    super.onInit();
    getUserDetailsFromPrefs();
    _loadSettings();
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

  // Specific method to fetch teacher data
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

        // Get profile image URL from Realtime Database
        // Temporarily bypassed - no profile images database currently
        /* 
        try {
          final DatabaseReference dbRef = FirebaseDatabase.instance.ref().child(
            'profile_images/${userUid.value}',
          );
          final DataSnapshot snapshot = await dbRef.get();

          if (snapshot.exists && snapshot.value != null) {
            userData['profileImageUrl'] = snapshot.value.toString();
            print('Profile image URL found: ${userData['profileImageUrl']}');
          }
        } catch (e) {
          print('Error fetching profile image: $e');
        }
        */

        currentUser.value = userData;
        print('✅ Current teacher loaded: ${userData['fullName']}');
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

        // Get profile image URL from Realtime Database
        // Temporarily bypassed - no profile images database currently
        /* 
        try {
          final DatabaseReference dbRef = FirebaseDatabase.instance.ref().child(
            'profile_images/${userUid.value}',
          );
          final DataSnapshot snapshot = await dbRef.get();

          if (snapshot.exists && snapshot.value != null) {
            userData['profileImageUrl'] = snapshot.value.toString();
            print('Profile image URL found: ${userData['profileImageUrl']}');
          }
        } catch (e) {
          print('Error fetching profile image: $e');
        }
        */

        currentUser.value = userData;
        print('✅ Current user loaded: ${userData['fullName']}');
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

  // Load saved settings from SharedPreferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      notificationsEnabled.value =
          prefs.getBool('notifications_enabled') ?? true;
      darkModeEnabled.value = prefs.getBool('dark_mode_enabled') ?? false;
      biometricEnabled.value = prefs.getBool('biometric_enabled') ?? false;
    } catch (e) {
      print('Error loading settings: $e');
    }
  }

  // Save settings to SharedPreferences
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', notificationsEnabled.value);
      await prefs.setBool('dark_mode_enabled', darkModeEnabled.value);
      await prefs.setBool('biometric_enabled', biometricEnabled.value);
    } catch (e) {
      print('Error saving settings: $e');
    }
  }

  // Toggle notifications
  void toggleNotifications(bool value) {
    notificationsEnabled.value = value;
    _saveSettings();
    _showSuccessSnackbar(
      'Settings Updated',
      'Notification preferences saved successfully',
    );
  }

  // Toggle dark mode
  void toggleDarkMode(bool value) {
    darkModeEnabled.value = value;
    _saveSettings();
    _showSuccessSnackbar(
      'Theme Updated',
      'Dark mode ${value ? 'enabled' : 'disabled'} successfully',
    );
  }

  // Toggle biometric authentication
  void toggleBiometric(bool value) {
    biometricEnabled.value = value;
    _saveSettings();
    _showSuccessSnackbar(
      'Security Updated',
      'Biometric authentication ${value ? 'enabled' : 'disabled'}',
    );
  }

  // Navigate to profile page for editing
  void navigateToProfile() {
    Get.toNamed('/profile');
  }

  // Change password functionality
  void changePassword() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lock_outline, color: AppColors.primary, size: 24),
                  SizedBox(width: 12),
                  Text('Change Password', style: AppTextStyles.title),
                ],
              ),
              SizedBox(height: 20),

              Text(
                'You will be redirected to reset your password via email.',
                style: AppTextStyles.body,
              ),

              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: AppColors.greyColor),
                    ),
                  ),
                  SizedBox(width: 5),
                  ElevatedButton(
                    onPressed: _sendPasswordResetEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Reset Email',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Send password reset email
  Future<void> _sendPasswordResetEmail() async {
    try {
      Get.back(); // Close dialog
      isLoading.value = true;

      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      _showSuccessSnackbar('Email Sent', 'Password reset email sent to $email');
    } catch (e) {
      _showErrorSnackbar(
        'Error',
        'Failed to send reset email: ${e.toString()}',
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Show privacy policy
  void showPrivacyPolicy() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: EdgeInsets.all(24),
          height: Get.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.privacy_tip_outlined,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Text('Privacy Policy', style: AppTextStyles.title),
                ],
              ),
              SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    '''DigiSlips Privacy Policy

Last updated: ${DateTime.now().year}

1. Information We Collect
We collect information you provide directly to us, such as when you create an account, update your profile, or contact us for support.

2. How We Use Your Information
• To provide and maintain our services
• To notify you about changes to our services
• To provide customer support
• To gather analysis or valuable information

3. Information Sharing
We do not sell, trade, or otherwise transfer your personal information to third parties without your consent, except as described in this policy.

4. Data Security
We implement appropriate security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction.

5. Your Rights
• Access your personal data
• Correct inaccurate data
• Request deletion of your data
• Object to processing of your data

6. Contact Us
If you have any questions about this Privacy Policy, please contact us at:
Email: privacy@digislips.com
Phone: +1 (555) 123-4567

This policy is effective as of the last updated date and will remain in effect except with respect to any changes in its provisions in the future.''',
                    style: AppTextStyles.body,
                  ),
                ),
              ),
              SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('Close', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Show help and support
  void showHelpSupport() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.help_outline, color: AppColors.primary, size: 24),
                  SizedBox(width: 12),
                  Text('Help & Support', style: AppTextStyles.title),
                ],
              ),
              SizedBox(height: 20),

              _buildSupportOption(
                Icons.email_outlined,
                'Email Support',
                'support@digislips.com',
                () => _contactSupport('Email support will be available soon!'),
              ),
              SizedBox(height: 16),
              _buildSupportOption(
                Icons.phone_outlined,
                'Phone Support',
                '+1 (555) 123-4567',
                () => _contactSupport('Phone support will be available soon!'),
              ),
              SizedBox(height: 16),
              _buildSupportOption(
                Icons.chat_outlined,
                'Live Chat',
                'Available 9 AM - 6 PM',
                () => _contactSupport('Live chat will be available soon!'),
              ),
              SizedBox(height: 16),
              _buildSupportOption(
                Icons.help_outline,
                'FAQ',
                'Frequently Asked Questions',
                () => _contactSupport('FAQ page will be available soon!'),
              ),

              SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('Close', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSupportOption(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.lightGrey ?? Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.bodyMedium),
                  Text(subtitle, style: AppTextStyles.caption),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: AppColors.greyColor, size: 16),
          ],
        ),
      ),
    );
  }

  // Handle support contact methods (simplified without external packages)
  void _contactSupport(String message) {
    Get.back();
    _showInfoSnackbar('Support', message);
  }

  // Logout functionality
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
          'Are you sure you want to logout? You will need to sign in again to access your account.',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel', style: TextStyle(color: AppColors.greyColor)),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.error, AppColors.error.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              onPressed: _performLogout,
              child: Text(
                'Logout',
                style:
                    AppTextStyles.buttonText?.copyWith(color: Colors.white) ??
                    TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Perform logout operation
  Future<void> _performLogout() async {
    try {
      Get.back(); // Close any open dialog
      isLoading.value = true;

      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();
      await FirebaseAuth.instance.signOut();
      final HomeController homeController = Get.put(HomeController());
      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      homeController.resetUserData();
      await Get.delete<HomeController>(force: true);
      // Clear all stored SharedPreferences

      // (Optional) Recreate default values only if your app relies on them immediately
      await prefs.setBool('isLoggedIn', false);

      // Clear in-memory data (GetX observables)
      currentUser.value = null;
      userRole.value = '';
      userUid.value = '';
      userEmail.value = '';
      isParent.value = false;
      isTeacher.value = false;

      // Show success snackbar
      _showSuccessSnackbar(
        'Logged Out',
        'You have been successfully logged out',
      );

      // Navigate to splash/login screen
      await Future.delayed(Duration(milliseconds: 500));
      Get.offAll(() => SplashScreen(), transition: Transition.fadeIn);
    } catch (e) {
      print('Error during logout: $e');
      _showErrorSnackbar('Error', 'Failed to logout properly');
    } finally {
      isLoading.value = false;
    }
  }

  // Private helper methods for getters
  String _getFullName() {
    if (currentUser.value == null) return 'Loading...';
    return currentUser.value!['fullName']?.toString() ?? 'No Name';
  }

  String _getDepartment() {
    if (currentUser.value == null) return 'Loading...';

    if (isTeacher.value) {
      return currentUser.value!['department']?.toString() ?? 'No Department';
    } else if (isParent.value) {
      // For parents, show child's department/class info
      return currentUser.value!['childClass']?.toString() ?? 'No Class Info';
    } else {
      // For students
      return currentUser.value!['department']?.toString() ?? 'No Department';
    }
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

  // Legacy getters for backward compatibility
  String _getStudentId() {
    if (currentUser.value == null) return 'Loading...';
    return currentUser.value!['rollNumber']?.toString() ??
        currentUser.value!['studentId']?.toString() ??
        'No Student ID';
  }

  String _getParentPhone() {
    if (currentUser.value == null) return 'Not provided';
    return currentUser.value!['parentPhone']?.toString() ?? 'Not provided';
  }

  String _getParentEmail() {
    if (currentUser.value == null) return 'Not provided';
    return currentUser.value!['parentEmail']?.toString() ?? 'Not provided';
  }

  String _getSemester() {
    if (currentUser.value == null) return '1st Semester';
    return currentUser.value!['semester']?.toString() ?? '1st Semester';
  }

  // Helper methods for snackbars
  void _showSuccessSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: AppColors.success ?? Colors.green,
      colorText: AppColors.background ?? Colors.white,
      snackPosition: SnackPosition.TOP,
      margin: EdgeInsets.all(16),
      borderRadius: 12,
      duration: Duration(seconds: 3),
      icon: Icon(Icons.check_circle, color: AppColors.success ?? Colors.green),
    );
  }

  void _showErrorSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: AppColors.error,
      colorText: AppColors.background,
      snackPosition: SnackPosition.TOP,
      margin: EdgeInsets.all(16),
      borderRadius: 12,
      duration: Duration(seconds: 4),
      icon: Icon(Icons.error, color: AppColors.error),
    );
  }

  void _showInfoSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: AppColors.error,
      colorText: AppColors.background,
      snackPosition: SnackPosition.TOP,
      margin: EdgeInsets.all(16),
      borderRadius: 12,
      duration: Duration(seconds: 3),
      icon: Icon(Icons.info, color: AppColors.primary),
    );
  }
}
