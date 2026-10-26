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
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(imagePath!),
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  cacheWidth: 160,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 56,
                    height: 56,
                    color: AppColors.neutralBackground,
                    child: const Icon(
                      Icons.image_not_supported_outlined,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                      'الحجم: ${toArabicDigits(sizeKb)} كيلوبايت · محفوظة محلياً',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: 'استبدال الصورة',
                  type: AppButtonType.secondary,
                  onPressed: onPick,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppButton(
                  text: 'إزالة المرفق',
                  type: AppButtonType.secondary,
                  onPressed: onRemove,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
