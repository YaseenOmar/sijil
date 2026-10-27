import 'package:flutter/material.dart';
import 'package:sijil/core/theme/app_colors.dart';
import 'package:sijil/core/widgets/app_button.dart';

/// "Quick actions" section.
///
/// Only [onAddFamily] is inside the sprint scope.
/// The two secondary buttons are visual only for now.
class HomeQuickActions extends StatelessWidget {
  const HomeQuickActions({super.key, required this.onAddFamily});

  final VoidCallback onAddFamily;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'إجراء سريع',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        AppButton(
          text: 'إضافة أسرة جديدة',
          icon: Icons.person_add_alt_1_outlined,
          onPressed: onAddFamily,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AppButton(
                text: 'تسجيل مساعدة',
                type: AppButtonType.secondary,
                onPressed: () {},
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppButton(
                text: 'إنشاء إحالة',
                type: AppButtonType.secondary,
                onPressed: () {},
              ),
            ),
          ],
        ),
      ],
    );
  }
}
