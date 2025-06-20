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

class HomeController extends GetxController {
  var selectedIndex = 0.obs;
  var isLoading = true.obs;
  var isLoadingLeaves = false.obs;
  var student = Rxn<Student>(); // Current logged-in teacher data

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LeaveService _leaveService = LeaveService();

  // Updated to use reactive list for all students' leave applications
  final recentLeaveApplications = <LeaveApplication>[].obs;

  // Stream subscription for leave applications
  StreamSubscription? _leaveSubscription;

  @override
  void onInit() {
    super.onInit();
    fetchCurrentTeacherData();
    fetchAllStudentsLeaveApplications();
  }

  @override
  void onClose() {
    _leaveSubscription?.cancel();
    super.onClose();
  }

  // Fetch current logged-in teacher data using UID
  Future<void> fetchCurrentTeacherData() async {
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

      // Fetch current teacher data from Firestore using UID
      final docSnapshot = await _firestore
          .collection('teachers') // Assuming teachers collection
          .doc(uid)
          .get();

      if (docSnapshot.exists) {
        student.value = Student.fromMap(docSnapshot.data()!);
        print('✅ Current teacher loaded: ${student.value?.fullName}');
      } else {
        // If not found in teachers, try students collection
        final studentSnapshot = await _firestore
            .collection('students')
            .doc(uid)
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

  // Fetch all students' leave applications using collection method
  void fetchAllStudentsLeaveApplications() {
    try {
      isLoadingLeaves.value = true;
      print(
        '👨‍💼 Fetching all students leave applications for admin dashboard',
      );

      // Cancel previous subscription if exists
      _leaveSubscription?.cancel();

      // Get all students from CS department and their leave applications
      _leaveSubscription = _firestore
          .collection('students')
          .where("department", isEqualTo: "CS")
          .snapshots()
          .asyncMap((studentSnapshot) async {
            List<LeaveModel> allLeaves = [];
            print(
              '📋 Processing ${studentSnapshot.docs.length} students for admin view',
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
                        id: leaveDoc.id, // Leave document ID
                        uid: studentDoc.id, // Student ID
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
              // Convert LeaveModel to LeaveApplication
              final applications = allLeaves.map((leave) {
                return LeaveApplication.fromLeaveModel(leave);
              }).toList();

              // Update the reactive list
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

  // Method to refresh teacher data and all students' leave applications
  Future<void> refreshStudentData() async {
    await fetchCurrentTeacherData();
    fetchAllStudentsLeaveApplications();
  }

  // Method to manually refresh only leave applications
  Future<void> refreshLeaveApplications() async {
    fetchAllStudentsLeaveApplications();
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

  void onLogout() async {
    try {
      // Cancel leave applications subscription
      _leaveSubscription?.cancel();

      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Clear teacher data and leave applications
      student.value = null;
      recentLeaveApplications.clear();

      Get.to(LogoutPage());
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

  // Helper getters for easy access to teacher data
  String get studentName => student.value?.fullName ?? 'Teacher';
  String get studentDepartment => student.value?.department ?? 'Unknown';
  String get studentId => student.value?.rollNumber ?? 'N/A';
  String get studentEmail => student.value?.email ?? '';
  String get studentPhone => student.value?.phone ?? '';
  String get studentSemester => student.value?.semester ?? '';
  String? get profileImageUrl => student.value?.profileImageUrl;
  bool get isProfileComplete => student.value?.profileComplete ?? false;

  // Helper getters for leave applications (now for all students)
  bool get hasRecentLeaves => recentLeaveApplications.isNotEmpty;
  int get recentLeavesCount => recentLeaveApplications.length;

  // Get leave statistics for display (all students)
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

  // Get applications for a specific student
  List<LeaveApplication> getApplicationsForStudent(String studentId) {
    return recentLeaveApplications
        .where((app) => app.studentId == studentId)
        .toList();
  }

  // Get unique students who have applied for leaves
  List<String> get uniqueStudents {
    final students = <String>{};
    for (final app in recentLeaveApplications) {
      if (app.studentName != null) {
        students.add(app.studentName!);
      }
    }
    return students.toList();
  }
}
