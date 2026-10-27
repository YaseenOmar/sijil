import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sijil/core/theme/app_colors.dart';
import 'package:sijil/core/widgets/app_button.dart';
import 'package:sijil/features/family_creation/utils/text_utils.dart';

// Optional ID card image: attach / replace / remove (presentational only)
class IdCardImageField extends StatelessWidget {
  final String? imagePath;
  final int sizeKb;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const IdCardImageField({
    super.key,
    required this.imagePath,
    required this.sizeKb,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    // Empty state: direct next action
    if (imagePath == null) {
      return AppButton(
        text: 'إرفاق صورة الهوية',
        icon: Icons.photo_camera_outlined,
        type: AppButtonType.secondary,
        onPressed: onPick,
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Small preview on the end side of the card
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(imagePath!),
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                cacheWidth: 160,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 48,
                  height: 48,
                  color: AppColors.neutralBackground,
                  child: const Icon(
                    Icons.task_outlined,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'صورة الهوية مرفقة',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            'صورة واحدة · ${toArabicDigits(sizeKb)} كيلوبايت · محفوظة محلياً',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 8),

          // Image is local only until upload is added
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warningBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'بانتظار المزامنة',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.warning,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          AppButton(
            text: 'استبدال الصورة',
            icon: Icons.photo_camera_outlined,
            type: AppButtonType.secondary,
            onPressed: onPick,
          ),

          const SizedBox(height: 8),

          AppButton(
            text: 'إزالة المرفق',
            type: AppButtonType.secondary,
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
