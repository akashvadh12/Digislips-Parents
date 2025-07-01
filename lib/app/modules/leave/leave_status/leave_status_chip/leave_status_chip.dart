import 'package:digislips/app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  final String status;

  const StatusChip({Key? key, required this.status}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    IconData icon;
    String displayText;

    switch (status.toLowerCase()) {
      case 'pending':
        backgroundColor = AppColors.pendingColor.withOpacity(0.1);
        textColor = AppColors.pendingColor;
        icon = Icons.schedule;
        displayText = 'Pending';
        break;
      case 'partially approved':
        backgroundColor = AppColors.greyColor.withOpacity(0.1);
        textColor = AppColors.greyColor;
        icon = Icons.help_outline;
        displayText = 'Approved';
        break;
      case 'rejected':
        backgroundColor = AppColors.rejectedColor.withOpacity(0.1);
        textColor = AppColors.rejectedColor;
        icon = Icons.cancel;
        displayText = 'Rejected';
        break;
      case 'approved':
        backgroundColor = AppColors.approvedColor.withOpacity(0.1);
        textColor = AppColors.approvedColor;
        icon = Icons.check_circle;
        displayText = 'Approved';
        break;
      default:
        backgroundColor = AppColors.greyColor.withOpacity(0.1);
        textColor = AppColors.greyColor;
        icon = Icons.help_outline;
        displayText = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            displayText,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
