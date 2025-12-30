import 'package:digislips/app/modules/auth/Registration/Registration.dart';
import 'package:digislips/app/modules/auth/controllers/registration_controller.dart';
import 'package:digislips/app/modules/auth/login/login_page.dart';
import 'package:digislips/app/modules/dashboard/dashboard.dart';
import 'package:digislips/app/modules/leave/leave%20history/leave_history_controller.dart';
import 'package:digislips/app/modules/leave/leave%20history/leave_history_page.dart';
import 'package:digislips/app/modules/splash_screen/splash_screen.dart';
import 'package:digislips/app/shared/widgets/bottomnavigation/bottomnavigation.dart';
import 'package:digislips/app/shared/widgets/bottomnavigation/navigation_controller.dart';
import 'package:get/get.dart';

class Routes {
  static const SPLASH = '/splash'; // Add splash route
  static const HOME = '/home';
  static const LOGIN = '/login';
  static const APPLY_LEAVE = '/apply-leave';
  static const STUDENT_REGISTRATION = '/student-registration';
  static const BOTTOM_NAVIGATION = '/bottom-navigation';
  static const LEAVE_STATUS = '/leave-status';
  static const hsitory_page = '/history-page';
}

class AppPages {
  static const INITIAL = Routes.SPLASH; // Change initial to splash

  static final routes = [
    GetPage(
      name: Routes.SPLASH,
      page: () => SplashScreen(),
    ), // Add splash page here
    GetPage(name: Routes.HOME, page: () => HomeView()),
    GetPage(name: Routes.LOGIN, page: () => LoginScreen()),

    GetPage(
      name: Routes.STUDENT_REGISTRATION,
      page: () => RegistrationScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<RegistrationController>(() => RegistrationController());
      }),
    ),
    GetPage(
      name: Routes.BOTTOM_NAVIGATION,
      page: () => BottomNavBarWidget(),
      binding: BindingsBuilder(() {
        Get.lazyPut<BottomNavController>(() => BottomNavController());
      }),
    ),
    GetPage(
      name: Routes.hsitory_page,
      page: () => LeaveHistoryPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<LeaveHistoryController>(() => LeaveHistoryController());
      }),
    ),
  ];
}
