// screens/leave_requests_screen.dart
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
  const LeaveRequestsScreen({Key? key}) : super(key: key);

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
                        Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Row(
                            children: [
                              Text(
                                'Leave Requests',
                                style: AppTextStyles.welcomeTitle,
                              ),
                              const SizedBox(width: 4),
                              Obx(
                                () => Text(
                                  '${leaveController.filteredRequests.length} ${leaveController.filteredRequests.length == 1 ? 'request' : 'requests'}',
                                  style: AppTextStyles.welcomeTitle,
                                ),
                              ),
                            ],
                          ),
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

              // Leave Requests List
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 15),
                  child: Container(
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
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
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
                                            ? 'No leave requests found'
                                            : 'No ${leaveController.selectedFilter.value.toLowerCase()} requests',
                                        style: AppTextStyles.title,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Your leave requests will appear here',
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
                                  padding: const EdgeInsets.only(
                                    top: 8,
                                    bottom: 100,
                                  ),
                                  itemCount: filteredRequests.length,
                                  itemBuilder: (context, index) {
                                    final request = filteredRequests[index];
                                    return LeaveRequestCard(
                                      leaveRequest: request,
                                      onTap: () =>
                                          _showLeaveDetails(context, request),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String count,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor, width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            count,
            style: AppTextStyles.title.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(title, style: AppTextStyles.caption),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filter, LeaveController controller) {
    return Obx(() {
      final isSelected = controller.selectedFilter.value == filter;
      return Container(
        margin: const EdgeInsets.only(right: 8),
        child: FilterChip(
          label: Text(filter),
          selected: isSelected,
          onSelected: (selected) {
            controller.selectedFilter.value = filter;
          },
          backgroundColor: AppColors.cardBackground,
          selectedColor: AppColors.primary.withOpacity(0.1),
          checkmarkColor: AppColors.primary,
          labelStyle: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.greyColor,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isSelected ? AppColors.primary : AppColors.borderColor,
              width: 1,
            ),
          ),
          showCheckmark: false,
        ),
      );
    });
  }

  void _showFilterBottomSheet(
    BuildContext context,
    LeaveController controller,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filter Requests', style: AppTextStyles.title),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                'All',
                'Pending',
                'Approved',
                'Rejected',
              ].map((filter) => _buildFilterChip(filter, controller)).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showLeaveDetails(BuildContext context, LeaveModel request) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.event_note,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(request.leaveType, style: AppTextStyles.title),
                        const SizedBox(height: 4),
                        StatusChip(status: request.status),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildDetailRow(
                'Duration',
                '${request.totalDays} ${request.totalDays == 1 ? 'day' : 'days'}',
              ),
              const SizedBox(height: 16),
              _buildDetailRow(
                'Start Date',
                DateFormat('MMM dd, yyyy').format(request.fromDate),
              ),
              const SizedBox(height: 16),
              _buildDetailRow(
                'End Date',
                DateFormat('MMM dd, yyyy').format(request.toDate),
              ),
              const SizedBox(height: 16),
              _buildDetailRow(
                'Submitted On',
                DateFormat('MMM dd, yyyy').format(request.submittedAt),
              ),
              if (request.reviewedAt != null) ...[
                const SizedBox(height: 16),
                _buildDetailRow(
                  'Reviewed On',
                  DateFormat('MMM dd, yyyy').format(request.reviewedAt!),
                ),
              ],
              if (request.reviewedBy != null) ...[
                const SizedBox(height: 16),
                _buildDetailRow('Reviewed By', request.reviewedBy!),
              ],
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reason',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.greyColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    request.reason,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.blackColor,
                    ),
                  ),
                ],
              ),
              if (request.reviewComments != null &&
                  request.reviewComments!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.status.toLowerCase() == 'rejected'
                          ? 'Rejection Reason'
                          : 'Review Comments',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: request.status.toLowerCase() == 'rejected'
                            ? AppColors.rejectedColor
                            : AppColors.greyColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      request.reviewComments!,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.blackColor,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  if (request.status.toLowerCase() == 'pending') ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          Get.back();
                          final controller = Get.find<LeaveController>();
                          await controller.deleteLeaveRequest(request.id!);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: AppColors.error),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Get.back(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(color: Colors.white),
                      ),
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

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.greyColor,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.body.copyWith(
              color: AppColors.blackColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
