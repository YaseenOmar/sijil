import 'package:flutter/material.dart';
import 'package:sijil/core/theme/app_colors.dart';
import 'package:sijil/features/referrals/models/referral_model.dart';

// Top card of the referral details (green when the service was delivered)
class ReferralSummaryCard extends StatelessWidget {
  final ReferralModel referral;

  const ReferralSummaryCard({super.key, required this.referral});

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = referral.status == ReferralStatus.completed;
    final Color labelColor = isCompleted
        ? AppColors.success
        : AppColors.textSecondary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCompleted ? AppColors.successBackground : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: isCompleted ? null : Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            referral.status.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: labelColor,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            referral.familyName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 16),

          _SummaryRow(label: 'الجهة المستقبلة', value: referral.toOrg),
          _SummaryRow(label: 'الخدمة', value: referral.service),

          Text(
            'السبب: ${referral.reason}',
            style: const TextStyle(
              fontSize: 12,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
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
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
