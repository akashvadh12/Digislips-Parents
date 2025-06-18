// import 'package:digislips/app/modules/leave/leave1/leavecontroller.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get_core/src/get_main.dart';
// import 'package:get/get_instance/get_instance.dart';
// import 'package:provider/provider.dart';

// class LeaveRequestScreen extends StatefulWidget {
//   @override
//   _LeaveRequestScreenState createState() => _LeaveRequestScreenState();
// }

// class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       Get.find<LeaveRequestController>().fetchAllLeaveRequests();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       appBar: AppBar(
//         title: Text(
//           'Leave Requests',
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//             color: Colors.white,
//           ),
//         ),
//         backgroundColor: Colors.indigo[600],
//         elevation: 0,
//         actions: [
//           IconButton(
//             icon: Icon(Icons.refresh, color: Colors.white),
//             onPressed: () {
//               Get.find<LeaveRequestController>().fetchAllLeaveRequests();
//             },
//           ),
//         ],
//       ),
//       body: Consumer<LeaveRequestController>(
//         builder: (context, controller, child) {
//           if (controller.isLoading) {
//             return Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   CircularProgressIndicator(
//                     valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo[600]!),
//                   ),
//                   SizedBox(height: 16),
//                   Text(
//                     'Loading leave requests...',
//                     style: TextStyle(
//                       fontSize: 16,
//                       color: Colors.grey[600],
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           }

//           if (controller.errorMessage.isNotEmpty) {
//             return Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(
//                     Icons.error_outline,
//                     size: 64,
//                     color: Colors.red[400],
//                   ),
//                   SizedBox(height: 16),
//                   Text(
//                     controller.errorMessage,
//                     style: TextStyle(
//                       fontSize: 16,
//                       color: Colors.red[600],
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                   SizedBox(height: 16),
//                   ElevatedButton(
//                     onPressed: () {
//                       controller.fetchAllLeaveRequests();
//                     },
//                     child: Text('Retry'),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.indigo[600],
//                       foregroundColor: Colors.white,
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           }

//           if (controller.leaveRequests.isEmpty) {
//             return Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(
//                     Icons.inbox_outlined,
//                     size: 64,
//                     color: Colors.grey[400],
//                   ),
//                   SizedBox(height: 16),
//                   Text(
//                     'No leave requests found',
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.w500,
//                       color: Colors.grey[600],
//                     ),
//                   ),
//                   SizedBox(height: 8),
//                   Text(
//                     'Pull down to refresh',
//                     style: TextStyle(
//                       fontSize: 14,
//                       color: Colors.grey[500],
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           }

//           return RefreshIndicator(
//             onRefresh: () => controller.fetchAllLeaveRequests(),
//             color: Colors.indigo[600],
//             child: ListView.builder(
//               padding: EdgeInsets.all(16),
//               itemCount: controller.leaveRequests.length,
//               itemBuilder: (context, index) {
//                 LeaveRequestWithStudent request = controller.leaveRequests[index];
//                 String status = controller.getLeaveStatus(request.leaveData);
                
//                 return Card(
//                   elevation: 3,
//                   margin: EdgeInsets.only(bottom: 16),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Padding(
//                     padding: EdgeInsets.all(16),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         // Student Info Header
//                         Row(
//                           children: [
//                             CircleAvatar(
//                               backgroundColor: Colors.indigo[100],
//                               child: Text(
//                                 request.studentName.isNotEmpty 
//                                     ? request.studentName[0].toUpperCase()
//                                     : 'S',
//                                 style: TextStyle(
//                                   fontWeight: FontWeight.bold,
//                                   color: Colors.indigo[700],
//                                 ),
//                               ),
//                             ),
//                             SizedBox(width: 12),
//                             Expanded(
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     request.studentName,
//                                     style: TextStyle(
//                                       fontSize: 16,
//                                       fontWeight: FontWeight.bold,
//                                       color: Colors.grey[800],
//                                     ),
//                                   ),
//                                   Text(
//                                     '${request.department} • ${request.studentEmail}',
//                                     style: TextStyle(
//                                       fontSize: 12,
//                                       color: Colors.grey[600],
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                             Container(
//                               padding: EdgeInsets.symmetric(
//                                 horizontal: 12,
//                                 vertical: 6,
//                               ),
//                               decoration: BoxDecoration(
//                                 color: controller.getStatusColor(status).withOpacity(0.1),
//                                 borderRadius: BorderRadius.circular(20),
//                                 border: Border.all(
//                                   color: controller.getStatusColor(status),
//                                   width: 1,
//                                 ),
//                               ),
//                               child: Text(
//                                 status.toUpperCase(),
//                                 style: TextStyle(
//                                   fontSize: 12,
//                                   fontWeight: FontWeight.bold,
//                                   color: controller.getStatusColor(status),
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
                        
//                         SizedBox(height: 16),
                        
//                         // Leave Details
//                         Container(
//                           padding: EdgeInsets.all(12),
//                           decoration: BoxDecoration(
//                             color: Colors.grey[50],
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               _buildDetailRow(
//                                 'Reason',
//                                 request.leaveData['reason'] ?? 'Not specified',
//                                 Icons.description_outlined,
//                               ),
//                               SizedBox(height: 8),
//                               _buildDetailRow(
//                                 'From Date',
//                                 controller.formatDate(request.leaveData['fromDate']),
//                                 Icons.calendar_today_outlined,
//                               ),
//                               SizedBox(height: 8),
//                               _buildDetailRow(
//                                 'To Date',
//                                 controller.formatDate(request.leaveData['toDate']),
//                                 Icons.event_outlined,
//                               ),
//                               SizedBox(height: 8),
//                               _buildDetailRow(
//                                 'Applied On',
//                                 controller.formatDate(request.leaveData['createdAt']),
//                                 Icons.access_time_outlined,
//                               ),
//                             ],
//                           ),
//                         ),
                        
//                         // Action Buttons (only show if status is pending)
//                         if (status.toLowerCase() == 'pending') ...[
//                           SizedBox(height: 16),
//                           Row(
//                             children: [
//                               Expanded(
//                                 child: ElevatedButton.icon(
//                                   onPressed: () {
//                                     _showConfirmationDialog(
//                                       context,
//                                       'Approve Leave',
//                                       'Are you sure you want to approve this leave request?',
//                                       () => controller.updateLeaveStatus(
//                                         request.studentId,
//                                         request.leaveId,
//                                         'approved',
//                                       ),
//                                     );
//                                   },
//                                   icon: Icon(Icons.check, size: 18),
//                                   label: Text('Approve'),
//                                   style: ElevatedButton.styleFrom(
//                                     backgroundColor: Colors.green,
//                                     foregroundColor: Colors.white,
//                                     padding: EdgeInsets.symmetric(vertical: 12),
//                                     shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(8),
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                               SizedBox(width: 12),
//                               Expanded(
//                                 child: ElevatedButton.icon(
//                                   onPressed: () {
//                                     _showConfirmationDialog(
//                                       context,
//                                       'Reject Leave',
//                                       'Are you sure you want to reject this leave request?',
//                                       () => controller.updateLeaveStatus(
//                                         request.studentId,
//                                         request.leaveId,
//                                         'rejected',
//                                       ),
//                                     );
//                                   },
//                                   icon: Icon(Icons.close, size: 18),
//                                   label: Text('Reject'),
//                                   style: ElevatedButton.styleFrom(
//                                     backgroundColor: Colors.red,
//                                     foregroundColor: Colors.white,
//                                     padding: EdgeInsets.symmetric(vertical: 12),
//                                     shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(8),
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildDetailRow(String label, String value, IconData icon) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Icon(
//           icon,
//           size: 16,
//           color: Colors.grey[600],
//         ),
//         SizedBox(width: 8),
//         Expanded(
//           child: RichText(
//             text: TextSpan(
//               style: TextStyle(
//                 fontSize: 14,
//                 color: Colors.grey[800],
//               ),
//               children: [
//                 TextSpan(
//                   text: '$label: ',
//                   style: TextStyle(
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//                 TextSpan(
//                   text: value,
//                   style: TextStyle(
//                     color: Colors.grey[700],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   void _showConfirmationDialog(
//     BuildContext context,
//     String title,
//     String content,
//     VoidCallback onConfirm,
//   ) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//           title: Text(
//             title,
//             style: TextStyle(
//               fontWeight: FontWeight.bold,
//               color: Colors.grey[800],
//             ),
//           ),
//           content: Text(
//             content,
//             style: TextStyle(
//               color: Colors.grey[600],
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(),
//               child: Text(
//                 'Cancel',
//                 style: TextStyle(
//                   color: Colors.grey[600],
//                 ),
//               ),
//             ),
//             ElevatedButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//                 onConfirm();
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.indigo[600],
//                 foregroundColor: Colors.white,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//               ),
//               child: Text('Confirm'),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }