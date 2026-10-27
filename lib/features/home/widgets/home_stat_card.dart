import 'package:flutter/material.dart';
import 'package:sijil/core/theme/app_colors.dart';

/// Data shown inside one statistic card.
class HomeStat {
  const HomeStat({required this.value, required this.label});

  final String value;
  final String label;
}

/// One statistic card (big number + description).
class HomeStatCard extends StatelessWidget {
  const HomeStatCard({super.key, required this.stat});

  final HomeStat stat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stat.value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            stat.label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
