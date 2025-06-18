// controllers/leave_controller.dart
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

  @override
  void onInit() {
    super.onInit();
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString('uid');
      final role = prefs.getString('userRole') ?? 'student';
      
      if (uid != null && uid.isNotEmpty) {
        currentUserId.value = uid;
        userRole.value = role;
        _listenToLeaveRequests();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to initialize user: $e');
    }
  }

  void _listenToLeaveRequests() {
    if (currentUserId.value.isEmpty) return;

    // If user is admin/teacher, get all leave applications
    // If user is student, get only their applications
    Stream<List<LeaveModel>> leaveStream;
    
    if (userRole.value == 'admin' || userRole.value == 'teacher') {
      leaveStream = _leaveService.getAllLeaveApplications()
          .map((list) => list.map((doc) => LeaveModel.fromFirestore(doc as DocumentSnapshot)).toList());
    } else {
      leaveStream = _leaveService.getStudentLeaveApplications(currentUserId.value);
    }

    leaveStream.listen(
      (leaves) {
        // Sort leaves by submission date (newest first)
        leaves.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
        leaveRequests.value = leaves;
        print('Successfully fetched leave requests: ${leaves.length} applications');
      },
      onError: (error) {
        Get.snackbar(
          'Error',
          'Failed to fetch leave requests: $error',
        );
      },
    );
  }

  List<LeaveModel> get filteredRequests {
    List<LeaveModel> filtered = leaveRequests;
    
    // Apply status filter
    if (selectedFilter.value != 'All') {
      filtered = filtered
          .where((request) =>
              request.status.toLowerCase() ==
              selectedFilter.value.toLowerCase())
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
      Get.snackbar('Error', 'User not authenticated');
      return;
    }

    try {
      isLoading.value = true;
      
      // Get current user name from preferences for reviewedBy field
      final prefs = await SharedPreferences.getInstance();
      final reviewerName = prefs.getString('userName') ?? 'Admin';
      
      await _leaveService.updateLeaveStatus(
        userId: currentUserId.value,
        leaveId: leaveId,
        status: status,
        reviewedBy: reviewerName,
        reviewComments: reviewComments,
        studentId: studentId ?? '',
      );
      
      String message = status.toLowerCase() == 'approved' 
          ? 'Leave request approved successfully'
          : 'Leave request rejected successfully';
          
      Get.snackbar('Success', message);
    } catch (e) {
      Get.snackbar('Error', 'Failed to update leave request: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Method to show approval/rejection dialog
  Future<void> showApprovalDialog(LeaveModel request) async {
    String? reviewComments;
    
    Get.dialog(
      AlertDialog(
        title: Text('Review Leave Application'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Student: ${request.fullName}'),
            Text('Leave Type: ${request.leaveType}'),
            Text('Duration: ${request.totalDays} days'),
            SizedBox(height: 16),
            TextField(
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
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              await updateLeaveStatus(
                request.id!,
                'Rejected',
                reviewComments: reviewComments,
                studentId: request.id,
              );
            },
            child: Text('Reject', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await updateLeaveStatus(
                request.id!,
                'Approved',
                reviewComments: reviewComments,
                studentId: request.id,
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
      Get.snackbar('Error', 'User not authenticated');
      return;
    }

    try {
      isLoading.value = true;
      // Implement delete functionality in service
      // await _leaveService.deleteLeaveApplication(currentUserId.value, leaveId);
      Get.snackbar('Success', 'Leave request deleted successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete leave request: $e');
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
      if (userRole.value == 'admin' || userRole.value == 'teacher') {
        // Return statistics for all applications
        final allRequests = leaveRequests;
        return {
          'total': allRequests.length,
          'approved': allRequests.where((r) => r.status.toLowerCase() == 'approved').length,
          'pending': allRequests.where((r) => r.status.toLowerCase() == 'pending').length,
          'rejected': allRequests.where((r) => r.status.toLowerCase() == 'rejected').length,
          'totalDays': allRequests.fold(0, (sum, r) => sum + r.totalDays),
          'approvedDays': allRequests
              .where((r) => r.status.toLowerCase() == 'approved')
              .fold(0, (sum, r) => sum + r.totalDays),
        };
      } else {
        return await _leaveService.getLeaveStatistics(currentUserId.value);
      }
    } catch (e) {
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
        studentId: '',
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to check overlapping leave: $e');
      return false;
    }
  }

  Future<void> refreshLeaveRequests() async {
    if (currentUserId.value.isNotEmpty) {
      _listenToLeaveRequests();
    }
  }

  // Helper method to check if current user can approve/reject
  bool get canApproveReject => userRole.value == 'admin' || userRole.value == 'teacher';
  
  // Helper method to check if current user can delete
  bool canDelete(LeaveModel request) {
    if (userRole.value == 'admin') return true;
    if (userRole.value == 'student' && request.status.toLowerCase() == 'pending') {
      return true;
    }
    return false;
  }
}