import 'package:digislips/app/core/theme/app_colors.dart';
import 'package:digislips/app/core/theme/app_text_styles.dart';
import 'package:digislips/app/modules/logout/logout_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LogoutPage extends StatelessWidget {
  final LogoutController controller = Get.put(LogoutController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.background,
              AppColors.primary.withOpacity(0.05),
              AppColors.secondary.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: AnimatedBuilder(
              animation: controller.fadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: controller.fadeAnimation.value,
                  child: Column(
                    children: [
                      _buildHeader(),
                      Expanded(
                        child: Center(
                          child: SlideTransition(
                            position: controller.slideAnimation,
                            child: _buildLogoutCard(),
                          ),
                        ),
                      ),
                      _buildActionButtons(),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.only(top: 20, bottom: 40),
      child: Row(
        children: [
          GestureDetector(
            onTap: controller.cancelLogout,
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: AppColors.greyColor,
                size: 20,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Logout',
              style: AppTextStyles.title.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(width: 44), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildLogoutCard() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 10),
      padding: EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 30,
            offset: Offset(0, 15),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: AppColors.primary.withOpacity(0.05),
            blurRadius: 20,
            offset: Offset(0, 8),
            spreadRadius: -5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLogoutIcon(),
          SizedBox(height: 32),
          _buildLogoutTitle(),
          SizedBox(height: 16),
          _buildLogoutMessage(),
          SizedBox(height: 32),
          _buildLogoutProgress(),
        ],
      ),
    );
  }

  Widget _buildLogoutIcon() {
    return AnimatedBuilder(
      animation: controller.pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: controller.pulseAnimation.value,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.error,
                  AppColors.error.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.error.withOpacity(0.3),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Icon(
              Icons.logout_rounded,
              color: Colors.white,
              size: 45,
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogoutTitle() {
    return Text(
      'Are you leaving?',
      style: AppTextStyles.title.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.blackColor,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildLogoutMessage() {
    return Column(
      children: [
        Text(
          'We\'re sad to see you go!',
          style: AppTextStyles.body.copyWith(
            fontSize: 16,
            color: AppColors.greyColor,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8),
        Text(
          'Are you sure you want to logout from your account?',
          style: AppTextStyles.body.copyWith(
            fontSize: 14,
            color: AppColors.textGrey,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLogoutProgress() {
    return Obx(() {
      if (!controller.isLoggingOut.value) return SizedBox.shrink();
      
      return Column(
        children: [
          SizedBox(height: 20),
          Text(
            'Logging out...',
            style: AppTextStyles.body.copyWith(
              fontSize: 14,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.lightGrey,
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: controller.logoutProgress.value,
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            '${(controller.logoutProgress.value * 100).toInt()}%',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildActionButtons() {
    return Obx(() {
      if (controller.isLoggingOut.value) return SizedBox.shrink();
      
      return Column(
        children: [
          _buildPrimaryButton(),
          SizedBox(height: 16),
          _buildSecondaryButton(),
        ],
      );
    });
  }

  Widget _buildPrimaryButton() {
    return GestureDetector(
      onTap: controller.confirmLogout,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.error,
              AppColors.error.withOpacity(0.8),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.error.withOpacity(0.4),
              blurRadius: 15,
              offset: Offset(0, 8),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.logout_rounded,
              color: Colors.white,
              size: 22,
            ),
            SizedBox(width: 12),
            Text(
              'Yes, Logout',
              style: AppTextStyles.buttonText.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryButton() {
    return GestureDetector(
      onTap: controller.cancelLogout,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.borderColor,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.close_rounded,
              color: AppColors.greyColor,
              size: 22,
            ),
            SizedBox(width: 12),
            Text(
              'Cancel',
              style: AppTextStyles.buttonText.copyWith(
                color: AppColors.greyColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Alternative Minimal Logout Dialog (Optional)
class LogoutDialog extends StatelessWidget {
  final LogoutController controller = Get.put(LogoutController());

  static void show() {
    Get.dialog(
      LogoutDialog(),
      barrierDismissible: false,
      transitionDuration: Duration(milliseconds: 300),
      transitionCurve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: EdgeInsets.all(20),
        padding: EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 30,
              offset: Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.error, AppColors.error.withOpacity(0.7)],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.logout_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Logout Confirmation',
              style: AppTextStyles.title.copyWith(fontSize: 22),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              'Are you sure you want to logout?',
              style: AppTextStyles.body.copyWith(fontSize: 15),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.lightGrey,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Cancel',
                        style: AppTextStyles.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: controller.confirmLogout,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.error, AppColors.error.withOpacity(0.8)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Logout',
                        style: AppTextStyles.buttonText,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}