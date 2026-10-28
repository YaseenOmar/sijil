import 'package:flutter/material.dart';
import 'package:sijil/core/theme/app_colors.dart';
import 'package:sijil/features/staff/constants/staff_options.dart';

// "معاينة الصلاحيات": what the new account will be able to do (presentational only)
class PermissionsPreviewCard extends StatelessWidget {
  final String name;
  final String? areaName;
  final String? role;

  const PermissionsPreviewCard({
    super.key,
    required this.name,
    required this.areaName,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    final RolePermissions? permissions = role == null
        ? null
        : StaffOptions.roles[role];

    final bool isReady = permissions != null && areaName != null;

    // First name only, like the design
    final String displayName = name.isEmpty ? 'الموظف' : name.split(' ').first;

    final String scope = isReady
        ? permissions.scope
              .replaceAll('{name}', displayName)
              .replaceAll('{area}', areaName!)
        : 'اختر الدور والمنطقة لعرض الصلاحيات.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'معاينة الصلاحيات',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            scope,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.textPrimary,
            ),
          ),

          if (isReady) ...[
            const SizedBox(height: 8),
            Text(
              permissions.limits,
              style: const TextStyle(
                fontSize: 12,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],

          const SizedBox(height: 16),

          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.neutralBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'لم يُنشأ الحساب بعد',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
