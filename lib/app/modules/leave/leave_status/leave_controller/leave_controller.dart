// controllers/leave_controller.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digislips/app/modules/leave/leave_model/leave_model.dart';
import 'package:digislips/app/modules/leave/leave_service/leave_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LeaveController extends GetxController {
  final LeaveService _leaveService = LeaveService();
  final RxList<LeaveModel> leaveRequests = <LeaveModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString selectedFilter = 'All'.obs;
  final RxString currentUserId = ''.obs;
  final RxString userRole = ''.obs; // 'student', 'admin', 'teacher'

  // Add a StreamSubscription to properly manage the listener
  StreamSubscription<List<LeaveModel>>? _leaveSubscription;

  @override
  void onInit() {
    super.onInit();
    _initializeUser();
  }

  @override
  void onClose() {
    // Cancel the subscription when controller is disposed
    _leaveSubscription?.cancel();
    super.onClose();
  }

  Future<void> _initializeUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString('uid');
      final role = prefs.getString('userRole') ?? 'student';

      if (uid != null && uid.isNotEmpty) {
        currentUserId.value = uid;
        userRole.value = role;
        print('🔥 Initialized user - ID: $uid, Role: $role');
        _listenToLeaveRequests();
      }
    } catch (e) {
      print('❌ Error initializing user: $e');
      Get.snackbar('Error', 'Failed to initialize user: $e');
    }
  }

  void _listenToLeaveRequests() {
    if (currentUserId.value.isEmpty) return;

    print('🔍 Listening to leave requests for role: ${userRole.value}');

    // Cancel existing subscription before creating a new one
    _leaveSubscription?.cancel();

    // If user is admin/teacher, get all leave applications
    // If user is student, get only their applications
    Stream<List<LeaveModel>> leaveStream;

    if (userRole.value == 'Parent' || userRole.value == 'teacher') {
      print('👨‍💼 Fetching all leave applications for admin/teacher');
      leaveStream = _leaveService.getAllLeaveApplicationsForRole();
    } else {
      print(
        '👨‍🎓 Fetching student leave applications for: ${currentUserId.value}',
      );
      leaveStream = _leaveService.getStudentLeaveApplications(
        currentUserId.value,
      );
    }

    _leaveSubscription = leaveStream.listen(
      (leaves) {
        // Sort leaves by submission date (newest first)
        leaves.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
        leaveRequests.value = leaves;
        print('✅ Successfully fetched ${leaves.length} leave requests');

        // Force UI update
        leaveRequests.refresh();
      },
      onError: (error) {
        print('❌ Error fetching leave requests: $error');
        Get.snackbar('Error', 'Failed to fetch leave requests: $error');
      },
    );
  }

  List<LeaveModel> get filteredRequests {
    List<LeaveModel> filtered = leaveRequests;

    // Apply status filter
    if (selectedFilter.value != 'All') {
      filtered = filtered
          .where(
            (request) =>
                request.status.toLowerCase() ==
                selectedFilter.value.toLowerCase(),
          )
          .toList();
    }

    return filtered;
  }

  // Updated method to handle approval/rejection with proper parameters
  Future<void> updateLeaveStatus(
    String leaveId,
    String status, {
    String? reviewComments,
    String? studentId,
  }) async {
    if (currentUserId.value.isEmpty) {
      print('❌ User not authenticated');
      Get.snackbar('Error', 'User not authenticated');
      return;
    }

    // Find the leave request to get the correct student ID
    final leaveRequest = leaveRequests.firstWhereOrNull(
      (leave) => leave.id == leaveId,
    );
    if (leaveRequest == null) {
      print('❌ Leave request not found with ID: $leaveId');
      Get.snackbar('Error', 'Leave request not found');
      return;
    }

    // Use the student ID from the leave request (uid field)
    final actualStudentId = leaveRequest.uid ?? studentId;
    if (actualStudentId == null || actualStudentId.isEmpty) {
      print('❌ Student ID not found for leave request: $leaveId');
      Get.snackbar('Error', 'Student ID not found');
      return;
    }

    try {
      isLoading.value = true;
      print('🔄 Starting leave status update...');
      print('📋 Leave ID: $leaveId');
      print('👤 Student ID: $actualStudentId');
      print('📊 New Status: $status');

      // Get current user name from preferences for reviewedBy field
      final prefs = await SharedPreferences.getInstance();
      final reviewerName = prefs.getString('userName') ?? 'Admin';

      await _leaveService.updateLeaveStatus(
        studentId: actualStudentId,
        leaveId: leaveId,
        status: status,
        reviewedBy: reviewerName,
        reviewComments: reviewComments,
        userId: currentUserId.value,
      );

      // Optimistically update the local state immediately
      final updatedRequests = leaveRequests.map((request) {
        if (request.id == leaveId) {
          return request.copyWith(
            status: status,
            reviewedBy: reviewerName,
            reviewComments: reviewComments,
            reviewedAt: DateTime.now(),
          );
        }
        return request;
      }).toList();

      leaveRequests.value = updatedRequests;
      leaveRequests.refresh();

      String message = status.toLowerCase() == 'approved'
          ? 'Leave request approved successfully'
          : 'Leave request rejected successfully';

      print('✅ Leave status updated successfully');
    } catch (e) {
      print('❌ Failed to update leave status: $e');
      Get.snackbar('Error', 'Failed to update leave request: $e');

      // Refresh data from server in case of error
      await refreshLeaveRequests();
    } finally {
      isLoading.value = false;
    }
  }

  // Method to show approval/rejection dialog
  Future<void> showApprovalDialog(LeaveModel request) async {
    String? reviewComments;
    final TextEditingController commentsController = TextEditingController();

    print('📝 Showing approval dialog for leave: ${request.id}');
    print('👤 Student: ${request.fullName} (${request.uid})');

    Get.dialog(
      AlertDialog(
        title: Text('Review Leave Application'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Student: ${request.fullName}'),
            Text('Roll Number: ${request.rollNumber}'),
            Text('Leave Type: ${request.leaveType}'),
            Text('Duration: ${request.totalDays} days'),
            Text('Reason: ${request.reason}'),
            SizedBox(height: 16),
            TextField(
              controller: commentsController,
              decoration: InputDecoration(
                labelText: 'Review Comments (Optional)',
                border: OutlineInputBorder(),
                hintText: 'Add your comments here...',
              ),
              maxLines: 3,
              onChanged: (value) => reviewComments = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              print('❌ Approval dialog cancelled');
              Get.back();
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              print('❌ Rejecting leave request: ${request.id}');
              Get.back();
              await updateLeaveStatus(
                request.id!,
                'Rejected',
                reviewComments: commentsController.text.trim().isEmpty
                    ? null
                    : commentsController.text.trim(),
                studentId: request.uid,
              );
            },
            child: Text('Reject', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () async {
              print('✅ Approving leave request: ${request.id}');
              Get.back();
              await updateLeaveStatus(
                request.id!,
                'Approved',
                reviewComments: commentsController.text.trim().isEmpty
                    ? null
                    : commentsController.text.trim(),
                studentId: request.uid,
              );
            },
            child: Text('Approve'),
          ),
        ],
      ),
    );
  }

  Future<void> deleteLeaveRequest(String leaveId) async {
    if (currentUserId.value.isEmpty) {
      print('❌ User not authenticated for delete operation');
      Get.snackbar('Error', 'User not authenticated');
      return;
    }

    try {
      isLoading.value = true;
      print('🗑️ Deleting leave request: $leaveId');
      // Implement delete functionality in service
      // await _leaveService.deleteLeaveApplication(currentUserId.value, leaveId);

      // Optimistically remove from local state
      leaveRequests.removeWhere((request) => request.id == leaveId);
      leaveRequests.refresh();

      Get.snackbar('Success', 'Leave request deleted successfully');
    } catch (e) {
      print('❌ Failed to delete leave request: $e');
      Get.snackbar('Error', 'Failed to delete leave request: $e');
      // Refresh data from server in case of error
      await refreshLeaveRequests();
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, int>> getLeaveStatistics() async {
    if (currentUserId.value.isEmpty) {
      return {
        'total': 0,
        'approved': 0,
        'pending': 0,
        'rejected': 0,
        'totalDays': 0,
        'approvedDays': 0,
      };
    }

    try {
      if (userRole.value == 'Parents' || userRole.value == 'teacher') {
        // Return statistics for all applications
        final allRequests = leaveRequests;
        print('📊 Calculating statistics for ${allRequests.length} requests');
        return {
          'total': allRequests.length,
          'approved': allRequests
              .where((r) => r.status.toLowerCase() == 'approved')
              .length,
          'pending': allRequests
              .where((r) => r.status.toLowerCase() == 'pending')
              .length,
          'rejected': allRequests
              .where((r) => r.status.toLowerCase() == 'rejected')
              .length,
          'totalDays': allRequests.fold(0, (sum, r) => sum + r.totalDays),
          'approvedDays': allRequests
              .where((r) => r.status.toLowerCase() == 'approved')
              .fold(0, (sum, r) => sum + r.totalDays),
        };
      } else {
        return await _leaveService.getLeaveStatistics(currentUserId.value);
      }
    } catch (e) {
      print('❌ Failed to get leave statistics: $e');
      Get.snackbar('Error', 'Failed to get leave statistics: $e');
      return {
        'total': 0,
        'approved': 0,
        'pending': 0,
        'rejected': 0,
        'totalDays': 0,
        'approvedDays': 0,
      };
    }
  }

  Future<bool> checkOverlappingLeave({
    required DateTime fromDate,
    required DateTime toDate,
    String? excludeLeaveId,
  }) async {
    if (currentUserId.value.isEmpty) {
      return false;
    }

    try {
      return await _leaveService.hasOverlappingLeave(
        userId: currentUserId.value,
        fromDate: fromDate,
        toDate: toDate,
        excludeLeaveId: excludeLeaveId,
        studentId: currentUserId.value,
      );
    } catch (e) {
      print('❌ Failed to check overlapping leave: $e');
      Get.snackbar('Error', 'Failed to check overlapping leave: $e');
      return false;
    }
  }

  Future<void> refreshLeaveRequests() async {
    print('🔄 Refreshing leave requests...');
    if (currentUserId.value.isNotEmpty) {
      _listenToLeaveRequests();
    }
  }

  // Helper method to check if current user can approve/reject
  bool get canApproveReject =>
      userRole.value == 'admin' || userRole.value == 'teacher';

  // Helper method to check if current user can delete
  bool canDelete(LeaveModel request) {
    if (userRole.value == 'admin') return true;
    if (userRole.value == 'student' &&
        request.status.toLowerCase() == 'pending') {
      return true;
    }
    return false;
  }
}
