import 'package:digislips/app/core/theme/app_colors.dart';
import 'package:digislips/app/core/theme/app_text_styles.dart';
import 'package:digislips/app/modules/leave/leave%20history/leave_history_controller.dart';
import 'package:digislips/app/modules/leave/leave_status/leave_request_card/leave_request_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class LeaveHistoryPage extends GetView<LeaveHistoryController> {
  const LeaveHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar with Gradient
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
                              Text(
                                'Leave History',
                                style: AppTextStyles.welcomeTitle.copyWith(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Obx(
                                () => Text(
                                  '${controller.leaveRequests.length} ${controller.leaveRequests.length == 1 ? 'application' : 'applications'}',
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
                      ],
                    ),
                  ],
                ),
              ),

              // Filter Chips
              Container(
                color: AppColors.primary,
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    // Search Bar - Only show for teachers and admins
                    Obx(() {
                      final isParent = controller.userRole.value == 'Parent';
                      if (isParent) return SizedBox.shrink();

                      return Padding(
                        padding: const EdgeInsets.only(
                          left: 20,
                          right: 20,
                          bottom: 10,
                        ),
                        child: TextField(
                          onChanged: (value) =>
                              controller.setSearchQuery(value),
                          style: TextStyle(color: AppColors.blackColor),
                          decoration: InputDecoration(
                            hintText: 'Search by name...',
                            hintStyle: TextStyle(
                              color: AppColors.greyColor,
                              fontSize: 14,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: AppColors.greyColor,
                              size: 20,
                            ),
                            suffixIcon: Obx(() {
                              if (controller.searchQuery.value.isEmpty) {
                                return SizedBox.shrink();
                              }
                              return IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: AppColors.greyColor,
                                  size: 20,
                                ),
                                onPressed: () {
                                  controller.setSearchQuery('');
                                },
                              );
                            }),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      );
                    }),
                    // Month Filter
                    Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: controller.months
                            .map((month) => _buildFilterChip(month))
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Date Range Picker Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Obx(() {
                              final hasDateRange =
                                  controller.startDate.value != null &&
                                  controller.endDate.value != null;
                              return OutlinedButton.icon(
                                onPressed: () => _showDateRangePicker(context),
                                icon: Icon(
                                  Icons.date_range,
                                  color: hasDateRange
                                      ? AppColors.primary
                                      : Colors.white,
                                  size: 18,
                                ),
                                label: Text(
                                  hasDateRange
                                      ? '${_formatDate(controller.startDate.value!)} - ${_formatDate(controller.endDate.value!)}'
                                      : 'Select Date Range',
                                  style: TextStyle(
                                    color: hasDateRange
                                        ? AppColors.primary
                                        : Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: hasDateRange
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.15),
                                  side: BorderSide(
                                    color: hasDateRange
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.3),
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(width: 8),
                          Obx(() {
                            final hasFilters =
                                controller.selectedMonth.value != 'All' ||
                                (controller.startDate.value != null &&
                                    controller.endDate.value != null) ||
                                controller.searchQuery.value.isNotEmpty;
                            if (!hasFilters) return SizedBox.shrink();
                            return IconButton(
                              onPressed: () => controller.clearFilters(),
                              icon: Icon(Icons.clear, color: Colors.white),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.2),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Main Content Area
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
                            if (controller.isLoading.value) {
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

                            final leaveRequests = controller.leaveRequests;

                            if (leaveRequests.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(32),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(
                                          0.05,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.folder_open_rounded,
                                        size: 64,
                                        color: AppColors.primary.withOpacity(
                                          0.3,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      'No Leave History',
                                      style: AppTextStyles.title.copyWith(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.blackColor,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'You haven\'t submitted any leave requests yet',
                                      style: AppTextStyles.body.copyWith(
                                        color: AppColors.greyColor,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return RefreshIndicator(
                              onRefresh: () async {
                                await controller.refreshLeaveRequests();
                              },
                              color: AppColors.primary,
                              child: ListView.builder(
                                itemCount: leaveRequests.length,
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                itemBuilder: (context, index) {
                                  final request = leaveRequests[index];
                                  return AnimatedContainer(
                                    duration: Duration(
                                      milliseconds: 300 + (index * 50),
                                    ),
                                    curve: Curves.easeOutBack,
                                    child: LeaveRequestCard(
                                      leaveRequest: request,
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

  Widget _buildFilterChip(String month) {
    return Obx(() {
      final isSelected = controller.selectedMonth.value == month;
      return Container(
        margin: const EdgeInsets.only(right: 12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => controller.setMonth(month),
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
                      Icons.calendar_month,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    month,
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

  Future<void> _showDateRangePicker(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(DateTime.now().year),
      lastDate: DateTime(DateTime.now().year, 12, 31),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.blackColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      controller.setDateRange(picked.start, picked.end);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
