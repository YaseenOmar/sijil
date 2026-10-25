import 'package:flutter/material.dart';
import 'package:sijil/core/theme/app_colors.dart';

// Card for one review section with an optional "تعديل" action
class ReviewSectionCard extends StatelessWidget {
  final String title;
  final VoidCallback? onEdit;
  final List<Widget> children;

  const ReviewSectionCard({
    super.key,
    required this.title,
    required this.children,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
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
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (onEdit != null)
                TextButton(
                  onPressed: onEdit,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    minimumSize: const Size(48, 48),
                  ),
                  child: const Text(
                    'تعديل',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 8),

          ...children,
        ],
      ),
    );
  }
}

// One "label : value" line inside a review card
class ReviewRow extends StatelessWidget {
  final String label;
  final String value;

  // Use LTR for numbers like national ID and phone
  final TextDirection? valueDirection;

  const ReviewRow({
    super.key,
    required this.label,
    required this.value,
    this.valueDirection,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                value,
                textDirection: valueDirection,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
