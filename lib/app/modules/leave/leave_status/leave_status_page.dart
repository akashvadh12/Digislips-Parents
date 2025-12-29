// screens/leave_requests_screen.dart
import 'package:digislips/app/core/theme/app_colors.dart';
import 'package:digislips/app/core/theme/app_text_styles.dart';
import 'package:digislips/app/modules/leave/leave_model/leave_model.dart';
import 'package:digislips/app/modules/leave/leave_status/leave_controller/leave_controller.dart';
import 'package:digislips/app/modules/leave/leave_status/leave_request_card/leave_request_card.dart';
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
              // Enhanced Custom App Bar with Gradient
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(10, 16, 10, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Back Button
                        IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          iconSize: 20,
                          icon: const Icon(Icons.arrow_back_ios_new_rounded),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(8),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Obx(
                                () => Text(
                                  leaveController.canApproveReject
                                      ? 'Leave Applications'
                                      : 'My Leave Requests',
                                  style: AppTextStyles.welcomeTitle.copyWith(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Obx(
                                () => Text(
                                  '${leaveController.filteredRequests.length} ${leaveController.filteredRequests.length == 1 ? 'application' : 'applications'}',
                                  style: AppTextStyles.welcomeTitle.copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Add notification or action icon
                      ],
                    ),
                  ],
                ),
              ),

              // Enhanced Filter Chips with better spacing
              Container(
                color: AppColors.primary,
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children:
                        [
                              'All',
                              'Pending',
                              'Partially Approved',
                              'Approved',
                              'Rejected',
                            ]
                            .map(
                              (filter) => _buildEnhancedFilterChip(
                                filter,
                                leaveController,
                              ),
                            )
                            .toList(),
                  ),
                ),
              ),

              // Enhanced Main Content Area
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Content indicator
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Obx(() {
                            // Check if we should show loading state
                            if (leaveController.shouldShowLoading) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(
                                      color: AppColors.primary,
                                      strokeWidth: 3,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Loading applications...',
                                      style: AppTextStyles.body.copyWith(
                                        color: AppColors.greyColor,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            final filteredRequests =
                                leaveController.filteredRequests;

                            if (filteredRequests.isEmpty) {
                              return _buildEnhancedEmptyState(leaveController);
                            }

                            return RefreshIndicator(
                              onRefresh: () async {
                                await leaveController.refreshLeaveRequests();
                              },
                              color: AppColors.primary,
                              child: ListView.builder(
                                itemCount: filteredRequests.length,
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                itemBuilder: (context, index) {
                                  final request = filteredRequests[index];
                                  return AnimatedContainer(
                                    duration: Duration(
                                      milliseconds: 300 + (index * 50),
                                    ),
                                    curve: Curves.easeOutBack,
                                    child: LeaveRequestCard(
                                      leaveRequest: request,
                                      showStudentInfo:
                                          leaveController.canApproveReject,
                                      onTap: () =>
                                          _showEnhancedLeaveDetailDialog(
                                            context,
                                            request,
                                            leaveController,
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
                                    ),
                                  );
                                },
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedFilterChip(
    String filter,
    LeaveController leaveController,
  ) {
    return Obx(() {
      final isSelected = leaveController.selectedFilter.value == filter;
      return Container(
        margin: const EdgeInsets.only(right: 12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => leaveController.selectedFilter.value = filter,
            borderRadius: BorderRadius.circular(25),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white
                    : Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected) ...[
                    Icon(
                      _getFilterIcon(filter),
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    filter,
                    style: TextStyle(
                      color: isSelected ? AppColors.primary : Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildEnhancedStatCard(
    String title,
    String count,
    Color color,
    IconData icon,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              Text(
                count,
                style: AppTextStyles.title.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.blackColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.greyColor,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedEmptyState(LeaveController leaveController) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withOpacity(0.1),
                  AppColors.primary.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              Icons.description_outlined,
              size: 64,
              color: AppColors.primary.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            leaveController.selectedFilter.value == 'All'
                ? 'No applications found'
                : 'No ${leaveController.selectedFilter.value.toLowerCase()} applications',
            style: AppTextStyles.title.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            leaveController.canApproveReject
                ? 'Leave applications will appear here once submitted'
                : 'Leave applications will appear here once submitted',
            style: AppTextStyles.body.copyWith(color: AppColors.greyColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showEnhancedLeaveDetailDialog(
    BuildContext context,
    LeaveModel request,
    leaveController,
  ) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Professional Header with Status Badge
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _getStatusColor(request.status).withOpacity(0.08),
                      _getStatusColor(request.status).withOpacity(0.03),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Leave Type Icon
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              request.status,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _getStatusColor(
                                request.status,
                              ).withOpacity(0.2),
                            ),
                          ),
                          child: Icon(
                            _getLeaveTypeIcon(request.leaveType),
                            color: _getStatusColor(request.status),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Title and Status
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Leave Application',
                                style: AppTextStyles.title.copyWith(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.blackColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(request.status),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _getStatusColor(
                                            request.status,
                                          ).withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      request.status.toUpperCase(),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    request.leaveType,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.greyColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Close Button
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.grey.shade100,
                            foregroundColor: AppColors.greyColor,
                            padding: const EdgeInsets.all(8),
                          ),
                        ),
                      ],
                    ),

                    // Duration Summary Card
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${dateFormat.format(request.fromDate)} - ${dateFormat.format(request.toDate)}',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.blackColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${request.totalDays} ${request.totalDays == 1 ? 'day' : 'days'} leave',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.greyColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Student Information (if applicable)
                      if (leaveController.canApproveReject)
                        _buildProfessionalDetailSection(
                          'Student Information',
                          Icons.person_rounded,
                          AppColors.primary,
                          [
                            if (request.fullName != null &&
                                request.fullName!.isNotEmpty)
                              _buildProfessionalDetailRow(
                                'Full Name',
                                request.fullName!,
                              ),
                            if (request.rollNumber != null &&
                                request.rollNumber!.isNotEmpty)
                              _buildProfessionalDetailRow(
                                'Roll Number',
                                request.rollNumber!,
                              ),
                            if (request.department != null &&
                                request.department!.isNotEmpty)
                              _buildProfessionalDetailRow(
                                'Department',
                                request.department!,
                              ),
                            if (request.semester != null &&
                                request.semester!.isNotEmpty)
                              _buildProfessionalDetailRow(
                                'Semester',
                                request.semester!,
                              ),
                          ],
                        ),

                      // Leave Details
                      _buildProfessionalDetailSection(
                        'Leave Details',
                        Icons.event_note_rounded,
                        AppColors.success,
                        [
                          _buildProfessionalDetailRow(
                            'Leave Type',
                            request.leaveType,
                          ),
                          _buildProfessionalDetailRow(
                            'Duration',
                            '${request.totalDays} ${request.totalDays == 1 ? 'day' : 'days'}',
                          ),
                          _buildProfessionalDetailRow(
                            'From Date',
                            dateFormat.format(request.fromDate),
                          ),
                          _buildProfessionalDetailRow(
                            'To Date',
                            dateFormat.format(request.toDate),
                          ),
                          if (request.reason.isNotEmpty)
                            _buildProfessionalDetailRow(
                              'Reason',
                              request.reason,
                            ),
                          if (request.destination.isNotEmpty)
                            _buildProfessionalDetailRow(
                              'Destination',
                              request.destination,
                            ),
                          if (request.travelMode.isNotEmpty)
                            _buildProfessionalDetailRow(
                              'Travel Mode',
                              request.travelMode,
                            ),
                        ],
                      ),

                      // Contact Information
                      if ((request.email != null &&
                              request.email!.isNotEmpty) ||
                          (request.phone != null &&
                              request.phone!.isNotEmpty) ||
                          (request.parentEmail != null &&
                              request.parentEmail!.isNotEmpty) ||
                          (request.parentPhone != null &&
                              request.parentPhone!.isNotEmpty))
                        _buildProfessionalDetailSection(
                          'Contact Information',
                          Icons.contact_phone_rounded,
                          AppColors.warning,
                          [
                            if (request.email != null &&
                                request.email!.isNotEmpty)
                              _buildProfessionalDetailRow(
                                'Email',
                                request.email!,
                              ),
                            if (request.phone != null &&
                                request.phone!.isNotEmpty)
                              _buildProfessionalDetailRow(
                                'Phone',
                                request.phone!,
                              ),
                            if (request.parentEmail != null &&
                                request.parentEmail!.isNotEmpty)
                              _buildProfessionalDetailRow(
                                'Parent Email',
                                request.parentEmail!,
                              ),
                            if (request.parentPhone != null &&
                                request.parentPhone!.isNotEmpty)
                              _buildProfessionalDetailRow(
                                'Parent Phone',
                                request.parentPhone!,
                              ),
                          ],
                        ),

                      // Application Status
                      _buildProfessionalDetailSection(
                        'Application Status',
                        Icons.assignment_turned_in_rounded,
                        _getStatusColor(request.status),
                        [
                          _buildProfessionalDetailRow(
                            'Status',
                            request.status.toUpperCase(),
                          ),
                          _buildProfessionalDetailRow(
                            'Submitted On',
                            dateFormat.format(request.submittedAt),
                          ),
                          if (request.submittedBy.isNotEmpty)
                            _buildProfessionalDetailRow(
                              'Submitted By',
                              request.fullName ?? request.submittedBy,
                            ),
                          if (request.reviewedBy != null &&
                              request.reviewedBy!.isNotEmpty)
                            _buildProfessionalDetailRow(
                              'Reviewed By',
                              request.reviewedBy!,
                            ),
                          if (request.reviewedAt != null)
                            _buildProfessionalDetailRow(
                              'Reviewed On',
                              dateFormat.format(request.reviewedAt!),
                            ),
                          if (request.reviewComments != null &&
                              request.reviewComments!.isNotEmpty)
                            _buildProfessionalDetailRow(
                              'Review Comments',
                              request.reviewComments!,
                            ),
                        ],
                      ),

                      // Documents (if any)
                      if (request.documentUrls.isNotEmpty)
                        _buildProfessionalDetailSection(
                          'Attachments',
                          Icons.attach_file_rounded,
                          AppColors.primary,
                          [
                            _buildProfessionalDetailRow(
                              'Documents',
                              '${request.documentUrls.length} ${request.documentUrls.length == 1 ? 'document' : 'documents'} attached',
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),

              // Action Footer - Keep original button functionality
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        leaveController.showApprovalDialog(request);
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text("Approve/Reject"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfessionalDetailSection(
    String title,
    IconData icon,
    Color color,
    List<Widget> children,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: AppTextStyles.title.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.blackColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Section Content
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.greyColor,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.body.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.blackColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedDetailSection(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.title.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.greyColor,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.body.copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getFilterIcon(String filter) {
    switch (filter.toLowerCase()) {
      case 'pending':
        return Icons.schedule_rounded;
      case 'approved':
        return Icons.check_circle_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      default:
        return Icons.list_rounded;
    }
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
        return Icons.medical_services_rounded;
      case 'vacation leave':
        return Icons.beach_access_rounded;
      case 'personal leave':
        return Icons.person_rounded;
      case 'family emergency':
        return Icons.family_restroom_rounded;
      case 'medical leave':
        return Icons.local_hospital_rounded;
      default:
        return Icons.event_note_rounded;
    }
  }
}
