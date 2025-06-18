import 'package:digislips/app/core/theme/app_them.dart';
import 'package:digislips/app/modules/auth/login/login_page.dart';
import 'package:digislips/app/modules/notification/notification_controller.dart';
import 'package:digislips/app/routes/app_pages.dart';
import 'package:digislips/app/shared/widgets/bottomnavigation/bottomnavigation.dart';
import 'package:digislips/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:get/get_navigation/src/routes/get_route.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');

  // You can add custom logic here to handle background notifications
  // For example, update local database, show custom notification, etc.
}

class FirebaseInitializer {
  static Future<void> initialize() async {
    try {
      // Initialize Firebase
      await Firebase.initializeApp();

      // Set background message handler
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // Initialize notification service
      // final notificationService = NotificationService();
      // await notificationService.initialize();

      // Handle initial message (when app is opened from terminated state)
      _handleInitialMessage();

      print('Firebase initialized successfully');
    } catch (e) {
      print('Error initializing Firebase: $e');
    }
  }

  static void _handleInitialMessage() {
    FirebaseMessaging.instance.getInitialMessage().then((
      RemoteMessage? message,
    ) {
      if (message != null) {
        print(
          'App opened from terminated state via notification: ${message.messageId}',
        );
        // Handle navigation or other actions based on the notification
        _handleNotificationNavigation(message.data);
      }
    });
  }

  static void _handleNotificationNavigation(Map<String, dynamic> data) {
    // Add delay to ensure app is fully initialized
    Future.delayed(const Duration(seconds: 2), () {
      final type = data['type'] as String?;
      final notificationId = data['notificationId'] as String?;

      // Navigate based on notification type
      switch (type) {
        case 'approved':
        case 'rejected':
          final leaveId = data['leaveId'] as String?;
          if (leaveId != null) {
            Get.toNamed('/leave-details', arguments: leaveId);
          } else {
            Get.toNamed('/notifications');
          }
          break;
        case 'document':
          final documentId = data['documentId'] as String?;
          if (documentId != null) {
            Get.toNamed('/document-details', arguments: documentId);
          } else {
            Get.toNamed('/notifications');
          }
          break;
        case 'comment':
          Get.toNamed('/notifications');
          break;
        default:
          Get.toNamed('/notifications');
          break;
      }

      // Mark notification as read if possible
      if (notificationId != null) {
        // You can get the notification controller and mark as read
        try {
          // final controller = Get.find<NotificationsController>();
          // controller.markAsRead(notificationId);
        } catch (e) {
          print('Could not mark notification as read: $e');
        }
      }
    });
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? uid = prefs.getString('uid');

  runApp(MyApp(isLoggedIn: uid != null));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'DigiSlips',
      debugShowCheckedModeBanner: false,
      initialRoute: Routes.SPLASH, // Splash is first screen on app start
      getPages: AppPages.routes,
      // other properties like theme, locale, etc.
    );
  }
}
