import 'package:digislips/app/core/theme/app_colors.dart';
import 'package:digislips/app/core/theme/app_text_styles.dart';
import 'package:digislips/app/modules/leave/leave_model/leave_model.dart';
import 'package:digislips/app/modules/leave/leave_status/leave_status_chip/leave_status_chip.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LeaveRequestCard extends StatelessWidget {
  final LeaveModel leaveRequest;
  final VoidCallback? onTap;

  const LeaveRequestCard({
    Key? key,
    required this.leaveRequest,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.blackColor.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _getLeaveTypeColor().withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _getLeaveTypeIcon(),
                              size: 20,
                              color: _getLeaveTypeColor(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              leaveRequest.leaveType,
                              style: AppTextStyles.title.copyWith(
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    StatusChip(status: leaveRequest.status),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Date Range
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.lightGrey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: AppColors.greyColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        dateFormat.format(leaveRequest.fromDate),
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontSize: 13,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(
                          Icons.arrow_forward,
                          size: 14,
                          color: AppColors.greyColor,
                        ),
                      ),
                      Text(
                        dateFormat.format(leaveRequest.toDate),
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${leaveRequest.totalDays} ${leaveRequest.totalDays == 1 ? 'day' : 'days'}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                if (leaveRequest.status.toLowerCase() == 'rejected' && 
                    leaveRequest.reviewComments != null && 
                    leaveRequest.reviewComments!.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.rejectedColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.rejectedColor.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: AppColors.rejectedColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Rejection Reason',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontSize: 13,
                                color: AppColors.rejectedColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          leaveRequest.reviewComments!,
                          style: AppTextStyles.body.copyWith(
                            fontSize: 13,
                            color: AppColors.blackColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Text(
                    'Reason: ${leaveRequest.reason}',
                    style: AppTextStyles.body.copyWith(
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                
                const SizedBox(height: 12),
                
                // Submission date
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: AppColors.greyColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Submitted on ${dateFormat.format(leaveRequest.submittedAt)}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),

                // Show destination if available
                if (leaveRequest.destination.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: AppColors.greyColor,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Destination: ${leaveRequest.destination}',
                          style: AppTextStyles.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],

                // Show travel mode if available
                if (leaveRequest.travelMode.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.directions,
                        size: 14,
                        color: AppColors.greyColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Travel: ${leaveRequest.travelMode}',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ],

                // Show documents if available
                if (leaveRequest.documentUrls.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.attach_file,
                        size: 14,
                        color: AppColors.greyColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${leaveRequest.documentUrls.length} ${leaveRequest.documentUrls.length == 1 ? 'document' : 'documents'} attached',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getLeaveTypeColor() {
    switch (leaveRequest.leaveType.toLowerCase()) {
      case 'sick leave':
        return AppColors.error;
      case 'vacation leave':
        return AppColors.success;
      case 'personal leave':
        return AppColors.primary;
      case 'family emergency':
        return AppColors.warning;
      case 'medical leave':
        return AppColors.error;
      default:
        return AppColors.greyColor;
    }
  }

  IconData _getLeaveTypeIcon() {
    switch (leaveRequest.leaveType.toLowerCase()) {
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