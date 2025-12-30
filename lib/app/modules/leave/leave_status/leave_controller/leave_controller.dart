// controllers/leave_controller.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digislips/app/modules/leave/leave_model/leave_model.dart';
import 'package:digislips/app/modules/leave/leave_service/leave_service.dart';
import 'package:digislips/app/shared/widgets/Custom_Snackbar/Custom_Snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LeaveController extends GetxController {
  final LeaveService _leaveService = LeaveService();
  final RxList<LeaveModel> leaveRequests = <LeaveModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString selectedFilter = 'All'.obs;
  final RxString currentUserId = ''.obs;
  final RxString userRole = ''.obs; // 'student', 'admin', 'teacher', 'parent'

  // Add a StreamSubscription to properly manage the listener
  StreamSubscription<List<LeaveModel>>? _leaveSubscription;

  // Store dual approval data separately (using Firestore custom fields)
  final RxMap<String, Map<String, dynamic>> dualApprovalData =
      <String, Map<String, dynamic>>{}.obs;

  // Map to hold per-leave Firestore listeners for dual approval data
  final Map<String, StreamSubscription<DocumentSnapshot>>
  _dualApprovalSubscriptions = {};

  @override
  void onInit() {
    super.onInit();
    _initializeUser();
  }

  @override
  void onClose() {
    // Cancel the subscription when controller is disposed
    _leaveSubscription?.cancel();
    // Cancel all dual approval listeners
    _cancelAllDualApprovalListeners();
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
      CustomSnackbar.showError('Error', 'Failed to initialize user: $e');
    }
  }

  void _listenToLeaveRequests() {
    if (currentUserId.value.isEmpty) return;

    print('🔍 Listening to leave requests for role: ${userRole.value}');

    // Cancel existing subscription before creating a new one
    _leaveSubscription?.cancel();

    // If user is admin/teacher/parent, get all leave applications
    // If user is student, get only their applications
    Stream<List<LeaveModel>> leaveStream;

    if (userRole.value == 'Parent' ||
        userRole.value == 'teacher' ||
        userRole.value == 'admin') {
      print('👨‍💼 Fetching all leave applications for admin/teacher/parent');
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

        // Mark initial load as complete
        _initialLoadComplete.value = true;

        // Load dual approval data for each leave request
        _loadDualApprovalData();

        // Force UI update
        leaveRequests.refresh();
      },
      onError: (error) {
        print('❌ Error fetching leave requests: $error');

        // Mark initial load as complete even on error
        _initialLoadComplete.value = true;

        CustomSnackbar.showError(
          'Error',
          'Failed to fetch leave requests: $error',
        );
      },
    );
  }

  // Load dual approval data from Firestore custom fields (now with real-time listeners)
  Future<void> _loadDualApprovalData() async {
    // Cancel listeners for leave requests that no longer exist
    final currentIds = leaveRequests
        .map((r) => r.id)
        .whereType<String>()
        .toSet();
    final toRemove = _dualApprovalSubscriptions.keys
        .where((id) => !currentIds.contains(id))
        .toList();
    for (final id in toRemove) {
      _dualApprovalSubscriptions[id]?.cancel();
      _dualApprovalSubscriptions.remove(id);
      dualApprovalData.remove(id);
    }

    // Set up listeners for each leave request
    for (var request in leaveRequests) {
      if (request.id != null && request.uid != null) {
        final leaveId = request.id!;
        // If already listening, skip
        if (_dualApprovalSubscriptions.containsKey(leaveId)) continue;

        final sub = FirebaseFirestore.instance
            .collection('students')
            .doc(request.uid!)
            .collection('leave')
            .doc(leaveId)
            .snapshots()
            .listen(
              (doc) {
                if (doc.exists) {
                  final data = doc.data() as Map<String, dynamic>;
                  dualApprovalData[leaveId] = {
                    'parentStatus': data['parentStatus'],
                    'parentReviewedBy': data['parentReviewedBy'],
                    'parentReviewComments': data['parentReviewComments'],
                    'parentReviewedAt': data['parentReviewedAt'],
                    'teacherStatus': data['teacherStatus'],
                    'teacherReviewedBy': data['teacherReviewedBy'],
                    'teacherReviewComments': data['teacherReviewComments'],
                    'teacherReviewedAt': data['teacherReviewedAt'],
                  };
                  dualApprovalData.refresh();
                }
              },
              onError: (e) {
                print(
                  '❌ Error listening to dual approval data for $leaveId: $e',
                );
              },
            );
        _dualApprovalSubscriptions[leaveId] = sub;
      }
    }
  }

  void _cancelAllDualApprovalListeners() {
    for (final sub in _dualApprovalSubscriptions.values) {
      sub.cancel();
    }
    _dualApprovalSubscriptions.clear();
  }

  List<LeaveModel> get filteredRequests {
    // Return empty list immediately on first load to show loading state instead of empty state
    // This is determined by checking if isLoading is true OR if leaveRequests is empty AND we just initialized
    List<LeaveModel> filtered = leaveRequests;

    // Apply status filter
    if (selectedFilter.value != 'All') {
      filtered = filtered
          .where(
            (request) =>
                _getFinalStatus(request).toLowerCase() ==
                selectedFilter.value.toLowerCase(),
          )
          .toList();
    }

    return filtered;
  }

  // Track if initial load is complete
  final RxBool _initialLoadComplete = false.obs;

  // Getter to check if we should show loading state
  bool get shouldShowLoading {
    // Only show loading during initial fetch, not during status updates
    return !_initialLoadComplete.value &&
        leaveRequests.isEmpty &&
        currentUserId.isNotEmpty;
  }

  // Helper method to determine final status based on dual approvals
  String _getFinalStatus(LeaveModel request) {
    if (request.id == null) return request.status;

    final approvalData = dualApprovalData[request.id!];
    if (approvalData == null) return request.status;

    final parentStatus = approvalData['parentStatus'] as String?;
    final teacherStatus = approvalData['teacherStatus'] as String?;

    // If both have approved
    if (parentStatus?.toLowerCase() == 'approved' &&
        teacherStatus?.toLowerCase() == 'approved') {
      return 'Approved';
    }

    // If either has rejected
    if (parentStatus?.toLowerCase() == 'rejected' ||
        teacherStatus?.toLowerCase() == 'rejected') {
      return 'Rejected';
    }

    // If one has approved but other is still pending
    if ((parentStatus?.toLowerCase() == 'approved' && teacherStatus == null) ||
        (teacherStatus?.toLowerCase() == 'approved' && parentStatus == null)) {
      return 'Partially Approved';
    }

    // Default to pending or original status
    return request.status;
  }

  // Helper method to get review status display text
  String getReviewStatusText(LeaveModel request) {
    if (request.id == null) return 'Status: ${request.status}';

    final approvalData = dualApprovalData[request.id!];
    if (approvalData == null) return 'Status: ${request.status}';

    final parentStatus = approvalData['parentStatus'] as String?;
    final teacherStatus = approvalData['teacherStatus'] as String?;
    final parentReviewedBy = approvalData['parentReviewedBy'] as String?;
    final teacherReviewedBy = approvalData['teacherReviewedBy'] as String?;

    List<String> statusParts = [];

    if (parentStatus != null && parentReviewedBy != null) {
      statusParts.add('Parent: $parentStatus by $parentReviewedBy');
    } else {
      statusParts.add('Parent: Pending');
    }

    if (teacherStatus != null && teacherReviewedBy != null) {
      statusParts.add('Teacher: $teacherStatus by $teacherReviewedBy');
    } else {
      statusParts.add('Teacher: Pending');
    }

    return statusParts.join(' | ');
  }

  // Updated method to handle approval/rejection with dual approval system
  Future<void> updateLeaveStatus(
    String leaveId,
    String status, {
    String? reviewComments,
    String? studentId,
  }) async {
    if (currentUserId.value.isEmpty) {
      print('❌ User not authenticated');
      CustomSnackbar.showError('Error', 'User not authenticated');

      return;
    }

    // Find the leave request to get the correct student ID
    final leaveRequest = leaveRequests.firstWhereOrNull(
      (leave) => leave.id == leaveId,
    );
    if (leaveRequest == null) {
      print('❌ Leave request not found with ID: $leaveId');
      CustomSnackbar.showError('Error', 'Leave request not found');

      return;
    }

    // Use the student ID from the leave request (uid field)
    final actualStudentId = leaveRequest.uid ?? studentId;
    if (actualStudentId == null || actualStudentId.isEmpty) {
      print('❌ Student ID not found for leave request: $leaveId');
      CustomSnackbar.showError('Error', 'Student ID not found');

      return;
    }

    try {
      isLoading.value = true;
      print('🔄 Starting leave status update...');
      print('📋 Leave ID: $leaveId');
      print('👤 Student ID: $actualStudentId');
      print('📊 New Status: $status');
      print('👥 User Role: ${userRole.value}');

      // Get current user name from preferences for reviewedBy field
      final prefs = await SharedPreferences.getInstance();
      final reviewerName =
          prefs.getString('userName') ??
          (userRole.value == 'Parent' ? 'Parent' : 'Teacher');

      // Get current approval data
      final currentApprovalData = dualApprovalData[leaveId] ?? {};

      // Update role-specific approval data
      Map<String, dynamic> updateFields = {};

      if (userRole.value.toLowerCase() == 'parent') {
        updateFields = {
          'parentStatus': status,
          'parentReviewedBy': reviewerName,
          'parentReviewedAt': FieldValue.serverTimestamp(),
          'parentReviewComments': reviewComments,
        };

        // Update local data
        currentApprovalData['parentStatus'] = status;
        currentApprovalData['parentReviewedBy'] = reviewerName;
        currentApprovalData['parentReviewComments'] = reviewComments;
        currentApprovalData['parentReviewedAt'] = DateTime.now();
      } else if (userRole.value.toLowerCase() == 'teacher') {
        updateFields = {
          'teacherStatus': status,
          'teacherReviewedBy': reviewerName,
          'teacherReviewedAt': FieldValue.serverTimestamp(),
          'teacherReviewComments': reviewComments,
        };

        // Update local data
        currentApprovalData['teacherStatus'] = status;
        currentApprovalData['teacherReviewedBy'] = reviewerName;
        currentApprovalData['teacherReviewComments'] = reviewComments;
        currentApprovalData['teacherReviewedAt'] = DateTime.now();
      }

      // Calculate final status
      String finalStatus = _calculateFinalStatus(currentApprovalData);

      // Add final status to update fields
      updateFields['status'] = finalStatus;
      updateFields['reviewedAt'] = FieldValue.serverTimestamp();

      // Set reviewedBy based on final status
      if (finalStatus == 'Approved' || finalStatus == 'Rejected') {
        updateFields['reviewedBy'] = 'Parent & Teacher';
        updateFields['reviewComments'] = reviewComments;
      } else {
        updateFields['reviewedBy'] = reviewerName;
        updateFields['reviewComments'] = reviewComments;
      }

      // Update Firestore with both role-specific and main fields
      await _writeLeaveUpdateWithRetry(actualStudentId, leaveId, updateFields);

      // Update local dual approval data
      dualApprovalData[leaveId] = currentApprovalData;
      dualApprovalData.refresh();

      // Update the main leave request status in local state using assignAll for proper GetX reactivity
      final index = leaveRequests.indexWhere((r) => r.id == leaveId);
      if (index != -1) {
        leaveRequests[index] = LeaveModel(
          id: leaveRequests[index].id,
          leaveType: leaveRequests[index].leaveType,
          fromDate: leaveRequests[index].fromDate,
          toDate: leaveRequests[index].toDate,
          totalDays: leaveRequests[index].totalDays,
          reason: leaveRequests[index].reason,
          destination: leaveRequests[index].destination,
          travelMode: leaveRequests[index].travelMode,
          documentUrls: leaveRequests[index].documentUrls,
          status: finalStatus,
          submittedAt: leaveRequests[index].submittedAt,
          submittedBy: leaveRequests[index].submittedBy,
          reviewedBy: updateFields['reviewedBy'] as String?,
          reviewedAt: DateTime.now(),
          reviewComments: updateFields['reviewComments'] as String?,
          uid: leaveRequests[index].uid,
          fullName: leaveRequests[index].fullName,
          email: leaveRequests[index].email,
          phone: leaveRequests[index].phone,
          parentEmail: leaveRequests[index].parentEmail,
          parentPhone: leaveRequests[index].parentPhone,
          rollNumber: leaveRequests[index].rollNumber,
          department: leaveRequests[index].department,
          semester: leaveRequests[index].semester,
          profileImageUrl: leaveRequests[index].profileImageUrl,
          isEmailVerified: leaveRequests[index].isEmailVerified,
          profileComplete: leaveRequests[index].profileComplete,
          createdAt: leaveRequests[index].createdAt,
          updatedAt: DateTime.now(),
        );

        // Ensure RxList notifies listeners
        leaveRequests.refresh();
      }

      // Force GetX to notify listeners
      update();

      print('✅ Leave status updated successfully');

      // Show success message (fire and forget - don't await)
      String message = _getSuccessMessage(finalStatus, status);
      CustomSnackbar.showSuccess('Success', message);
    } catch (e) {
      print('❌ Failed to update leave status: $e');

      CustomSnackbar.showError('Error', 'Failed to update leave request: $e');

      // Refresh data from server in case of error
      await refreshLeaveRequests();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _writeLeaveUpdateWithRetry(
    String studentId,
    String leaveId,
    Map<String, dynamic> updateFields,
  ) async {
    // Use Firestore's built-in offline persistence - writes are cached locally
    // and synced when connection is available. No need for manual timeout.
    await FirebaseFirestore.instance
        .collection('students')
        .doc(studentId)
        .collection('leave')
        .doc(leaveId)
        .update(updateFields);
  }

  // Helper method to calculate final status from approval data
  String _calculateFinalStatus(Map<String, dynamic> approvalData) {
    final parentStatus = approvalData['parentStatus'] as String?;
    final teacherStatus = approvalData['teacherStatus'] as String?;

    // If both have approved
    if (parentStatus?.toLowerCase() == 'approved' &&
        teacherStatus?.toLowerCase() == 'approved') {
      return 'Approved';
    }

    // If either has rejected
    if (parentStatus?.toLowerCase() == 'rejected' ||
        teacherStatus?.toLowerCase() == 'rejected') {
      return 'Rejected';
    }

    // If one has approved but other is still pending
    if ((parentStatus?.toLowerCase() == 'approved' && teacherStatus == null) ||
        (teacherStatus?.toLowerCase() == 'approved' && parentStatus == null)) {
      return 'Partially Approved';
    }

    // Default to pending
    return 'Pending';
  }

  // Helper method to get success message
  String _getSuccessMessage(String finalStatus, String userAction) {
    if (finalStatus == 'Approved') {
      return 'Leave request approved by both Parent and Teacher';
    } else if (finalStatus == 'Rejected1') {
      return 'Leave request rejected';
    } else if (finalStatus == 'Partially Approved') {
      return 'Leave request ${userAction.toLowerCase()} by ${userRole.value}. Waiting for other approval.';
    } else {
      return 'Leave request ${userAction.toLowerCase()} by ${userRole.value}';
    }
  }

  // Method to show approval/rejection dialog
  Future<void> showApprovalDialog(LeaveModel request) async {
    final TextEditingController commentsController = TextEditingController();

    bool hasAlreadyReviewed = false;
    String? existingStatus;

    if (request.id != null) {
      final approvalData = dualApprovalData[request.id!];
      if (approvalData != null) {
        if (userRole.value.toLowerCase() == 'parent' &&
            approvalData['parentStatus'] != null) {
          hasAlreadyReviewed = true;
          existingStatus = approvalData['parentStatus'] as String?;
        } else if (userRole.value.toLowerCase() == 'teacher' &&
            approvalData['teacherStatus'] != null) {
          hasAlreadyReviewed = true;
          existingStatus = approvalData['teacherStatus'] as String?;
        }
      }
    }

    Future<void> handleDecision(String targetStatus) async {
      final comment = commentsController.text.trim();

      // Close dialog first
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      // Wait for dialog to fully close before updating
      await Future.delayed(const Duration(milliseconds: 150));

      try {
        await updateLeaveStatus(
          request.id!,
          targetStatus,
          reviewComments: comment.isEmpty ? null : comment,
          studentId: request.uid,
        );
      } catch (e) {
        // Errors are already surfaced via snackbar; this catch prevents crashes.
        debugPrint('handleDecision error: $e');
      }
    }

    Get.dialog(
      Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        backgroundColor: Colors.transparent,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              decoration: BoxDecoration(
                color: Color(0xFFF0F0F3),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF000000).withOpacity(0.1),
                    blurRadius: 30,
                    offset: Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Color(0xFFFFFFFF).withOpacity(0.5),
                    blurRadius: 20,
                    offset: Offset(-5, -5),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF000000).withOpacity(0.05),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Review Leave Application',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2D3142),
                              letterSpacing: -0.3,
                            ),
                          ),
                          SizedBox(height: 2),
                          Container(
                            width: 35,
                            height: 3,
                            decoration: BoxDecoration(
                              color: Color(0xFF4A9EFF),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                    // Data Container with 2-column compact layout
                    Flexible(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF000000).withOpacity(0.05),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.all(14),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Row 1: Student Name & Roll Number (2-column)
                              Row(
                                children: [
                                  _buildCompactDataField(
                                    'Student Name',
                                    request.fullName.toString(),
                                  ),
                                  SizedBox(width: 12),
                                  _buildCompactDataField(
                                    'Roll Number',
                                    request.rollNumber.toString(),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              Divider(height: 1, color: Color(0xFFEEEEEE)),
                              SizedBox(height: 12),
                              // Row 2: Leave Type & Duration (2-column)
                              Row(
                                children: [
                                  _buildCompactDataField(
                                    'Leave Type',
                                    request.leaveType,
                                  ),
                                  SizedBox(width: 12),
                                  _buildCompactDataField(
                                    'Duration',
                                    '${request.totalDays} days',
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              Divider(height: 1, color: Color(0xFFEEEEEE)),
                              SizedBox(height: 12),
                              // Row 3: Reason (Full width)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Reason',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFFA0A3B1),
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    request.reason,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF2D3142),
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              Divider(height: 1, color: Color(0xFFEEEEEE)),
                              SizedBox(height: 12),
                              // Row 4: Status (Full width)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Status',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFFA0A3B1),
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    getReviewStatusText(request),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF2D3142),
                                    ),
                                  ),
                                ],
                              ),
                              // Already Reviewed Banner
                              if (hasAlreadyReviewed) ...[
                                SizedBox(height: 12),
                                Divider(height: 1, color: Color(0xFFEEEEEE)),
                                SizedBox(height: 12),
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFFFFF8E1),
                                        Color(0xFFFFE0B2),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  padding: EdgeInsets.all(10),
                                  child: Row(
                                    children: [
                                      Text(
                                        '⚠️',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Already Reviewed',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFFE65100),
                                              ),
                                            ),
                                            Text(
                                              'You have already reviewed this request. Your previous decision: $existingStatus',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFFBF360C),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              // Comments Field
                              SizedBox(height: 12),
                              Divider(height: 1, color: Color(0xFFEEEEEE)),
                              SizedBox(height: 12),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Color(0xFFFAFAFC),
                                  border: Border.all(
                                    color: Color(0xFFEEEEEE),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(
                                        0xFF000000,
                                      ).withOpacity(0.05),
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                padding: EdgeInsets.all(12),
                                child: TextField(
                                  controller: commentsController,
                                  maxLines: 2,
                                  style: TextStyle(
                                    color: Color(0xFF2D3142),
                                    fontSize: 13,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Comments (Optional)',
                                    labelStyle: TextStyle(
                                      color: Color(0xFFA0A3B1),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    border: InputBorder.none,
                                    hintText: 'Add comments if needed...',
                                    hintStyle: TextStyle(
                                      color: Color(0xFFD0D3DB),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 14),
                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildNeumoButton(
                          label: 'Cancel',
                          onPressed: () {
                            print('❌ Approval dialog cancelled');
                            if (Get.isDialogOpen ?? false) {
                              Get.back();
                            }
                          },
                          isPrimary: false,
                          isCompact: true,
                        ),
                        SizedBox(width: 6),
                        _buildNeumoButton(
                          label: 'Reject',
                          icon: '✕',
                          onPressed: () => handleDecision('Rejected'),
                          isDestructive: true,
                          isCompact: true,
                        ),
                        SizedBox(width: 6),
                        _buildNeumoButton(
                          label: 'Approve',
                          icon: '✓',
                          onPressed: () => handleDecision('Approved'),
                          isPrimary: true,
                          isCompact: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> deleteLeaveRequest(String leaveId) async {
    if (currentUserId.value.isEmpty) {
      print('❌ User not authenticated for delete operation');

      CustomSnackbar.showError('Error', 'User not authenticated');
      return;
    }

    try {
      isLoading.value = true;
      print('🗑️ Deleting leave request: $leaveId');
      // Implement delete functionality in service
      // await _leaveService.deleteLeaveApplication(currentUserId.value, leaveId);

      // Remove from dual approval data
      dualApprovalData.remove(leaveId);

      // Optimistically remove from local state
      leaveRequests.removeWhere((request) => request.id == leaveId);
      leaveRequests.refresh();
      CustomSnackbar.showSuccess(
        'Success',
        'Leave request deleted successfully',
      );
    } catch (e) {
      print('❌ Failed to delete leave request: $e');
      CustomSnackbar.showError('Error', 'Failed to delete leave request $e');

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
        'partiallyApproved': 0,
        'totalDays': 0,
        'approvedDays': 0,
      };
    }

    try {
      if (userRole.value == 'Parent' ||
          userRole.value == 'teacher' ||
          userRole.value == 'admin') {
        // Return statistics for all applications
        final allRequests = leaveRequests;
        print('📊 Calculating statistics for ${allRequests.length} requests');

        int approved = 0;
        int pending = 0;
        int rejected = 0;
        int partiallyApproved = 0;
        int approvedDays = 0;

        for (var request in allRequests) {
          final finalStatus = _getFinalStatus(request);
          switch (finalStatus.toLowerCase()) {
            case 'approved':
              approved++;
              approvedDays += request.totalDays;
              break;
            case 'rejected':
              rejected++;
              break;
            case 'partially approved':
              partiallyApproved++;
              break;
            default:
              pending++;
          }
        }

        return {
          'total': allRequests.length,
          'approved': approved,
          'pending': pending,
          'rejected': rejected,
          'partiallyApproved': partiallyApproved,
          'totalDays': allRequests.fold(0, (sum, r) => sum + r.totalDays),
          'approvedDays': approvedDays,
        };
      } else {
        return await _leaveService.getLeaveStatistics(currentUserId.value);
      }
    } catch (e) {
      print('❌ Failed to get leave statistics: $e');

      CustomSnackbar.showError('Error', 'Failed to get leave statistics: $e');
      return {
        'total': 0,
        'approved': 0,
        'pending': 0,
        'rejected': 0,
        'partiallyApproved': 0,
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
      CustomSnackbar.showError(
        'Error',
        'Failed to check overlapping leave: $e',
      );
      ;
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
      userRole.value.toLowerCase() == 'admin' ||
      userRole.value.toLowerCase() == 'teacher' ||
      userRole.value.toLowerCase() == 'parent';

  // Helper method to check if current user can delete
  bool canDelete(LeaveModel request) {
    if (userRole.value.toLowerCase() == 'admin') return true;
    if (userRole.value.toLowerCase() == 'student' &&
        _getFinalStatus(request).toLowerCase() == 'pending') {
      return true;
    }
    return false;
  }

  // Helper method to check if user has already reviewed
  bool hasUserAlreadyReviewed(LeaveModel request) {
    if (request.id == null) return false;

    final approvalData = dualApprovalData[request.id!];
    if (approvalData == null) return false;

    if (userRole.value.toLowerCase() == 'parent') {
      return approvalData['parentStatus'] != null;
    } else if (userRole.value.toLowerCase() == 'teacher') {
      return approvalData['teacherStatus'] != null;
    }
    return false;
  }

  // Helper method to get user's review status for a request
  String? getUserReviewStatus(LeaveModel request) {
    if (request.id == null) return null;

    final approvalData = dualApprovalData[request.id!];
    if (approvalData == null) return null;

    if (userRole.value.toLowerCase() == 'parent') {
      return approvalData['parentStatus'] as String?;
    } else if (userRole.value.toLowerCase() == 'teacher') {
      return approvalData['teacherStatus'] as String?;
    }
    return null;
  }

  // Neumorphic Button Builder with Compact Support
  Widget _buildNeumoButton({
    required String label,
    required VoidCallback onPressed,
    String? icon,
    bool isPrimary = false,
    bool isDestructive = false,
    bool isCompact = false,
  }) {
    Color bgColor;
    Color textColor;
    List<BoxShadow> shadows;

    if (isDestructive) {
      bgColor = Color(0xFFFFF5F5);
      textColor = Color(0xFFE74C3C);
      shadows = [
        BoxShadow(
          color: Color(0xFFE74C3C).withOpacity(0.15),
          blurRadius: 15,
          offset: Offset(0, 6),
        ),
      ];
    } else if (isPrimary) {
      bgColor = Color(0xFF4A9EFF);
      textColor = Colors.white;
      shadows = [
        BoxShadow(
          color: Color(0xFF4A9EFF).withOpacity(0.3),
          blurRadius: 20,
          offset: Offset(0, 8),
        ),
      ];
    } else {
      bgColor = Colors.white;
      textColor = Color(0xFF2D3142);
      shadows = [
        BoxShadow(
          color: Color(0xFF000000).withOpacity(0.08),
          blurRadius: 15,
          offset: Offset(0, 4),
        ),
      ];
    }

    final horizontalPadding = isCompact ? 14.0 : 20.0;
    final verticalPadding = isCompact ? 8.0 : 12.0;
    final fontSize = isCompact ? 12.0 : 14.0;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: shadows,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Text(icon, style: TextStyle(fontSize: isCompact ? 14 : 16)),
              SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Compact Data Field Builder for 2-column layout
  Widget _buildCompactDataField(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Color(0xFFA0A3B1),
              letterSpacing: 0.2,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3142),
            ),
          ),
        ],
      ),
    );
  }
}
