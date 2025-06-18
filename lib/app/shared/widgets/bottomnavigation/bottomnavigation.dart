import 'package:digislips/app/core/theme/app_colors.dart';
import 'package:digislips/app/core/theme/app_text_styles.dart';
import 'package:digislips/app/modules/dashboard/dashboard.dart';
import 'package:digislips/app/modules/notification/notification_screen.dart';
import 'package:digislips/app/modules/setting/setting.dart';
import 'package:digislips/app/shared/widgets/bottomnavigation/navigation_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BottomNavBarWidget extends StatelessWidget {
  BottomNavBarWidget({super.key});

  final BottomNavController controller = Get.put(BottomNavController());

  final List<Widget> screens = [
    HomeView(),
    NotificationScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        body: screens[controller.selectedIndex.value],
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: controller.selectedIndex.value,
            onTap: controller.changeBottomNavIndex,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textGrey,
            selectedLabelStyle: AppTextStyles.bottomNavActiveLabel?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: AppTextStyles.bottomNavLabel,
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined, size: 24),
                activeIcon: Icon(Icons.home, size: 24),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.notifications_outlined, size: 24),
                activeIcon: Icon(Icons.notifications, size: 24),
                label: 'Notifications',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined, size: 24),
                activeIcon: Icon(Icons.settings, size: 24),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
