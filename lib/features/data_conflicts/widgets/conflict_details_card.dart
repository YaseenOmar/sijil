import 'package:flutter/material.dart';
import 'package:sijil/core/theme/app_colors.dart';

// Card that holds the rows of one version (presentational only).
// isHighlighted = true  -> green card, the tag is a plain text (current value)
// isHighlighted = false -> white card, the tag is a small pill (previous value)
class ConflictDetailsCard extends StatelessWidget {
  final List<Widget> children;
  final String? tag;
  final bool isHighlighted;

  const ConflictDetailsCard({
    super.key,
    required this.children,
    this.tag,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHighlighted ? AppColors.successBackground : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: isHighlighted ? null : Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tag != null) _buildTag(),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTag() {
    if (isHighlighted) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          tag!,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.success,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.disabledBackground,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          tag!,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.neutral,
          ),
        ),
      ),
    );
  }
}
