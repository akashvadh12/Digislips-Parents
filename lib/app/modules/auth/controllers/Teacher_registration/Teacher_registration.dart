import 'package:digislips/app/core/theme/app_colors.dart';
import 'package:digislips/app/modules/auth/controllers/Teacher_registration/Teacher_registration_controller.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TeacherRegistrationPage extends StatelessWidget {
  final TeacherRegistrationController controller = Get.put(
    TeacherRegistrationController(),
  );

  TeacherRegistrationPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Teacher Registration',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Text
            const Text(
              'Create Teacher Account',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Fill in the details below to create your teacher account',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your unique ID will be generated automatically',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 32),

            // Full Name Field
            _buildTextField(
              controller: controller.fullNameController,
              label: 'Full Name',
              icon: Icons.person,
              hintText: 'Enter your full name',
            ),
            const SizedBox(height: 16),

            // Email Field
            _buildTextField(
              controller: controller.emailController,
              label: 'Email',
              icon: Icons.email,
              hintText: 'Enter your email',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            // Phone Field
            _buildTextField(
              controller: controller.phoneController,
              label: 'Phone Number',
              icon: Icons.phone,
              hintText: 'Enter your phone number',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),

            // Department Selection
            _buildDepartmentDropdown(),
            const SizedBox(height: 16),

            const SizedBox(height: 16),

            // Password Field
            Obx(
              () => _buildPasswordField(
                controller: controller.passwordController,
                label: 'Password',
                isHidden: controller.isPasswordHidden.value,
                onToggle: controller.togglePasswordVisibility,
              ),
            ),
            const SizedBox(height: 8),

            // Password Requirements
            Obx(() => _buildPasswordRequirements()),
            const SizedBox(height: 16),

            // Confirm Password Field
            Obx(
              () => _buildPasswordField(
                controller: controller.confirmPasswordController,
                label: 'Confirm Password',
                isHidden: controller.isConfirmPasswordHidden.value,
                onToggle: controller.toggleConfirmPasswordVisibility,
              ),
            ),
            const SizedBox(height: 32),

            // Register Button
            Obx(
              () => SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: controller.isLoading.value
                      ? null
                      : controller.registerTeacher,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: controller.isLoading.value
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        )
                      : const Text(
                          'Register',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Login Link
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Already have an account? ',
                  style: TextStyle(color: Colors.grey),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text(
                    'Login',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hintText,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.primary),
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDepartmentDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Department',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Obx(
          () => Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonFormField<String>(
              value: controller.selectedDepartment.value,
              onChanged: controller.selectDepartment,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.school, color: AppColors.primary),
                hintText: 'Select your department',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
              ),
              items: controller.departments.map((String department) {
                return DropdownMenuItem<String>(
                  value: department,
                  child: Text(
                    department,
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isHidden,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isHidden,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.lock, color: AppColors.primary),
            suffixIcon: IconButton(
              icon: Icon(
                isHidden ? Icons.visibility : Icons.visibility_off,
                color: AppColors.primary,
              ),
              onPressed: onToggle,
            ),
            hintText: 'Enter your password',
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordRequirements() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Password Requirements:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          _buildRequirementItem(
            'At least 8 characters',
            controller.hasMinLength.value,
          ),
          _buildRequirementItem(
            'One uppercase letter',
            controller.hasUppercase.value,
          ),
          _buildRequirementItem(
            'One lowercase letter',
            controller.hasLowercase.value,
          ),
          _buildRequirementItem('One number', controller.hasNumber.value),
          _buildRequirementItem(
            'One special character',
            controller.hasSpecialChar.value,
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(String requirement, bool isValid) {
    return Row(
      children: [
        Icon(
          isValid ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isValid ? Colors.green : Colors.grey,
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          requirement,
          style: TextStyle(
            fontSize: 12,
            color: isValid ? Colors.green : Colors.grey,
          ),
        ),
      ],
    );
  }
}
