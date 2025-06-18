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

  LeaveApplication({
    required this.type,
    required this.date,
    required this.status,
    required this.statusColor,
    this.id,
    this.reason,
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
    );
  }
}

class HomeController extends GetxController {
  var selectedIndex = 0.obs;
  var isLoading = true.obs;
  var isLoadingLeaves = false.obs;
  var student = Rxn<Student>();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LeaveService _leaveService = LeaveService();

  // Updated to use reactive list
  final recentLeaveApplications = <LeaveApplication>[].obs;

  // Stream subscription for leave applications
  StreamSubscription? _leaveSubscription;

  @override
  void onInit() {
    super.onInit();
    fetchStudentData();
  }

  @override
  void onClose() {
    _leaveSubscription?.cancel();
    super.onClose();
  }

  Future<void> fetchStudentData() async {
    try {
      isLoading.value = true;

      // Get UID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString('uid');

      if (uid == null) {
        Get.snackbar(
          'Error',
          'User not found. Please login again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Fetch student data from Firestore
      final docSnapshot = await _firestore
          .collection('students')
          .doc(uid)
          .get();

      if (docSnapshot.exists) {
        student.value = Student.fromMap(docSnapshot.data()!);
        // Fetch leave applications after student data is loaded
        // _fetchRecentLeaveApplications(uid);
      } else {
        Get.snackbar(
          'Error',
          'Student profile not found.',
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
    } finally {
      isLoading.value = false;
    }
  }

  // // Fetch recent leave applications (last 5)
  // void _fetchRecentLeaveApplications(String uid) {
  //   try {
  //     isLoadingLeaves.value = true;

  //     // Cancel previous subscription if exists
  //     _leaveSubscription?.cancel();

  //     // Listen to user's leave applications
  //     _leaveSubscription = _leaveService
  //         .getUserLeaveApplications(uid)
  //         .listen(
  //           (leaveModels) {
  //             // Convert LeaveModel to LeaveApplication and take only recent 5
  //             final applications = leaveModels
  //                 .take(5) // Get only the first 5 (most recent)
  //                 .map((leave) => LeaveApplication.fromLeaveModel(leave))
  //                 .toList();

  //             recentLeaveApplications.assignAll(applications);
  //             isLoadingLeaves.value = false;
  //           },
  //           onError: (error) {
  //             print('Error fetching leave applications: $error');
  //             Get.snackbar(
  //               'Error',
  //               'Failed to load leave applications: $error',
  //               snackPosition: SnackPosition.BOTTOM,
  //               backgroundColor: Colors.red,
  //               colorText: Colors.white,
  //             );
  //             isLoadingLeaves.value = false;
  //           },
  //         );
  //   } catch (e) {
  //     print('Error setting up leave applications stream: $e');
  //     isLoadingLeaves.value = false;
  //   }
  // }

  // Method to refresh student data and leave applications
  Future<void> refreshStudentData() async {
    await fetchStudentData();
  }

  // Method to manually refresh only leave applications
  Future<void> refreshLeaveApplications() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('uid');

    if (uid != null) {
      // _fetchRecentLeaveApplications(uid);
    }
  }

  void changeBottomNavIndex(int index) {
    selectedIndex.value = index;
  }

  void LeaveRequests() {
    Get.to(LeaveRequestsScreen());
    // Get.snackbar(
    //   'Apply for Leave',
    //   'Navigate to leave application form',
    //   snackPosition: SnackPosition.BOTTOM,
    // );
  }

  void onViewLeaveStatus() {
    Get.to(LeaveRequestsScreen());
    // Get.snackbar(
    //   'Leave Status',
    //   'Navigate to leave status page',
    //   snackPosition: SnackPosition.BOTTOM,
    // );
  }

  void onMyProfile() {
    Get.to(ProfileScreen());
    // Get.snackbar(
    //   'My Profile',
    //   'Navigate to profile page',
    //   snackPosition: SnackPosition.BOTTOM,
    // );
  }

  void onLogout() async {
    try {
      // Cancel leave applications subscription
      _leaveSubscription?.cancel();

      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Clear student data and leave applications
      student.value = null;
      recentLeaveApplications.clear();

      Get.to(LogoutPage());
      // Get.snackbar(
      //   'Logout',
      //   'Logging out...',
      //   snackPosition: SnackPosition.BOTTOM,
      // );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to logout: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Helper getters for easy access to student data
  String get studentName => student.value?.fullName ?? 'Student';
  String get studentDepartment => student.value?.department ?? 'Unknown';
  String get studentId => student.value?.rollNumber ?? 'N/A';
  String get studentEmail => student.value?.email ?? '';
  String get studentPhone => student.value?.phone ?? '';
  String get studentSemester => student.value?.semester ?? '';
  String? get profileImageUrl => student.value?.profileImageUrl;
  bool get isProfileComplete => student.value?.profileComplete ?? false;
}
