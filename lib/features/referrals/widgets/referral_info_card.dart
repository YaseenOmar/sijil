import 'package:flutter/material.dart';
import 'package:sijil/core/theme/app_colors.dart';

// White bordered card that holds rows or text (presentational only)
class ReferralInfoCard extends StatelessWidget {
  final List<Widget> children;

  const ReferralInfoCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
