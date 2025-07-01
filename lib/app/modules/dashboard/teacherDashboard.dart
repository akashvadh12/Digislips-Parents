// // app/modules/teacher/views/teacher_dashboard_view.dart
// import 'package:digislips/app/core/theme/app_colors.dart';
// import 'package:digislips/app/core/theme/app_text_styles.dart';
// import 'package:digislips/app/modules/contect/contect.dart';
// import 'package:digislips/app/modules/dashboard/dashboard_controller.dart';
// import 'package:digislips/app/modules/notification/notification_controller.dart';
// import 'package:digislips/app/modules/notification/notification_screen.dart';
// import 'package:digislips/app/shared/widgets/bottomnavigation/navigation_controller.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// class TeacherDashboardView extends GetView<HomeController> {
//   @override
//   Widget build(BuildContext context) {
//     Get.put(HomeController());
//     final BottomNavController bottomNavController = Get.put(
//       BottomNavController(),
//     );
//     final NotificationController notificationController = Get.put(
//       NotificationController(),
//     );
//     return Scaffold(
//       backgroundColor: AppColors.primary,
//       body: SafeArea(
//         child: Column(
//           children: [
//             // Enhanced Header with gradient and better spacing
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.fromLTRB(20, 20, 24, 30),
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                   colors: [
//                     AppColors.primary,
//                     AppColors.primary.withOpacity(0.8),
//                   ],
//                 ),
//                 boxShadow: [
//                   BoxShadow(
//                     color: AppColors.primary.withOpacity(0.3),
//                     blurRadius: 20,
//                     offset: const Offset(0, 8),
//                   ),
//                 ],
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             controller.greetingWithEmoji,
//                             style: AppTextStyles.welcomeTitle.copyWith(
//                               fontSize: 16,
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                           const SizedBox(height: 4),
//                           Obx(
//                             () => Text(
//                               controller.isLoading.value
//                                   ? 'Loading...'
//                                   : controller.currentUserName,
//                               style: AppTextStyles.welcomeTitle.copyWith(
//                                 fontSize: 24,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                       // Notification Bell with badge
//                       Stack(
//                         children: [
//                           Container(
//                             padding: const EdgeInsets.all(5),
//                             decoration: BoxDecoration(
//                               color: Colors.white.withOpacity(0.2),
//                               borderRadius: BorderRadius.circular(16),
//                             ),
//                             child: IconButton(
//                               icon: const Icon(
//                                 Icons.notifications_outlined,
//                                 color: Colors.white,
//                                 size: 24,
//                               ),
//                               onPressed: () {
//                                 bottomNavController.changeBottomNavIndex(1);
//                                 // Get.to(NotificationScreen());
//                               },
//                             ),
//                           ),
//                           // Notification badge
//                           Obx(() {
//                             if (notificationController.hasUnreadNotifications) {
//                               return Positioned(
//                                 right: 6,
//                                 top: 6,
//                                 child: Container(
//                                   padding: const EdgeInsets.symmetric(
//                                     horizontal: 6,
//                                     vertical: 2,
//                                   ),
//                                   decoration: BoxDecoration(
//                                     color: Colors.red,
//                                     borderRadius: BorderRadius.circular(12),
//                                   ),
//                                   child: Text(
//                                     '${notificationController.unreadCount.value}',
//                                     style: const TextStyle(
//                                       color: Colors.white,
//                                       fontSize: 10,
//                                       fontWeight: FontWeight.bold,
//                                     ),
//                                   ),
//                                 ),
//                               );
//                             } else {
//                               return const SizedBox.shrink(); // Hide if no unread notifications
//                             }
//                           }),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),

//             Expanded(
//               child: Container(
//                 decoration: const BoxDecoration(
//                   color: Color(0xFFF8FAFC),
//                   borderRadius: BorderRadius.only(
//                     topLeft: Radius.circular(32),
//                     topRight: Radius.circular(32),
//                   ),
//                 ),
//                 child: Obx(
//                   () => controller.isLoading.value
//                       ? const Center(
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               CircularProgressIndicator(),
//                               SizedBox(height: 16),
//                               Text('Loading profile...'),
//                             ],
//                           ),
//                         )
//                       : RefreshIndicator(
//                           onRefresh: controller.refreshLeaveApplications,
//                           child: SingleChildScrollView(
//                             physics: const AlwaysScrollableScrollPhysics(),
//                             padding: const EdgeInsets.all(14),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 // Enhanced Profile Card with glassmorphism effect
//                                 Container(
//                                   padding: const EdgeInsets.all(20),
//                                   decoration: BoxDecoration(
//                                     gradient: LinearGradient(
//                                       begin: Alignment.topLeft,
//                                       end: Alignment.bottomRight,
//                                       colors: [
//                                         Colors.white,
//                                         Colors.white.withOpacity(0.9),
//                                       ],
//                                     ),
//                                     borderRadius: BorderRadius.circular(20),
//                                     boxShadow: [
//                                       BoxShadow(
//                                         color: Colors.black.withOpacity(0.08),
//                                         blurRadius: 20,
//                                         offset: const Offset(0, 4),
//                                       ),
//                                     ],
//                                     border: Border.all(
//                                       color: Colors.white.withOpacity(0.2),
//                                       width: 1,
//                                     ),
//                                   ),
//                                   child: Row(
//                                     children: [
//                                       // Enhanced Profile Avatar with border and shadow
//                                       Container(
//                                         width: 60,
//                                         height: 60,
//                                         decoration: BoxDecoration(
//                                           shape: BoxShape.circle,
//                                           gradient: LinearGradient(
//                                             colors: [
//                                               AppColors.primary.withOpacity(
//                                                 0.1,
//                                               ),
//                                               AppColors.primary.withOpacity(
//                                                 0.05,
//                                               ),
//                                             ],
//                                           ),
//                                           boxShadow: [
//                                             BoxShadow(
//                                               color: AppColors.primary
//                                                   .withOpacity(0.2),
//                                               blurRadius: 12,
//                                               offset: const Offset(0, 4),
//                                             ),
//                                           ],
//                                         ),
//                                         child: Container(
//                                           margin: const EdgeInsets.all(3),
//                                           decoration: BoxDecoration(
//                                             shape: BoxShape.circle,
//                                             image: DecorationImage(
//                                               image:
//                                                   controller.profileImageUrl !=
//                                                           null &&
//                                                       controller
//                                                           .profileImageUrl!
//                                                           .isNotEmpty
//                                                   ? NetworkImage(
//                                                       controller
//                                                           .profileImageUrl!,
//                                                     )
//                                                   : const NetworkImage(''),
//                                               fit: BoxFit.cover,
//                                               onError: (exception, stackTrace) {
//                                                 // Handle image load error
//                                               },
//                                             ),
//                                           ),
//                                           child:
//                                               controller.profileImageUrl ==
//                                                       null ||
//                                                   controller
//                                                       .profileImageUrl!
//                                                       .isEmpty
//                                               ? Icon(
//                                                   Icons.person,
//                                                   size: 30,
//                                                   color: AppColors.primary
//                                                       .withOpacity(0.7),
//                                                 )
//                                               : null,
//                                         ),
//                                       ),
//                                       const SizedBox(width: 6),
//                                       // Enhanced Profile Info
//                                       Expanded(
//                                         child: Column(
//                                           crossAxisAlignment:
//                                               CrossAxisAlignment.start,
//                                           children: [
//                                             Text(
//                                               controller.studentName,
//                                               style: AppTextStyles.profileName,
//                                             ),
//                                             const SizedBox(height: 2),
//                                             Text(
//                                               controller.studentDepartment,
//                                               style: AppTextStyles
//                                                   .profileSubtitle
//                                                   .copyWith(
//                                                     color: AppColors.primary,
//                                                     fontWeight: FontWeight.w500,
//                                                   ),
//                                             ),
//                                           ],
//                                         ),
//                                       ),
//                                       // Status indicator
//                                       Container(
//                                         padding: const EdgeInsets.symmetric(
//                                           horizontal: 8,
//                                           vertical: 6,
//                                         ),
//                                         decoration: BoxDecoration(
//                                           color: controller.isProfileComplete
//                                               ? Colors.green.withOpacity(0.1)
//                                               : Colors.orange.withOpacity(0.1),
//                                           borderRadius: BorderRadius.circular(
//                                             20,
//                                           ),
//                                         ),
//                                         child: Row(
//                                           mainAxisSize: MainAxisSize.min,
//                                           children: [
//                                             Container(
//                                               width: 6,
//                                               height: 6,
//                                               decoration: BoxDecoration(
//                                                 color:
//                                                     controller.isProfileComplete
//                                                     ? Colors.green
//                                                     : Colors.orange,
//                                                 shape: BoxShape.circle,
//                                               ),
//                                             ),
//                                             const SizedBox(width: 6),
//                                             Text(
//                                               controller.isProfileComplete
//                                                   ? 'Complete'
//                                                   : 'Incomplete',
//                                               style: TextStyle(
//                                                 color:
//                                                     controller.isProfileComplete
//                                                     ? Colors.green[700]
//                                                     : Colors.orange[700],
//                                                 fontSize: 12,
//                                                 fontWeight: FontWeight.w500,
//                                               ),
//                                             ),
//                                           ],
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),

//                                 const SizedBox(height: 32),

//                                 // Enhanced Action Cards Grid with Role-based Visibility
//                                 Obx(() => _buildActionCardsGrid()),

//                                 const SizedBox(height: 32),

//                                 // Enhanced Recent Leave Applications Section
//                                 Row(
//                                   mainAxisAlignment:
//                                       MainAxisAlignment.spaceBetween,
//                                   children: [
//                                     Text(
//                                       'Recent Applications',
//                                       style: AppTextStyles.sectionTitle
//                                           .copyWith(
//                                             fontSize: 20,
//                                             fontWeight: FontWeight.w700,
//                                           ),
//                                     ),
//                                     TextButton(
//                                       onPressed: controller.onViewLeaveStatus,
//                                       child: Text(
//                                         'View All',
//                                         style: TextStyle(
//                                           color: AppColors.primary,
//                                           fontWeight: FontWeight.w600,
//                                         ),
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                                 const SizedBox(height: 16),

//                                 // Enhanced Leave Applications List with Loading State
//                                 Obx(() {
//                                   if (controller.isLoadingLeaves.value) {
//                                     return Container(
//                                       padding: const EdgeInsets.all(40),
//                                       decoration: BoxDecoration(
//                                         color: Colors.grey[50],
//                                         borderRadius: BorderRadius.circular(16),
//                                         border: Border.all(
//                                           color: Colors.grey[200]!,
//                                           width: 1,
//                                         ),
//                                       ),
//                                       child: const Center(
//                                         child: Column(
//                                           children: [
//                                             CircularProgressIndicator(),
//                                             SizedBox(height: 16),
//                                             Text(
//                                               'Loading leave applications...',
//                                               style: TextStyle(
//                                                 fontSize: 14,
//                                                 color: Colors.grey,
//                                               ),
//                                             ),
//                                           ],
//                                         ),
//                                       ),
//                                     );
//                                   }

//                                   if (controller
//                                       .recentLeaveApplications
//                                       .isEmpty) {
//                                     return Container(
//                                       padding: const EdgeInsets.all(40),
//                                       decoration: BoxDecoration(
//                                         color: Colors.grey[50],
//                                         borderRadius: BorderRadius.circular(16),
//                                         border: Border.all(
//                                           color: Colors.grey[200]!,
//                                           width: 1,
//                                         ),
//                                       ),
//                                       child: Column(
//                                         children: [
//                                           Icon(
//                                             Icons.assignment_outlined,
//                                             size: 48,
//                                             color: Colors.grey[400],
//                                           ),
//                                           const SizedBox(height: 16),
//                                           Text(
//                                             'No recent applications',
//                                             style: TextStyle(
//                                               color: Colors.grey[600],
//                                               fontSize: 16,
//                                               fontWeight: FontWeight.w500,
//                                             ),
//                                           ),
//                                           const SizedBox(height: 8),
//                                           Text(
//                                             'Student leave applications will appear here',
//                                             style: TextStyle(
//                                               color: Colors.grey[500],
//                                               fontSize: 14,
//                                             ),
//                                             textAlign: TextAlign.center,
//                                           ),
//                                         ],
//                                       ),
//                                     );
//                                   }

//                                   return ListView.separated(
//                                     shrinkWrap: true,
//                                     physics:
//                                         const NeverScrollableScrollPhysics(),
//                                     itemCount: controller
//                                         .recentLeaveApplications
//                                         .length,
//                                     separatorBuilder: (context, index) =>
//                                         const SizedBox(height: 12),
//                                     itemBuilder: (context, index) {
//                                       final leave = controller
//                                           .recentLeaveApplications[index];
//                                       return _buildEnhancedLeaveApplicationCard(
//                                         leave,
//                                       );
//                                     },
//                                   );
//                                 }),

//                                 const SizedBox(height: 40),
//                               ],
//                             ),
//                           ),
//                         ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // Build Action Cards Grid with Role-based Visibility
//   Widget _buildActionCardsGrid() {
//     List<Widget> actionCards = [];

//     // Always show Leave Request card
//     actionCards.add(
//       _buildEnhancedActionCard(
//         icon: Icons.assignment,
//         title: 'Leave Request',
//         subtitle: 'View Leave Requests',
//         gradient: [Colors.blue[400]!, Colors.blue[600]!],
//         onTap: controller.LeaveRequests,
//       ),
//     );

//     // Show Phone card only for teachers
//     if (controller.isCurrentUserTeacher) {
//       actionCards.add(
//         _buildEnhancedActionCard(
//           icon: Icons.phone,
//           title: 'Phone',
//           subtitle: 'Contact Parent',
//           gradient: [Colors.green[400]!, Colors.green[600]!],
//           onTap: () {
//             Get.to(ContactScreen());
//           },
//         ),
//       );
//     }

//     // Always show My Profile card
//     actionCards.add(
//       _buildEnhancedActionCard(
//         icon: Icons.person_outline_rounded,
//         title: 'My Profile',
//         subtitle: 'View & edit profile',
//         gradient: [Colors.purple[400]!, Colors.purple[600]!],
//         onTap: controller.onMyProfile,
//       ),
//     );

//     // Show Logout card only for teachers
//     if (controller.isCurrentUserTeacher) {
//       actionCards.add(
//         _buildEnhancedActionCard(
//           icon: Icons.logout_rounded,
//           title: 'Logout',
//           subtitle: 'Sign out safely',
//           gradient: [Colors.red[400]!, Colors.red[600]!],
//           onTap: controller.onLogout,
//         ),
//       );
//     }

//     // Determine grid layout based on number of cards
//     int crossAxisCount = actionCards.length == 2 ? 2 : 2;
//     double childAspectRatio = actionCards.length == 2 ? 1.2 : 1;

//     return GridView.count(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       crossAxisCount: crossAxisCount,
//       crossAxisSpacing: 8,
//       mainAxisSpacing: 8,
//       childAspectRatio: childAspectRatio,
//       children: actionCards,
//     );
//   }

//   Widget _buildEnhancedActionCard({
//     required IconData icon,
//     required String title,
//     required String subtitle,
//     required List<Color> gradient,
//     required VoidCallback onTap,
//   }) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//             colors: gradient,
//           ),
//           borderRadius: BorderRadius.circular(20),
//           boxShadow: [
//             BoxShadow(
//               color: gradient[0].withOpacity(0.3),
//               blurRadius: 15,
//               offset: const Offset(0, 8),
//             ),
//           ],
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.white.withOpacity(0.2),
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               child: Icon(icon, size: 28, color: Colors.white),
//             ),
//             const SizedBox(height: 16),
//             Text(
//               title,
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//               ),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 4),
//             Text(
//               subtitle,
//               style: TextStyle(
//                 color: Colors.white.withOpacity(0.8),
//                 fontSize: 12,
//                 fontWeight: FontWeight.w500,
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildEnhancedLeaveApplicationCard(LeaveApplication leave) {
//     Color statusColor;
//     IconData statusIcon;

//     switch (leave.status.toLowerCase()) {
//       case 'approved':
//         statusColor = Colors.green;
//         statusIcon = Icons.check_circle_outline;
//         break;
//       case 'pending':
//         statusColor = Colors.orange;
//         statusIcon = Icons.schedule_outlined;
//         break;
//       case 'rejected':
//         statusColor = Colors.red;
//         statusIcon = Icons.cancel_outlined;
//         break;
//       default:
//         statusColor = Colors.orange;
//         statusIcon = Icons.schedule_outlined;
//     }

//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.06),
//             blurRadius: 15,
//             offset: const Offset(0, 4),
//           ),
//         ],
//         border: Border.all(color: statusColor.withOpacity(0.1), width: 1),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Header Row with Leave Type and Status
//           Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: statusColor.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Icon(
//                   Icons.calendar_today_outlined,
//                   color: statusColor,
//                   size: 20,
//                 ),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       leave.type,
//                       style: const TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w600,
//                         color: Colors.black87,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       leave.date,
//                       style: TextStyle(
//                         fontSize: 13,
//                         color: Colors.grey[600],
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 12,
//                   vertical: 6,
//                 ),
//                 decoration: BoxDecoration(
//                   color: statusColor.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Icon(statusIcon, size: 16, color: statusColor),
//                     const SizedBox(width: 6),
//                     Text(
//                       leave.status,
//                       style: TextStyle(
//                         color: statusColor,
//                         fontSize: 12,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),

//           const SizedBox(height: 16),

//           // Student Information Section
//           if (leave.studentName != null ||
//               leave.rollNumber != null ||
//               leave.department != null)
//             Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.grey[50],
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(color: Colors.grey[200]!, width: 1),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Student Name
//                   if (leave.studentName != null &&
//                       leave.studentName!.isNotEmpty)
//                     Row(
//                       children: [
//                         Icon(
//                           Icons.person_outline,
//                           size: 16,
//                           color: Colors.grey[600],
//                         ),
//                         const SizedBox(width: 8),
//                         Expanded(
//                           child: Text(
//                             leave.studentName!,
//                             style: TextStyle(
//                               fontSize: 14,
//                               fontWeight: FontWeight.w600,
//                               color: Colors.grey[800],
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),

//                   // Roll Number and Department
//                   if ((leave.rollNumber != null &&
//                           leave.rollNumber!.isNotEmpty) ||
//                       (leave.department != null &&
//                           leave.department!.isNotEmpty))
//                     const SizedBox(height: 8),

//                   Row(
//                     children: [
//                       // Roll Number
//                       if (leave.rollNumber != null &&
//                           leave.rollNumber!.isNotEmpty)
//                         Expanded(
//                           child: Row(
//                             children: [
//                               Icon(
//                                 Icons.badge_outlined,
//                                 size: 16,
//                                 color: Colors.grey[600],
//                               ),
//                               const SizedBox(width: 8),
//                               Flexible(
//                                 child: Text(
//                                   'Roll: ${leave.rollNumber}',
//                                   style: TextStyle(
//                                     fontSize: 12,
//                                     color: Colors.grey[700],
//                                     fontWeight: FontWeight.w500,
//                                   ),
//                                   overflow: TextOverflow.ellipsis,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),

//                       // Department
//                       if (leave.department != null &&
//                           leave.department!.isNotEmpty)
//                         Expanded(
//                           child: Row(
//                             children: [
//                               Icon(
//                                 Icons.school_outlined,
//                                 size: 16,
//                                 color: Colors.grey[600],
//                               ),
//                               const SizedBox(width: 8),
//                               Flexible(
//                                 child: Text(
//                                   leave.department!,
//                                   style: TextStyle(
//                                     fontSize: 12,
//                                     color: Colors.grey[700],
//                                     fontWeight: FontWeight.w500,
//                                   ),
//                                   overflow: TextOverflow.ellipsis,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),

//           // Reason Section
//           if (leave.reason != null && leave.reason!.isNotEmpty) ...[
//             const SizedBox(height: 12),
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Icon(
//                   Icons.description_outlined,
//                   size: 16,
//                   color: Colors.grey[600],
//                 ),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Reason:',
//                         style: TextStyle(
//                           fontSize: 12,
//                           fontWeight: FontWeight.w600,
//                           color: Colors.grey[700],
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         leave.reason!,
//                         style: TextStyle(
//                           fontSize: 13,
//                           color: Colors.grey[800],
//                           height: 1.3,
//                         ),
//                         maxLines: 3,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ],
//       ),
//     );
//   }
// }