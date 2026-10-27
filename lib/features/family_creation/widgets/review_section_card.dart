import 'package:flutter/material.dart';
import 'package:sijil/core/theme/app_colors.dart';

// One review section with an optional "تعديل" action.
// titleOutside = true  -> title row above the card (review screen)
// titleOutside = false -> title inside the card (duplicate screen)
class ReviewSectionCard extends StatelessWidget {
  final String title;
  final VoidCallback? onEdit;
  final List<Widget> children;
  final bool titleOutside;

  const ReviewSectionCard({
    super.key,
    required this.title,
    required this.children,
    this.onEdit,
    this.titleOutside = false,
  });

  @override
  Widget build(BuildContext context) {
    final Widget titleRow = Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: titleOutside ? 18 : 16,
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
    );

    final Widget card = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!titleOutside) ...[titleRow, const SizedBox(height: 8)],
          ...children,
        ],
      ),
    );

    if (!titleOutside) return card;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [titleRow, const SizedBox(height: 8), card],
    );
  }
}

// One "label above value" block inside a review card
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 4),

          Align(
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
        ],
      ),
    );
  }
}

// Small green pill inside a review card (ex: "صورة الهوية محفوظة محلياً")
class ReviewBadge extends StatelessWidget {
  final String text;

  const ReviewBadge({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.successBackground,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.success,
            ),
          ),
        ),
      ),
    );
  }
}
