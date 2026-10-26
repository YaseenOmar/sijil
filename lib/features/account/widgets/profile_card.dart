import 'package:flutter/material.dart';
import 'package:sijil/core/theme/app_colors.dart';

class ProfileCard extends StatelessWidget {
  final String name;
  final String organization;
  final String role;
  final String area;
  final String email;

  const ProfileCard({
    super.key,
    required this.name,
    required this.organization,
    required this.role,
    required this.area,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.successBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Name
          Text(
            name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 12),

          // Organization
          infoItem('الجهة', organization),

          const SizedBox(height: 12),

          // User Role
          infoItem('دورك المعتمد', role),

          const SizedBox(height: 12),

          // Assigned Area
          infoItem('المنطقة المكلّف بها', area),

          const SizedBox(height: 12),

          // Email
          Text(
            email,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  // Reusable label and value
  Widget infoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
