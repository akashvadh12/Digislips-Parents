// app/modules/home/controllers/home_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digislips/app/modules/auth/models/user_model.dart';
import 'package:digislips/app/modules/dashboard/dashboard.dart';
import 'package:digislips/app/modules/leave/leave_model/leave_model.dart';
import 'package:digislips/app/modules/leave/leave_service/leave_service.dart';
import 'package:digislips/app/modules/leave/leave_status/leave_status_page.dart';
import 'package:digislips/app/modules/logout/logout.dart';
import 'package:digislips/app/modules/notification/notification_screen.dart';
import 'package:digislips/app/modules/profile/Profile_screen.dart';
import 'package:digislips/app/modules/setting/setting.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

// Updated LeaveApplication class to work with LeaveModel
class LeaveApplication {
  final String type;
  final String date;
  final String status;
  final Color statusColor;
  final String? id;
  final String? reason;
  final String? studentName;
  final String? rollNumber;
  final String? department;
  final String? studentId;

  LeaveApplication({
    required this.type,
    required this.date,
    required this.status,
    required this.statusColor,
    this.id,
    this.reason,
    this.studentName,
    this.rollNumber,
    this.department,
    this.studentId,
  });

  // Factory method to create from LeaveModel
  factory LeaveApplication.fromLeaveModel(LeaveModel leave) {
    Color statusColor;
    switch (leave.status.toLowerCase()) {
      case 'approved':
        statusColor = const Color(0xFF4CAF50);
        break;
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'rejected':
        statusColor = const Color(0xFFD32F2F);
        break;
      default:
        statusColor = Colors.orange;
    }

    // Format date range
    String dateRange;
    if (leave.fromDate.day == leave.toDate.day &&
        leave.fromDate.month == leave.toDate.month &&
        leave.fromDate.year == leave.toDate.year) {
      dateRange =
          '${leave.fromDate.day}/${leave.fromDate.month}/${leave.fromDate.year}';
    } else {
      dateRange =
          '${leave.fromDate.day}/${leave.fromDate.month} - ${leave.toDate.day}/${leave.toDate.month}/${leave.toDate.year}';
    }

    return LeaveApplication(
      id: leave.id,
      type: leave.leaveType,
      date: dateRange,
      status: leave.status,
      statusColor: statusColor,
      reason: leave.reason,
      studentName: leave.fullName,
      rollNumber: leave.rollNumber,
      department: leave.department,
      studentId: leave.uid,
    );
  }
}

// Enhanced HomeController with proper data cleanup
class HomeController extends GetxController {
  var selectedIndex = 0.obs;
  var isLoading = true.obs;
  var isLoadingLeaves = false.obs;
  var isVerifyingEmail = false.obs;
  var student = Rxn<Student>(); // Current logged-in user data
  var parentStudentData =
      Rxn<Map<String, dynamic>>(); // Student data for parent
  var parentData = Rxn<Map<String, dynamic>>(); // Parent's own data

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LeaveService _leaveService = LeaveService();

  // User role variables
  var userRole = ''.obs;
  var isParent = false.obs;
  var isTeacher = false.obs;
  var userEmail = ''.obs;
  var uid = ''.obs;

  // Updated to use reactive list for leave applications
  final recentLeaveApplications = <LeaveApplication>[].obs;

  // Stream subscription for leave applications
  StreamSubscription? _leaveSubscription;

  // Add a flag to track if controller is initialized
  var _isInitialized = false.obs;

  void resetUserData() {
    print('🔄 Resetting user data...');

    // Cancel and clear subscriptions
    _leaveSubscription?.cancel();
    _leaveSubscription = null;

    // Reset all Rx variables to their initial state
    student.value = null;
    parentStudentData.value = null;
    parentData.value = null;
    recentLeaveApplications.clear();
    userRole.value = '';
    isParent.value = false;
    isTeacher.value = false;
    userEmail.value = '';
    uid.value = '';
    isLoading.value = true;
    isLoadingLeaves.value = false;
    isVerifyingEmail.value = false;

    // Reset initialization flag
    _isInitialized.value = false;

    print('✅ User data reset complete');
  }

  @override
  void onInit() {
    super.onInit();
    print('🚀 HomeController onInit called');
    resetUserData();
    getUserDetailsFromPrefs();
  }

  @override
  void onClose() {
    print('🔚 HomeController onClose called');
    _leaveSubscription?.cancel();
    super.onClose();
  }

  // Method to force reinitialize the controller
  void forceReinitialize() {
    print('🔄 Force reinitializing HomeController...');
    resetUserData();
    getUserDetailsFromPrefs();
  }

  // Method to be called when user logs out
  void onUserLogout() {
    print('👋 User logging out - cleaning up controller data');
  }

  // Method to be called when new user logs in
  void onUserLogin() {
    print('👤 New user logging in - reinitializing controller');
    resetUserData();
    getUserDetailsFromPrefs();
  }

  // Get user details from SharedPreferences and initialize based on role
  Future<void> getUserDetailsFromPrefs() async {
    try {
      // Ensure we start with clean state
      if (_isInitialized.value) {
        print('⚠️ Controller already initialized, resetting first...');
        resetUserData();
      }

      final prefs = await SharedPreferences.getInstance();

      // Get stored values
      String? storedUid = prefs.getString('uid');
      String? storedUserRole = prefs.getString('userRole');
      bool? storedIsParent = prefs.getBool('isParent');
      bool? storedIsTeacher = prefs.getBool('isTeacher');
      String? storedEmail = prefs.getString('Email');

      // Validate that we have essential data
      if (storedUid == null || storedUid.isEmpty) {
        print('❌ No valid UID found in preferences');
        Get.snackbar(
          'Error',
          'User not found. Please login again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Update reactive variables
      uid.value = storedUid;
      userRole.value = storedUserRole ?? '';
      isParent.value = storedIsParent ?? false;
      isTeacher.value = storedIsTeacher ?? false;
      userEmail.value = storedEmail ?? '';

      // Print for debugging
      print("🔍 Loading user data:");
      print("  UID: ${uid.value}");
      print("  Email: ${userEmail.value}");
      print("  Role: ${userRole.value}");
      print("  Is Parent: ${isParent.value}");
      print("  Is Teacher: ${isTeacher.value}");

      // Initialize based on role
      if (userRole.value == 'parent' || isParent.value) {
        print("😁😁😁😁😁😁😁");
        await initializeParentData();
      } else if (userRole.value == 'teacher' || isTeacher.value) {
        print("👍👍👍👍👍👍👍👍👍");
        await initializeTeacherData();
      } else {
        print("😊😊😊😊😊😊😊");
        await fetchCurrentUserData();
      }

      _isInitialized.value = true;
      print('✅ Controller initialization complete');
    } catch (e) {
      print('❌ Error getting user details from prefs: $e');
      Get.snackbar(
        'Error',
        'Failed to load user data. Please try logging in again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      isLoading.value = false;
    }
  }

  // Fetch parent's own data from Firestore
  Future<Map<String, dynamic>?> _fetchParentData() async {
    try {
      print('🔍 Fetching parent data for UID: ${uid.value}');

      // Try to fetch from parents collection first
      DocumentSnapshot parentDoc = await _firestore
          .collection('parents')
          .doc(uid.value)
          .get();

      if (parentDoc.exists && parentDoc.data() != null) {
        Map<String, dynamic> parentData = Map<String, dynamic>.from(
          parentDoc.data() as Map<String, dynamic>,
        );
        parentData['uid'] = uid.value;
        print(
          '✅ Parent data found in parents collection: ${parentData['fullName']}',
        );
        return parentData;
      }

      // If not found in parents collection, try other collections
      print(
        'Parent not found in parents collection, trying other collections...',
      );

      // Try teachers collection
      DocumentSnapshot teacherDoc = await _firestore
          .collection('teachers')
          .doc(uid.value)
          .get();

      if (teacherDoc.exists && teacherDoc.data() != null) {
        Map<String, dynamic> teacherData = Map<String, dynamic>.from(
          teacherDoc.data() as Map<String, dynamic>,
        );
        teacherData['uid'] = uid.value;
        print(
          '✅ Parent data found in teachers collection: ${teacherData['fullName']}',
        );
        return teacherData;
      }

      // Try students collection
      DocumentSnapshot studentDoc = await _firestore
          .collection('students')
          .doc(uid.value)
          .get();

      if (studentDoc.exists && studentDoc.data() != null) {
        Map<String, dynamic> studentData = Map<String, dynamic>.from(
          studentDoc.data() as Map<String, dynamic>,
        );
        studentData['uid'] = uid.value;
        print(
          '✅ Parent data found in students collection: ${studentData['fullName']}',
        );
        return studentData;
      }

      print('❌ Parent data not found in any collection');
      return null;
    } catch (e) {
      print('❌ Error fetching parent data: $e');
      return null;
    }
  }

  // Enhanced initializeParentData with better error handling
  Future<void> initializeParentData() async {
    print('🔄 Initializing parent data for UID: ${uid.value}');

    try {
      isLoading.value = true;

      // First, fetch parent's own data
      final fetchedParentData = await _fetchParentData();
      if (fetchedParentData != null) {
        parentData.value = fetchedParentData;
        print('✅ Parent profile loaded: ${fetchedParentData['fullName']}');
      }

      // Then verify parent email and get STUDENT data (not mixed data)
      final studentData = await _verifyParentEmailInStudents(userEmail.value);

      if (studentData != null) {
        // Store ONLY student data in parentStudentData
        parentStudentData.value = studentData;

        // Create a Student object from the student data for consistency
        student.value = Student.fromMap(studentData);

        print(
          '✅ Parent data initialized for student: ${studentData['fullName']}',
        );
        print(
          '✅ Parent\'s own name: ${parentData.value?['fullName'] ?? 'Not found'}',
        );

        // Fetch leave applications for this specific student
        fetchParentStudentLeaveApplications(studentData['studentId']);
      } else {
        print('❌ No student found with parent email: ${userEmail.value}');
        Get.snackbar(
          'Error',
          'No student found with your parent email. Please contact administrator.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print('❌ Error initializing parent data: $e');
      Get.snackbar(
        'Error',
        'Failed to initialize parent data: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Verify parent email in students collection to return ONLY student data
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
        final studentData = Map<String, dynamic>.from(
          querySnapshot.docs.first.data(),
        );
        studentData['studentId'] =
            querySnapshot.docs.first.id; // Add document ID

        print(
          '✅ Found student with matching parent email: ${studentData['fullName']}',
        );
        print('🔍 Student data keys: ${studentData.keys.toList()}');

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

  // Initialize teacher-specific data
  Future<void> initializeTeacherData() async {
    print('🔄 Initializing teacher data...');
    await fetchCurrentTeacherData();
    fetchAllStudentsLeaveApplications();
  }

  // Fetch leave applications for parent's specific student
  void fetchParentStudentLeaveApplications(String studentId) {
    try {
      isLoadingLeaves.value = true;
      print(
        '👨‍👩‍👧‍👦 Fetching leave applications for parent\'s student: $studentId',
      );

      // Cancel previous subscription if exists
      _leaveSubscription?.cancel();

      // Get leave applications for the specific student
      _leaveSubscription = _firestore
          .collection('students')
          .doc(studentId)
          .collection('leave')
          .orderBy('submittedAt', descending: true)
          .snapshots()
          .listen(
            (snapshot) {
              List<LeaveModel> leaves = [];

              if (snapshot.docs.isNotEmpty) {
                print(
                  '📄 Processing ${snapshot.docs.length} leaves for parent view',
                );

                leaves = snapshot.docs.map((leaveDoc) {
                  return LeaveModel.fromFirestore(leaveDoc).copyWith(
                    id: leaveDoc.id,
                    uid: studentId,
                    fullName: parentStudentData.value?['fullName'],
                    rollNumber: parentStudentData.value?['rollNumber'],
                    department: parentStudentData.value?['department'],
                    email: parentStudentData.value?['email'],
                    phone: parentStudentData.value?['phone'],
                    parentPhone: parentStudentData.value?['parentPhone'],
                  );
                }).toList();
              }

              // Convert LeaveModel to LeaveApplication
              final applications = leaves.map((leave) {
                return LeaveApplication.fromLeaveModel(leave);
              }).toList();

              // Update the reactive list
              recentLeaveApplications.assignAll(applications);
              isLoadingLeaves.value = false;

              print(
                '✅ Successfully loaded ${applications.length} leave applications for parent',
              );
            },
            onError: (error) {
              print(
                '❌ Error fetching parent student leave applications: $error',
              );
              Get.snackbar(
                'Error',
                'Failed to load leave applications: $error',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.red,
                colorText: Colors.white,
              );
              isLoadingLeaves.value = false;
            },
          );
    } catch (e) {
      print('❌ Error setting up parent student leave applications stream: $e');
      Get.snackbar(
        'Error',
        'Failed to setup leave applications: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      isLoadingLeaves.value = false;
    }
  }

  // Fetch current teacher data using UID (existing method)
  Future<void> fetchCurrentTeacherData() async {
    try {
      isLoading.value = true;

      if (uid.value.isEmpty) {
        Get.snackbar(
          'Error',
          'User not found. Please login again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Fetch current teacher data from Firestore using UID
      final docSnapshot = await _firestore
          .collection('teachers')
          .doc(uid.value)
          .get();

      if (docSnapshot.exists) {
        student.value = Student.fromMap(docSnapshot.data()!);
        print('✅ Current teacher loaded: ${student.value?.fullName}');
      } else {
        // If not found in teachers, try students collection
        final studentSnapshot = await _firestore
            .collection('students')
            .doc(uid.value)
            .get();

        if (studentSnapshot.exists) {
          student.value = Student.fromMap(studentSnapshot.data()!);
          print('✅ Current user loaded: ${student.value?.fullName}');
        } else {
          Get.snackbar(
            'Error',
            'User profile not found.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load profile: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      print('❌ Error fetching teacher data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Generic method to fetch current user data
  Future<void> fetchCurrentUserData() async {
    try {
      isLoading.value = true;

      if (uid.value.isEmpty) {
        Get.snackbar(
          'Error',
          'User not found. Please login again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Try multiple collections to find user
      DocumentSnapshot? userDoc;

      // Try teachers first
      userDoc = await _firestore.collection('teachers').doc(uid.value).get();

      if (!userDoc.exists) {
        // Try students
        userDoc = await _firestore.collection('students').doc(uid.value).get();
      }

      if (!userDoc.exists) {
        // Try parents
        userDoc = await _firestore.collection('parents').doc(uid.value).get();
      }

      if (userDoc.exists) {
        student.value = Student.fromMap(userDoc.data() as Map<String, dynamic>);
        print('✅ Current user loaded: ${student.value?.fullName}');

        // Fetch appropriate leave applications
        fetchAllStudentsLeaveApplications();
      } else {
        Get.snackbar(
          'Error',
          'User profile not found.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load profile: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      print('❌ Error fetching user data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Fetch all students' leave applications using collection method (for teachers)
  void fetchAllStudentsLeaveApplications() async {
    try {
      isLoadingLeaves.value = true;
      print(
        '👨‍💼 Fetching all students leave applications for admin dashboard',
      );

      // Get department from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      String? department = prefs.getString('department');

      if (department == null || department.isEmpty) {
        print('⚠️ No department found in SharedPreferences.');
        isLoadingLeaves.value = false;
        Get.snackbar(
          'Error',
          'Department not set in preferences.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Cancel previous subscription if exists
      _leaveSubscription?.cancel();

      // Fetch all students from selected department
      _leaveSubscription = _firestore
          .collection('students')
          .where("department", isEqualTo: department)
          .snapshots()
          .asyncMap((studentSnapshot) async {
            List<LeaveModel> allLeaves = [];
            print(
              '📋 Processing ${studentSnapshot.docs.length} students for admin view in $department',
            );

            for (var studentDoc in studentSnapshot.docs) {
              try {
                var leaveSnapshot = await studentDoc.reference
                    .collection('leave')
                    .orderBy('submittedAt', descending: true)
                    .limit(10) // Limit to recent 10 applications per student
                    .get();

                if (leaveSnapshot.docs.isNotEmpty) {
                  print(
                    '📄 Processing ${leaveSnapshot.docs.length} leaves for ${studentDoc['fullName']}',
                  );

                  allLeaves.addAll(
                    leaveSnapshot.docs.map((leaveDoc) {
                      return LeaveModel.fromFirestore(leaveDoc).copyWith(
                        id: leaveDoc.id,
                        uid: studentDoc.id,
                        fullName: studentDoc['fullName'],
                        rollNumber: studentDoc['rollNumber'],
                        department: studentDoc['department'],
                        email: studentDoc['email'],
                        phone: studentDoc['phone'],
                        parentPhone: studentDoc['parentPhone'],
                      );
                    }).toList(),
                  );
                }
              } catch (e) {
                print('❌ Error processing student ${studentDoc.id}: $e');
              }
            }

            // Sort all leaves by submission date (most recent first)
            allLeaves.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
            print('✅ Total applications for admin view: ${allLeaves.length}');
            return allLeaves;
          })
          .listen(
            (allLeaves) {
              final applications = allLeaves.map((leave) {
                return LeaveApplication.fromLeaveModel(leave);
              }).toList();

              recentLeaveApplications.assignAll(applications);
              isLoadingLeaves.value = false;

              print(
                '✅ Successfully loaded ${applications.length} leave applications for admin dashboard',
              );
            },
            onError: (error) {
              print('❌ Error fetching all students leave applications: $error');
              Get.snackbar(
                'Error',
                'Failed to load leave applications: $error',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.red,
                colorText: Colors.white,
              );
              isLoadingLeaves.value = false;
            },
          );
    } catch (e) {
      print('❌ Error setting up all students leave applications stream: $e');
      Get.snackbar(
        'Error',
        'Failed to setup leave applications: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      isLoadingLeaves.value = false;
    }
  }

  // Method to refresh data based on role
  Future<void> refreshUserData() async {
    if (userRole.value == 'parent' || isParent.value) {
      await initializeParentData();
    } else if (userRole.value == 'teacher' || isTeacher.value) {
      await fetchCurrentTeacherData();
      fetchAllStudentsLeaveApplications();
    } else {
      await fetchCurrentUserData();
    }
  }

  // Method to manually refresh only leave applications
  Future<void> refreshLeaveApplications() async {
    if (userRole.value == 'parent' || isParent.value) {
      if (parentStudentData.value != null) {
        fetchParentStudentLeaveApplications(
          parentStudentData.value!['studentId'],
        );
      }
    } else {
      fetchAllStudentsLeaveApplications();
    }
  }

  // Method to refresh all data (useful for debugging)
  Future<void> refreshAllData() async {
    print('🔄 Refreshing all data...');
    resetUserData();
    await getUserDetailsFromPrefs();
  }

  void changeBottomNavIndex(int index) {
    selectedIndex.value = index;
  }

  void LeaveRequests() {
    Get.to(LeaveRequestsScreen());
  }

  void onViewLeaveStatus() {
    Get.to(LeaveRequestsScreen());
  }

  void onMyProfile() {
    Get.to(ProfileScreen());
  }

  // Enhanced logout method
  void onLogout() async {
    try {
      print('🚪 Initiating logout process...');
      // Clean up controller data first
      onUserLogout();

      // Delete this controller instance so a new one is created on next login

      // Navigate to logout page
      Get.to(LogoutPage());
    } catch (e) {
      print('❌ Error during logout: $e');
      Get.snackbar(
        'Error',
        'Failed to logout: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Helper getters for easy access to user data
  String get studentName {
    if (isParent.value && parentStudentData.value != null) {
      return parentStudentData.value!['fullName'] ?? 'Student';
    }
    return student.value?.fullName ?? 'User';
  }

  // Updated currentUserName getter - FIXED VERSION
  String get currentUserName {
    if (isParent.value) {
      // For parents, first try to get from parent's own data
      if (parentData.value != null && parentData.value!['fullName'] != null) {
        print(
          '🔍 Getting parent name from parentData: ${parentData.value!['fullName']}',
        );
        return parentData.value!['fullName'];
      }

      // Second priority: Check if parentStudentData has parent's fullName
      if (parentStudentData.value != null) {
        print('🔍 parentStudentData contains: ${parentStudentData.value}');

        // The issue is here - parentStudentData actually contains the parent's fullName
        // Check if this data has parent-specific fields
        if (parentStudentData.value!.containsKey('parentUid') ||
            parentStudentData.value!.containsKey('parentAccountCreated')) {
          // This means parentStudentData actually contains parent data
          String? parentFullName = parentStudentData.value!['fullName'];
          if (parentFullName != null && parentFullName.isNotEmpty) {
            print(
              '✅ Found parent fullName in parentStudentData: $parentFullName',
            );
            print(parentStudentData.value);
            return parentFullName;
          }
        }

        // Try different possible fields for parent name
        String? parentName =
            parentStudentData.value!['parentName'] ??
            parentStudentData.value!['fatherName'] ??
            parentStudentData.value!['motherName'] ??
            parentStudentData.value!['guardianName'];

        if (parentName != null && parentName.isNotEmpty) {
          print('✅ Found parent name in alternate fields: $parentName');
          return parentName;
        }
      }

      // Final fallback to email username
      String emailName = userEmail.value
          .split('@')[0]
          .replaceAll('.', ' ')
          .toUpperCase();
      print('⚠️ Using email fallback for parent name: $emailName');
      return emailName;
    } else if (isTeacher.value) {
      // For teachers, get teacher's own name from their profile
      return student.value?.fullName ?? userEmail.value.split('@')[0];
    } else {
      // For other users, try to get their profile name
      return student.value?.fullName ?? userEmail.value.split('@')[0];
    }
  }

  // Get time-based greeting
  String get timeBasedGreeting {
    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute;

    // Good Morning: 5:00 AM - 11:59 AM
    // Good Afternoon: 12:00 PM - 4:59 PM
    // Good Evening: 5:00 PM - 8:59 PM
    // Good Night: 9:00 PM - 4:59 AM
    if (hour >= 5 && hour < 12) {
      return 'Good Morning';
    } else if ((hour == 12 && minute >= 0) || (hour > 12 && hour < 17)) {
      return 'Good Afternoon';
    } else if (hour >= 17 && hour < 21) {
      return 'Good Evening';
    } else {
      return 'Good Night';
    }
  }

  // Get complete greeting with user name
  String get completeGreeting {
    return '$timeBasedGreeting, ${currentUserName}!';
  }

  // Get role-specific greeting
  String get roleBasedGreeting {
    String roleTitle = '';
    if (isParent.value) {
      roleTitle = ' (Parent)';
    } else if (isTeacher.value) {
      roleTitle = ' (Teacher)';
    }

    return '$timeBasedGreeting, ${currentUserName}$roleTitle!';
  }

  String get studentDepartment {
    if (isParent.value && parentStudentData.value != null) {
      return parentStudentData.value!['department'] ?? 'Unknown';
    }
    return student.value?.department ?? 'Unknown';
  }

  String get studentId {
    if (isParent.value && parentStudentData.value != null) {
      return parentStudentData.value!['rollNumber'] ?? 'N/A';
    }
    return student.value?.rollNumber ?? 'N/A';
  }

  String get studentEmail {
    if (isParent.value && parentStudentData.value != null) {
      return parentStudentData.value!['email'] ?? '';
    }
    return student.value?.email ?? '';
  }

  String get studentPhone {
    if (isParent.value && parentStudentData.value != null) {
      return parentStudentData.value!['phone'] ?? '';
    }
    return student.value?.phone ?? '';
  }

  String get studentSemester {
    if (isParent.value && parentStudentData.value != null) {
      return parentStudentData.value!['semester'] ?? '';
    }
    return student.value?.semester ?? '';
  }

  String? get profileImageUrl {
    if (isParent.value) {
      // For parents, try to get parent's profile image first
      if (parentData.value != null &&
          parentData.value!['profileImageUrl'] != null) {
        return parentData.value!['profileImageUrl'];
      }
      // Fallback to student's image
      if (parentStudentData.value != null) {
        return parentStudentData.value!['profileImageUrl'];
      }
    }
    return student.value?.profileImageUrl;
  }

  bool get isProfileComplete {
    if (isParent.value) {
      // For parents, check if parent profile is complete
      if (parentData.value != null) {
        return parentData.value!['profileComplete'] ?? false;
      }
      // Fallback to student data
      if (parentStudentData.value != null) {
        return parentStudentData.value!['profileComplete'] ?? false;
      }
    }
    return student.value?.profileComplete ?? false;
  }

  // Helper getters for leave applications
  bool get hasRecentLeaves => recentLeaveApplications.isNotEmpty;
  int get recentLeavesCount => recentLeaveApplications.length;

  // Get leave statistics for display
  Map<String, int> get leaveStats {
    final stats = {
      'total': recentLeaveApplications.length,
      'approved': 0,
      'pending': 0,
      'rejected': 0,
    };

    for (final leave in recentLeaveApplications) {
      switch (leave.status.toLowerCase()) {
        case 'approved':
          stats['approved'] = stats['approved']! + 1;
          break;
        case 'pending':
          stats['pending'] = stats['pending']! + 1;
          break;
        case 'rejected':
          stats['rejected'] = stats['rejected']! + 1;
          break;
      }
    }

    return stats;
  }

  // Get applications by status
  List<LeaveApplication> getApplicationsByStatus(String status) {
    return recentLeaveApplications
        .where((app) => app.status.toLowerCase() == status.toLowerCase())
        .toList();
  }

  // Get applications for a specific student (useful for teachers)
  List<LeaveApplication> getApplicationsForStudent(String studentId) {
    return recentLeaveApplications
        .where((app) => app.studentId == studentId)
        .toList();
  }

  // Get unique students who have applied for leaves (for teachers)
  List<String> get uniqueStudents {
    final students = <String>{};
    for (final app in recentLeaveApplications) {
      if (app.studentName != null) {
        students.add(app.studentName!);
      }
    }
    return students.toList();
  }

  // Role-based helper getters
  bool get isCurrentUserParent => userRole.value == 'parent' || isParent.value;
  bool get isCurrentUserTeacher =>
      userRole.value == 'teacher' || isTeacher.value;

  String get currentUserRole => userRole.value;
  String get currentUserEmail => userEmail.value;
  String get currentUserId => uid.value;

  // Additional helper methods for UI
  String get welcomeMessage {
    if (isParent.value) {
      return 'Welcome to your child\'s dashboard';
    } else if (isTeacher.value) {
      return 'Welcome to your teacher dashboard';
    } else {
      return 'Welcome to your dashboard';
    }
  }

  // Get greeting with emoji based on time
  String get greetingWithEmoji {
    final hour = DateTime.now().hour;
    String emoji = '';

    if (hour >= 5 && hour < 12) {
      emoji = '🌅';
    } else if (hour >= 12 && hour < 17) {
      emoji = '🌞';
    } else if (hour >= 17 && hour < 21) {
      emoji = '🌆';
    } else {
      emoji = '🌙';
    }

    return '$emoji $timeBasedGreeting';
  }

  // Get detailed user info for display
  Map<String, String> get userDisplayInfo {
    return {
      'name': currentUserName,
      'role': isParent.value
          ? 'Parent'
          : isTeacher.value
          ? 'Teacher'
          : 'User',
      'email': userEmail.value,
      'greeting': timeBasedGreeting,
      'completeGreeting': completeGreeting,
      'greetingWithEmoji': greetingWithEmoji,
      'welcomeMessage': welcomeMessage,
    };
  }
}
