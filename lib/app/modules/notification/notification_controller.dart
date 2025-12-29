// app/modules/notification/notification_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digislips/app/modules/auth/models/user_model.dart';
import 'package:digislips/app/modules/leave/leave_model/leave_model.dart';
import 'package:digislips/app/modules/leave/leave_service/leave_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';

enum NotificationType {
  leaveApproved,
  leaveRejected,
  leavePending,
  leaveSubmitted,
  profileUpdate,
  general,
  newLeaveRequest,
  leaveStatusChanged,
  systemAlert,
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final bool isDeleted;
  final String? relatedLeaveId;
  final String? relatedStudentId;
  final String? relatedStudentName;
  final Color backgroundColor;
  final IconData icon;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.isDeleted = false,
    this.relatedLeaveId,
    this.relatedStudentId,
    this.relatedStudentName,
    required this.backgroundColor,
    required this.icon,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type.toString(),
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isRead': isRead,
      'isDeleted': isDeleted,
      'relatedLeaveId': relatedLeaveId,
      'relatedStudentId': relatedStudentId,
      'relatedStudentName': relatedStudentName,
      'backgroundColor': backgroundColor.value,
      'iconName': _getIconName(icon),
    };
  }

  static String _getIconName(IconData icon) {
    if (icon == Icons.check_circle) return 'check_circle';
    if (icon == Icons.cancel) return 'cancel';
    if (icon == Icons.pending) return 'pending';
    if (icon == Icons.send) return 'send';
    if (icon == Icons.new_releases) return 'new_releases';
    if (icon == Icons.update) return 'update';
    if (icon == Icons.person) return 'person';
    if (icon == Icons.info) return 'info';
    return 'info';
  }

  static IconData _getIconFromName(String iconName) {
    switch (iconName) {
      case 'check_circle':
        return Icons.check_circle;
      case 'cancel':
        return Icons.cancel;
      case 'pending':
        return Icons.pending;
      case 'send':
        return Icons.send;
      case 'new_releases':
        return Icons.new_releases;
      case 'update':
        return Icons.update;
      case 'person':
        return Icons.person;
      case 'info':
      default:
        return Icons.info;
    }
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'],
      title: map['title'],
      message: map['message'],
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => NotificationType.general,
      ),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      isRead: map['isRead'] ?? false,
      isDeleted: map['isDeleted'] ?? false,
      relatedLeaveId: map['relatedLeaveId'],
      relatedStudentId: map['relatedStudentId'],
      relatedStudentName: map['relatedStudentName'],
      backgroundColor: Color(map['backgroundColor']),
      icon: _getIconFromName(map['iconName'] ?? 'info'),
    );
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    DateTime? timestamp,
    bool? isRead,
    bool? isDeleted,
    String? relatedLeaveId,
    String? relatedStudentId,
    String? relatedStudentName,
    Color? backgroundColor,
    IconData? icon,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      isDeleted: isDeleted ?? this.isDeleted,
      relatedLeaveId: relatedLeaveId ?? this.relatedLeaveId,
      relatedStudentId: relatedStudentId ?? this.relatedStudentId,
      relatedStudentName: relatedStudentName ?? this.relatedStudentName,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      icon: icon ?? this.icon,
    );
  }

  factory NotificationModel.fromLeaveModel(LeaveModel leave) {
    String title;
    String message;
    NotificationType type;
    Color backgroundColor;
    IconData icon;

    switch (leave.status.toLowerCase()) {
      case 'approved':
        title = 'Leave Approved';
        message = 'Your ${leave.leaveType} leave request has been approved';
        type = NotificationType.leaveApproved;
        backgroundColor = const Color(0xFF4CAF50);
        icon = Icons.check_circle;
        break;
      case 'rejected':
        title = 'Leave Rejected';
        message = 'Your ${leave.leaveType} leave request has been rejected';
        type = NotificationType.leaveRejected;
        backgroundColor = const Color(0xFFD32F2F);
        icon = Icons.cancel;
        break;
      case 'pending':
        title = 'Leave Pending';
        message = 'Your ${leave.leaveType} leave request is pending approval';
        type = NotificationType.leavePending;
        backgroundColor = Colors.orange;
        icon = Icons.pending;
        break;
      default:
        title = 'Leave Submitted';
        message = 'Your ${leave.leaveType} leave request has been submitted';
        type = NotificationType.leaveSubmitted;
        backgroundColor = Colors.blue;
        icon = Icons.send;
    }

    return NotificationModel(
      id: 'leave_${leave.id}_${leave.status.toLowerCase()}',
      title: title,
      message: message,
      type: type,
      timestamp: leave.submittedAt,
      relatedLeaveId: leave.id,
      relatedStudentId: leave.uid,
      relatedStudentName: leave.fullName,
      backgroundColor: backgroundColor,
      icon: icon,
    );
  }

  factory NotificationModel.newLeaveRequest(LeaveModel leave) {
    return NotificationModel(
      id: 'new_leave_${leave.id}',
      title: 'New Leave Request',
      message: '${leave.fullName} submitted a ${leave.leaveType} leave request',
      type: NotificationType.newLeaveRequest,
      timestamp: leave.submittedAt,
      relatedLeaveId: leave.id,
      relatedStudentId: leave.uid,
      relatedStudentName: leave.fullName,
      backgroundColor: Colors.blue,
      icon: Icons.new_releases,
    );
  }

  factory NotificationModel.parentLeaveUpdate(LeaveModel leave) {
    String title;
    String message;
    Color backgroundColor;
    IconData icon;

    switch (leave.status.toLowerCase()) {
      case 'approved':
        title = 'Child\'s Leave Approved';
        message =
            '${leave.fullName}\'s ${leave.leaveType} leave has been approved';
        backgroundColor = const Color(0xFF4CAF50);
        icon = Icons.check_circle;
        break;
      case 'rejected':
        title = 'Child\'s Leave Rejected';
        message =
            '${leave.fullName}\'s ${leave.leaveType} leave has been rejected';
        backgroundColor = const Color(0xFFD32F2F);
        icon = Icons.cancel;
        break;
      default:
        title = 'Child\'s Leave Update';
        message =
            '${leave.fullName}\'s ${leave.leaveType} leave status updated to ${leave.status}';
        backgroundColor = Colors.orange;
        icon = Icons.update;
    }

    return NotificationModel(
      id: 'parent_leave_${leave.id}_${leave.status.toLowerCase()}',
      title: title,
      message: message,
      type: NotificationType.leaveStatusChanged,
      timestamp: leave.submittedAt,
      relatedLeaveId: leave.id,
      relatedStudentId: leave.uid,
      relatedStudentName: leave.fullName,
      backgroundColor: backgroundColor,
      icon: icon,
    );
  }

  factory NotificationModel.profileUpdate(
    String message, {
    String? studentName,
    String? userId,
  }) {
    return NotificationModel(
      id: 'profile_${userId ?? 'user'}_${DateTime.now().millisecondsSinceEpoch}',
      title: studentName != null
          ? '${studentName}\'s Profile Updated'
          : 'Profile Updated',
      message: message,
      type: NotificationType.profileUpdate,
      timestamp: DateTime.now(),
      backgroundColor: Colors.indigo,
      icon: Icons.person,
    );
  }

  factory NotificationModel.general(String title, String message) {
    return NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: NotificationType.general,
      timestamp: DateTime.now(),
      backgroundColor: Colors.grey,
      icon: Icons.info,
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}

class NotificationController extends GetxController {
  var isLoading = true.obs;
  var isRefreshing = false.obs;
  var notifications = <NotificationModel>[].obs;
  var unreadCount = 0.obs;
  var student = Rxn<Student>();
  var parentStudentData = Rxn<Map<String, dynamic>>();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LeaveService _leaveService = LeaveService();

  var userRole = ''.obs;
  var isParent = false.obs;
  var isTeacher = false.obs;
  var userEmail = ''.obs;
  var uid = ''.obs;

  final Set<String> _readNotifications = <String>{};
  final Set<String> _deletedNotifications = <String>{};
  final Map<String, String> _lastProfileHash = <String, String>{};

  StreamSubscription? _leaveSubscription;
  StreamSubscription? _profileSubscription;
  StreamSubscription? _allStudentsLeaveSubscription;
  StreamSubscription? _notificationStatesSubscription;

  String get _storageKey => 'notifications_${uid.value}';
  String get _readNotificationsKey => 'read_notifications_${uid.value}';
  String get _deletedNotificationsKey => 'deleted_notifications_${uid.value}';
  String get _profileHashKey => 'profile_hash_${uid.value}';

  @override
  void onInit() {
    super.onInit();
    initializeNotifications();
  }

  @override
  void onClose() {
    _leaveSubscription?.cancel();
    _profileSubscription?.cancel();
    _allStudentsLeaveSubscription?.cancel();
    _notificationStatesSubscription?.cancel();
    super.onClose();
  }

  Future<void> initializeNotifications() async {
    try {
      isLoading.value = true;
      await _getUserDetailsFromPrefs();

      if (uid.value.isEmpty) {
        Get.snackbar(
          'Error',
          'User not found. Please login again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      await _loadNotificationStatesFromStorage();
      await _loadNotificationsFromStorage();
      await _setupNotificationStatesListener();

      if (userRole.value == 'parent' || isParent.value) {
        await _initializeParentNotifications();
      } else if (userRole.value == 'teacher' || isTeacher.value) {
        await _initializeTeacherNotifications();
      } else {
        await _initializeStudentNotifications();
      }
    } catch (e) {
      print('❌ Error initializing notifications: $e');
      Get.snackbar(
        'Error',
        'Failed to load notifications: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Update the _setupNotificationStatesListener method
  Future<void> _setupNotificationStatesListener() async {
    try {
      String collection;
      String userId;

      if (isParent.value && parentStudentData.value != null) {
        // For parents, listen to their student's notification states
        collection = 'students';
        userId =
            parentStudentData.value!['studentId'] ??
            parentStudentData.value!['uid'];
      } else {
        // For teachers/students, listen to their own notification states
        collection = isTeacher.value ? 'teachers' : 'students';
        userId = uid.value;
      }

      if (userId.isEmpty) {
        print('❌ User ID is empty');
        return;
      }

      _notificationStatesSubscription?.cancel();
      _notificationStatesSubscription = _firestore
          .collection(collection)
          .doc(userId)
          .collection('notification_states')
          .snapshots()
          .listen((snapshot) async {
            for (var doc in snapshot.docChanges) {
              final data = doc.doc.data() as Map<String, dynamic>?;
              if (data == null) continue;

              final notificationId = doc.doc.id;

              // Update local state
              if (data['isRead'] == true) {
                _readNotifications.add(notificationId);
              } else if (data['isRead'] == false) {
                _readNotifications.remove(notificationId);
              }

              if (data['isDeleted'] == true) {
                _deletedNotifications.add(notificationId);
              } else if (data['isDeleted'] == false) {
                _deletedNotifications.remove(notificationId);
              }

              // Update the notification in the list
              final index = notifications.indexWhere(
                (n) => n.id == notificationId,
              );
              if (index != -1) {
                notifications[index] = notifications[index].copyWith(
                  isRead: _readNotifications.contains(notificationId),
                  isDeleted: _deletedNotifications.contains(notificationId),
                );
              }
            }

            // Remove deleted notifications from the list
            notifications.removeWhere(
              (n) => _deletedNotifications.contains(n.id),
            );
            _updateUnreadCount();
            await _saveNotificationStatesToStorage();
          });
    } catch (e) {
      print('❌ Error setting up notification states listener: $e');
    }
  }

  Future<void> _loadNotificationStatesFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readNotifs = prefs.getStringList(_readNotificationsKey) ?? [];
      final deletedNotifs = prefs.getStringList(_deletedNotificationsKey) ?? [];
      _readNotifications.addAll(readNotifs);
      _deletedNotifications.addAll(deletedNotifs);

      final profileHashJson = prefs.getString(_profileHashKey);
      if (profileHashJson != null) {
        _lastProfileHash.addAll(
          Map<String, String>.from(json.decode(profileHashJson)),
        );
      }

      print('✅ Loaded notification states from storage');
    } catch (e) {
      print('❌ Error loading notification states: $e');
    }
  }

  Future<void> _saveNotificationStatesToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _readNotificationsKey,
        _readNotifications.toList(),
      );
      await prefs.setStringList(
        _deletedNotificationsKey,
        _deletedNotifications.toList(),
      );
      await prefs.setString(_profileHashKey, json.encode(_lastProfileHash));
      print('✅ Saved notification states to storage');
    } catch (e) {
      print('❌ Error saving notification states: $e');
    }
  }

  Future<void> _loadNotificationsFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getString(_storageKey);

      if (notificationsJson != null) {
        final List<dynamic> notificationsList = json.decode(notificationsJson);
        final List<NotificationModel> loadedNotifications = notificationsList
            .map((json) => NotificationModel.fromMap(json))
            .where((notif) => !_deletedNotifications.contains(notif.id))
            .map(
              (notif) => notif.copyWith(
                isRead: _readNotifications.contains(notif.id),
                isDeleted: _deletedNotifications.contains(notif.id),
              ),
            )
            .toList();

        notifications.value = loadedNotifications;
        _updateUnreadCount();
        print(
          '✅ Loaded ${loadedNotifications.length} notifications from storage',
        );
      }
    } catch (e) {
      print('❌ Error loading notifications from storage: $e');
    }
  }

  Future<void> _saveNotificationsToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = json.encode(
        notifications.map((notif) => notif.toMap()).toList(),
      );
      await prefs.setString(_storageKey, notificationsJson);
      await _saveNotificationStatesToStorage();
      print('✅ Saved ${notifications.length} notifications to storage');
    } catch (e) {
      print('❌ Error saving notifications to storage: $e');
    }
  }

  Future<void> _getUserDetailsFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      uid.value = prefs.getString('uid') ?? '';
      userRole.value = prefs.getString('userRole') ?? '';
      isParent.value = prefs.getBool('isParent') ?? false;
      isTeacher.value = prefs.getBool('isTeacher') ?? false;
      userEmail.value = prefs.getString('Email') ?? '';

      print('👤 User Role: ${userRole.value}');
      print('👤 Is Parent: ${isParent.value}');
      print('👤 Is Teacher: ${isTeacher.value}');
    } catch (e) {
      print('❌ Error getting user details from prefs: $e');
    }
  }

  String _generateProfileHash(Map<String, dynamic> profileData) {
    final relevantFields = {
      'fullName': profileData['fullName'],
      'email': profileData['email'],
      'phone': profileData['phone'],
      'department': profileData['department'],
      'rollNumber': profileData['rollNumber'],
      'parentEmail': profileData['parentEmail'],
    };
    return relevantFields.toString().hashCode.toString();
  }

  Future<void> _initializeParentNotifications() async {
    print('👨‍👩‍👧‍👦 Initializing parent notifications...');
    final studentData = await _verifyParentEmailInStudents(userEmail.value);

    if (studentData != null) {
      parentStudentData.value = studentData;
      student.value = Student.fromMap(studentData);
      _setupParentLeaveNotifications(studentData['studentId']);
      _setupParentProfileNotifications(studentData['studentId']);
    } else {
      Get.snackbar(
        'Error',
        'No student found with your parent email.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _initializeTeacherNotifications() async {
    print('👨‍💼 Initializing teacher notifications...');
    await _fetchCurrentUserData();
    _setupTeacherLeaveNotifications();
    _setupProfileNotifications(uid.value);
  }

  Future<void> _initializeStudentNotifications() async {
    print('👨‍🎓 Initializing student notifications...');
    await _fetchCurrentUserData();
    _setupStudentLeaveNotifications(uid.value);
    _setupProfileNotifications(uid.value);
  }

  Future<Map<String, dynamic>?> _verifyParentEmailInStudents(
    String parentEmail,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('students')
          .where('parentEmail', isEqualTo: parentEmail.trim().toLowerCase())
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final studentData = querySnapshot.docs.first.data();
        // Ensure studentId is always set
        studentData['studentId'] = querySnapshot.docs.first.id;

        // Add debug logging
        print(
          '✅ Found student for parent: ${studentData['fullName']} (ID: ${studentData['studentId']})',
        );

        return studentData;
      } else {
        print('❌ No student found for parent email: $parentEmail');
      }
      return null;
    } catch (e) {
      print('❌ Error verifying parent email: $e');
      return null;
    }
  }

  Future<void> _fetchCurrentUserData() async {
    try {
      DocumentSnapshot? userDoc = await _firestore
          .collection('teachers')
          .doc(uid.value)
          .get();
      if (!userDoc.exists) {
        userDoc = await _firestore.collection('students').doc(uid.value).get();
      }
      if (userDoc.exists) {
        student.value = Student.fromMap(userDoc.data() as Map<String, dynamic>);
      }
    } catch (e) {
      print('❌ Error fetching user data: $e');
    }
  }

  void _setupParentLeaveNotifications(String studentId) {
    try {
      _leaveSubscription?.cancel();
      _leaveSubscription = _firestore
          .collection('students')
          .doc(studentId)
          .collection('leave')
          .orderBy('submittedAt', descending: true)
          .snapshots()
          .listen(
            (snapshot) {
              final List<NotificationModel> leaveNotifications = [];
              for (var leaveDoc in snapshot.docs) {
                final leave = LeaveModel.fromFirestore(leaveDoc).copyWith(
                  id: leaveDoc.id,
                  uid: studentId,
                  fullName: parentStudentData.value?['fullName'],
                );
                final notification = NotificationModel.parentLeaveUpdate(leave);
                if (_deletedNotifications.contains(notification.id)) continue;
                leaveNotifications.add(
                  notification.copyWith(
                    isRead: _readNotifications.contains(notification.id),
                  ),
                );
              }
              _updateLeaveNotifications(leaveNotifications);
            },
            onError: (error) {
              print('❌ Error in parent leave notifications: $error');
            },
          );
    } catch (e) {
      print('❌ Error setting up parent leave notifications: $e');
    }
  }

  void _setupStudentLeaveNotifications(String studentId) {
    try {
      _leaveSubscription?.cancel();
      _leaveSubscription = _firestore
          .collection('students')
          .doc(studentId)
          .collection('leave')
          .orderBy('submittedAt', descending: true)
          .snapshots()
          .listen(
            (snapshot) {
              final List<NotificationModel> leaveNotifications = [];
              for (var leaveDoc in snapshot.docs) {
                final leave = LeaveModel.fromFirestore(
                  leaveDoc,
                ).copyWith(id: leaveDoc.id, uid: studentId);
                final notification = NotificationModel.fromLeaveModel(leave);
                if (_deletedNotifications.contains(notification.id)) continue;
                leaveNotifications.add(
                  notification.copyWith(
                    isRead: _readNotifications.contains(notification.id),
                  ),
                );
              }
              _updateLeaveNotifications(leaveNotifications);
            },
            onError: (error) {
              print('❌ Error in student leave notifications: $error');
            },
          );
    } catch (e) {
      print('❌ Error setting up student leave notifications: $e');
    }
  }

  void _setupTeacherLeaveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? department = prefs.getString('department');

      if (department == null || department.isEmpty) {
        print('⚠️ Department not found in SharedPreferences');
        return;
      }

      _allStudentsLeaveSubscription?.cancel();

      _allStudentsLeaveSubscription = FirebaseFirestore.instance
          .collection('students')
          .where("department", isEqualTo: department)
          .snapshots()
          .asyncMap((studentSnapshot) async {
            List<NotificationModel> allNotifications = [];

            for (var studentDoc in studentSnapshot.docs) {
              try {
                var leaveSnapshot = await studentDoc.reference
                    .collection('leave')
                    .orderBy('submittedAt', descending: true)
                    .limit(10)
                    .get();

                for (var leaveDoc in leaveSnapshot.docs) {
                  final leave = LeaveModel.fromFirestore(leaveDoc).copyWith(
                    id: leaveDoc.id,
                    uid: studentDoc.id,
                    fullName: studentDoc['fullName'],
                    rollNumber: studentDoc['rollNumber'],
                    department: studentDoc['department'],
                  );

                  final notification = NotificationModel.newLeaveRequest(leave);

                  if (_deletedNotifications.contains(notification.id)) continue;

                  allNotifications.add(
                    notification.copyWith(
                      isRead: _readNotifications.contains(notification.id),
                    ),
                  );
                }
              } catch (e) {
                print('❌ Error processing student ${studentDoc.id}: $e');
              }
            }

            return allNotifications;
          })
          .listen(
            (allNotifications) {
              _updateLeaveNotifications(allNotifications);
            },
            onError: (error) {
              print('❌ Error in teacher leave notifications: $error');
            },
          );
    } catch (e) {
      print('❌ Error setting up teacher leave notifications: $e');
    }
  }

  void _setupParentProfileNotifications(String studentId) {
    try {
      _profileSubscription?.cancel();
      _profileSubscription = _firestore
          .collection('students')
          .doc(studentId)
          .snapshots()
          .listen(
            (docSnapshot) {
              if (docSnapshot.exists) {
                final newStudentData = docSnapshot.data()!;
                final newHash = _generateProfileHash(newStudentData);
                final lastHash = _lastProfileHash[studentId];

                if (lastHash != null && lastHash != newHash) {
                  final profileNotification = NotificationModel.profileUpdate(
                    'Your child\'s profile information has been updated',
                    studentName: newStudentData['fullName'],
                    userId: studentId,
                  );
                  _addUniqueNotification(profileNotification);
                }

                _lastProfileHash[studentId] = newHash;
                _saveNotificationStatesToStorage();
                parentStudentData.value = newStudentData;
                student.value = Student.fromMap(newStudentData);
              }
            },
            onError: (error) {
              print('❌ Error in parent profile notifications: $error');
            },
          );
    } catch (e) {
      print('❌ Error setting up parent profile notifications: $e');
    }
  }

  void _setupProfileNotifications(String userId) {
    try {
      _profileSubscription?.cancel();
      String collection = isTeacher.value ? 'teachers' : 'students';
      _profileSubscription = _firestore
          .collection(collection)
          .doc(userId)
          .snapshots()
          .listen(
            (docSnapshot) {
              if (docSnapshot.exists) {
                final newProfileData = docSnapshot.data()!;
                final newHash = _generateProfileHash(newProfileData);
                final lastHash = _lastProfileHash[userId];

                if (lastHash != null && lastHash != newHash) {
                  final profileNotification = NotificationModel.profileUpdate(
                    'Your profile information has been updated successfully',
                    userId: userId,
                  );
                  _addUniqueNotification(profileNotification);
                }

                _lastProfileHash[userId] = newHash;
                _saveNotificationStatesToStorage();
                student.value = Student.fromMap(newProfileData);
              }
            },
            onError: (error) {
              print('❌ Error in profile notifications: $error');
            },
          );
    } catch (e) {
      print('❌ Error setting up profile notifications: $e');
    }
  }

  void _updateLeaveNotifications(List<NotificationModel> leaveNotifications) {
    notifications.removeWhere(
      (notif) =>
          notif.type == NotificationType.leaveApproved ||
          notif.type == NotificationType.leaveRejected ||
          notif.type == NotificationType.leavePending ||
          notif.type == NotificationType.leaveSubmitted ||
          notif.type == NotificationType.newLeaveRequest ||
          notif.type == NotificationType.leaveStatusChanged,
    );

    notifications.addAll(leaveNotifications);
    notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    _updateUnreadCount();
    _saveNotificationsToStorage();
  }

  void _addUniqueNotification(NotificationModel notification) {
    final existingIndex = notifications.indexWhere(
      (notif) => notif.id == notification.id,
    );
    if (existingIndex == -1 &&
        !_deletedNotifications.contains(notification.id)) {
      final updatedNotification = notification.copyWith(
        isRead: _readNotifications.contains(notification.id),
      );
      notifications.insert(0, updatedNotification);
      _updateUnreadCount();
      _saveNotificationsToStorage();
    }
  }

  void _updateUnreadCount() {
    unreadCount.value = notifications
        .where((notif) => !notif.isRead && !notif.isDeleted)
        .length;
  }

  Future<void> refreshNotifications() async {
    isRefreshing.value = true;
    await initializeNotifications();
    isRefreshing.value = false;
  }

  Future<void> markAsRead(String notificationId) async {
    final index = notifications.indexWhere(
      (notif) => notif.id == notificationId,
    );
    if (index != -1 && !notifications[index].isRead) {
      notifications[index] = notifications[index].copyWith(isRead: true);
      _readNotifications.add(notificationId);
      _updateUnreadCount();
      await _saveNotificationStateToFirestore(notificationId, isRead: true);
    }
  }

  Future<void> markAllAsRead() async {
    List<Future> futures = [];
    for (int i = 0; i < notifications.length; i++) {
      if (!notifications[i].isRead) {
        notifications[i] = notifications[i].copyWith(isRead: true);
        _readNotifications.add(notifications[i].id);
        futures.add(
          _saveNotificationStateToFirestore(notifications[i].id, isRead: true),
        );
      }
    }
    await Future.wait(futures);
    _updateUnreadCount();
  }

  Future<void> deleteNotification(String notificationId) async {
    await _saveNotificationStateToFirestore(notificationId, isDeleted: true);
    _deletedNotifications.add(notificationId);
    notifications.removeWhere((notif) => notif.id == notificationId);
    _updateUnreadCount();
  }

  Future<void> clearAllNotifications() async {
    List<Future> futures = [];
    for (final notif in notifications) {
      futures.add(_saveNotificationStateToFirestore(notif.id, isDeleted: true));
      _deletedNotifications.add(notif.id);
    }
    await Future.wait(futures);
    notifications.clear();
    unreadCount.value = 0;
  }

  void addNotification(String title, String message, {NotificationType? type}) {
    final notification = NotificationModel.general(title, message);
    notifications.insert(0, notification);
    _updateUnreadCount();
  }

  List<NotificationModel> getNotificationsByType(NotificationType type) {
    return notifications.where((notif) => notif.type == type).toList();
  }

  List<NotificationModel> getRecentNotifications() {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return notifications
        .where((notif) => notif.timestamp.isAfter(weekAgo))
        .toList();
  }

  List<NotificationModel> getLeaveNotifications() {
    return notifications
        .where(
          (notif) =>
              notif.type == NotificationType.leaveApproved ||
              notif.type == NotificationType.leaveRejected ||
              notif.type == NotificationType.leavePending ||
              notif.type == NotificationType.leaveSubmitted ||
              notif.type == NotificationType.newLeaveRequest ||
              notif.type == NotificationType.leaveStatusChanged,
        )
        .toList();
  }

  String get studentName {
    if (isParent.value && parentStudentData.value != null) {
      return parentStudentData.value!['fullName'] ?? 'Student';
    }
    return student.value?.fullName ?? 'User';
  }

  String get currentUserName {
    if (isParent.value) {
      return userEmail.value.split('@')[0];
    }
    return student.value?.fullName ?? userEmail.value.split('@')[0];
  }

  bool get hasNotifications => notifications.isNotEmpty;
  bool get hasUnreadNotifications => unreadCount.value > 0;
  bool get isCurrentUserParent => userRole.value == 'parent' || isParent.value;
  bool get isCurrentUserTeacher =>
      userRole.value == 'teacher' || isTeacher.value;

  String get currentUserRole => userRole.value;
  String get currentUserEmail => userEmail.value;
  String get currentUserId => uid.value;

  String get notificationWelcomeMessage {
    if (isParent.value) {
      return 'Stay updated with your child\'s activities';
    } else if (isTeacher.value) {
      return 'Manage student notifications and updates';
    } else {
      return 'Stay updated with your activities';
    }
  }

  Map<String, int> get notificationStats {
    final stats = {
      'total': notifications.length,
      'unread': unreadCount.value,
      'leave': 0,
      'profile': 0,
      'general': 0,
    };

    for (final notif in notifications) {
      switch (notif.type) {
        case NotificationType.leaveApproved:
        case NotificationType.leaveRejected:
        case NotificationType.leavePending:
        case NotificationType.leaveSubmitted:
        case NotificationType.newLeaveRequest:
        case NotificationType.leaveStatusChanged:
          stats['leave'] = stats['leave']! + 1;
          break;
        case NotificationType.profileUpdate:
          stats['profile'] = stats['profile']! + 1;
          break;
        case NotificationType.general:
        case NotificationType.systemAlert:
          stats['general'] = stats['general']! + 1;
          break;
      }
    }

    return stats;
  }

  Future<void> _saveNotificationStateToFirestore(
    String notificationId, {
    bool? isRead,
    bool? isDeleted,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('uid');
      bool isParentUser = prefs.getBool('isParent') ?? false;
      bool isTeacherUser = prefs.getBool('isTeacher') ?? false;

      String collection = isTeacherUser ? 'teachers' : 'students';

      if (isParentUser && parentStudentData.value != null) {
        print("📦 Full parentStudentData: ${parentStudentData.value}");
        print("🗂️ Available keys: ${parentStudentData.value?.keys}");

        final sid = parentStudentData.value!['parentUid']
            ?.toString(); // <- FIXED HERE

        if (sid == null || sid.isEmpty) {
          print("❌ student UID in parentStudentData is null or empty");
          return;
        }

        userId = sid;
        collection = 'students';

        print("👨‍👩‍👧 Parent's student UID: 🎯 $userId");
      }

      if (userId == null || userId.isEmpty) {
        print("❌ UID is null or empty. Cannot update Firestore.");
        return;
      }

      print("👤 Using user ID: 🚀 $userId");
      print("📚 Firestore collection: $collection");

      Map<String, dynamic> updateData = {};
      if (isRead != null) updateData['isRead'] = isRead;
      if (isDeleted != null) updateData['isDeleted'] = isDeleted;
      updateData['lastUpdated'] = FieldValue.serverTimestamp();

      await _firestore
          .collection(collection)
          .doc(userId)
          .collection('notification_states')
          .doc(notificationId)
          .set(updateData, SetOptions(merge: true));

      print("✅ Notification state saved for userId: $userId");
    } catch (e, stackTrace) {
      print('❌ Error saving notification state to Firestore: $e');
      print('🧵 Stack Trace:\n$stackTrace');
    }
  }
}
