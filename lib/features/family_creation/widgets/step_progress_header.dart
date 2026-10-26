import 'package:flutter/material.dart';
import 'package:sijil/core/theme/app_colors.dart';
import 'package:sijil/features/family_creation/utils/text_utils.dart';

// "الخطوة ٢ من ٣" + progress bars + section title
class StepProgressHeader extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final String sectionTitle;

  const StepProgressHeader({
    super.key,
    required this.currentStep,
    required this.sectionTitle,
    this.totalSteps = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الخطوة ${toArabicDigits(currentStep)} من ${toArabicDigits(totalSteps)}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),

        const SizedBox(height: 8),

        Row(
          children: List.generate(totalSteps, (index) {
            final bool isDone = index < currentStep;

            return Expanded(
              child: Padding(
                padding: EdgeInsetsDirectional.only(
                  end: index == totalSteps - 1 ? 0 : 8,
                ),
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDone ? AppColors.primary : AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            );
          }),
        ),

        const SizedBox(height: 16),

        Text(
          sectionTitle,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
