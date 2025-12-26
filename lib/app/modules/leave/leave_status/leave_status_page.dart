import 'package:digislips/app/core/theme/app_colors.dart';
import 'package:digislips/app/core/theme/app_text_styles.dart';
import 'package:digislips/app/modules/leave/leave_status/leave_controller/leave_controller.dart';
import 'package:digislips/app/modules/leave/leave_model/leave_model.dart';
import 'package:digislips/app/modules/leave/leave_status/leave_request_card/leave_request_card.dart';
import 'package:digislips/app/modules/leave/leave_status/leave_status_chip/leave_status_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class LeaveRequestsScreen extends StatelessWidget {
  const LeaveRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final leaveController = Get.put(LeaveController());

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Container(
                color: AppColors.primary,
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                              ),
                              onPressed: () => Navigator.popUntil(
                                context,
                                (route) => route.isFirst,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Obx(
                              () => Text(
                                leaveController.canApproveReject
                                    ? 'Leave Applications'
                                    : 'My Leave Requests',
                                style: AppTextStyles.welcomeTitle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Obx(
                              () => Text(
                                '(${leaveController.filteredRequests.length})',
                                style: AppTextStyles.welcomeTitle.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Filter Chips
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  children: [
                    Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: ['All', 'Pending', 'Approved', 'Rejected']
                            .map(
                              (filter) =>
                                  _buildFilterChip(filter, leaveController),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),

              // Statistics Row (for admin/teacher view)
              Obx(() {
                if (leaveController.canApproveReject) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildQuickStatCard(
                            'Pending',
                            leaveController.leaveRequests
                                .where(
                                  (r) => r.status.toLowerCase() == 'pending',
                                )
                                .length
                                .toString(),
                            AppColors.warning,
                            Icons.pending_actions,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildQuickStatCard(
                            'Approved',
                            leaveController.leaveRequests
                                .where(
                                  (r) => r.status.toLowerCase() == 'approved',
                                )
                                .length
                                .toString(),
                            AppColors.success,
                            Icons.check_circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildQuickStatCard(
                            'Rejected',
                            leaveController.leaveRequests
                                .where(
                                  (r) => r.status.toLowerCase() == 'rejected',
                                )
                                .length
                                .toString(),
                            AppColors.error,
                            Icons.cancel,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),

              // Leave Requests List
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 15),
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: Obx(() {
                            if (leaveController.isLoading.value) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                ),
                              );
                            }

                            final filteredRequests =
                                leaveController.filteredRequests;

                            if (filteredRequests.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Container(
                                        padding: const EdgeInsets.all(24),
                                        decoration: BoxDecoration(
                                          color: AppColors.lightGrey,
                                          borderRadius: BorderRadius.circular(
                                            50,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.inbox_outlined,
                                          size: 48,
                                          color: AppColors.greyColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      leaveController.selectedFilter.value ==
                                              'All'
                                          ? 'No leave applications found'
                                          : 'No ${leaveController.selectedFilter.value.toLowerCase()} applications',
                                      style: AppTextStyles.title,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      leaveController.canApproveReject
                                          ? 'Leave applications will appear here'
                                          : 'Your leave requests will appear here',
                                      style: AppTextStyles.body,
                                    ),
                                  ],
                                ),
                              );
                            }

                            return RefreshIndicator(
                              onRefresh: () async {
                                await leaveController.refreshLeaveRequests();
                              },
                              color: AppColors.primary,
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                itemCount: filteredRequests.length,
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemBuilder: (context, index) {
                                  final request = filteredRequests[index];
                                  return LeaveRequestCard(
                                    leaveRequest: request,
                                    showStudentInfo:
                                        leaveController.canApproveReject,
                                    onTap: () => _showLeaveDetailDialog(
                                      context,
                                      request,
                                    ),
                                    onApprove:
                                        leaveController.canApproveReject &&
                                            request.status.toLowerCase() ==
                                                'pending'
                                        ? () => leaveController
                                              .showApprovalDialog(request)
                                        : null,
                                    onReject:
                                        leaveController.canApproveReject &&
                                            request.status.toLowerCase() ==
                                                'pending'
                                        ? () => leaveController
                                              .showApprovalDialog(request)
                                        : null,
                                  );
                                },
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String filter, LeaveController leaveController) {
    return Obx(() {
      final isSelected = leaveController.selectedFilter.value == filter;
      return Container(
        margin: const EdgeInsets.only(right: 12),
        child: FilterChip(
          label: Text(
            filter,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              leaveController.selectedFilter.value = filter;
            }
          },
          selectedColor: AppColors.approvedColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          showCheckmark: false,
          elevation: 2,
          pressElevation: 4,
        ),
      );
    });
  }

  Widget _buildQuickStatCard(
    String title,
    String count,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 12,
                    color: AppColors.greyColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              count,
              style: AppTextStyles.title.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLeaveDetailDialog(BuildContext context, LeaveModel request) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getStatusColor(request.status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getLeaveTypeIcon(request.leaveType),
                color: _getStatusColor(request.status),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Leave Details',
                    style: AppTextStyles.title.copyWith(fontSize: 18),
                  ),
                  StatusChip(status: request.status),
                ],
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Leave Type', request.leaveType),
              if (request.fullName != null && request.fullName!.isNotEmpty)
                _buildDetailRow('Student Name', request.fullName!),
              if (request.rollNumber != null && request.rollNumber!.isNotEmpty)
                _buildDetailRow('Roll Number', request.rollNumber!),
              if (request.department != null && request.department!.isNotEmpty)
                _buildDetailRow('Department', request.department!),
              if (request.semester != null && request.semester!.isNotEmpty)
                _buildDetailRow('Semester', request.semester!),
              if (request.email != null && request.email!.isNotEmpty)
                _buildDetailRow('Email', request.email!),
              if (request.phone != null && request.phone!.isNotEmpty)
                _buildDetailRow('Phone', request.phone!),
              if (request.parentEmail != null &&
                  request.parentEmail!.isNotEmpty)
                _buildDetailRow('Parent Email', request.parentEmail!),
              if (request.parentPhone != null &&
                  request.parentPhone!.isNotEmpty)
                _buildDetailRow('Parent Phone', request.parentPhone!),
              const Divider(),
              _buildDetailRow(
                'Duration',
                '${request.totalDays} ${request.totalDays == 1 ? 'day' : 'days'}',
              ),
              _buildDetailRow('From Date', dateFormat.format(request.fromDate)),
              _buildDetailRow('To Date', dateFormat.format(request.toDate)),
              if (request.reason.isNotEmpty)
                _buildDetailRow('Reason', request.reason),
              if (request.destination.isNotEmpty)
                _buildDetailRow('Destination', request.destination),
              if (request.travelMode.isNotEmpty)
                _buildDetailRow('Travel Mode', request.travelMode),
              const Divider(),
              _buildDetailRow(
                'Submitted On',
                dateFormat.format(request.submittedAt),
              ),
              if (request.submittedBy.isNotEmpty)
                _buildDetailRow('Submitted By', request.submittedBy),
              if (request.reviewedBy != null && request.reviewedBy!.isNotEmpty)
                _buildDetailRow('Reviewed By', request.reviewedBy!),
              if (request.reviewedAt != null)
                _buildDetailRow(
                  'Reviewed On',
                  dateFormat.format(request.reviewedAt!),
                ),
              if (request.reviewComments != null &&
                  request.reviewComments!.isNotEmpty)
                _buildDetailRow('Review Comments', request.reviewComments!),
              if (request.documentUrls.isNotEmpty)
                _buildDetailRow(
                  'Documents',
                  '${request.documentUrls.length} ${request.documentUrls.length == 1 ? 'document' : 'documents'} attached',
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.greyColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.body),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      case 'pending':
        return AppColors.warning;
      default:
        return AppColors.greyColor;
    }
  }

  IconData _getLeaveTypeIcon(String leaveType) {
    switch (leaveType.toLowerCase()) {
      case 'sick leave':
        return Icons.medical_services;
      case 'vacation leave':
        return Icons.beach_access;
      case 'personal leave':
        return Icons.person;
      case 'family emergency':
        return Icons.family_restroom;
      case 'medical leave':
        return Icons.local_hospital;
      default:
        return Icons.event_note;
    }
  }
}
