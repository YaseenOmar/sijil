import 'package:flutter/material.dart';
import 'package:sijil/core/theme/app_colors.dart';
import 'package:sijil/core/widgets/app_button.dart';
import 'package:sijil/features/referrals/models/referral_model.dart';
import 'package:sijil/features/referrals/utils/referral_formatters.dart';
import 'package:sijil/features/referrals/widgets/referral_status_badge.dart';

// One referral in the list (presentational only)
class ReferralCard extends StatelessWidget {
  final ReferralModel referral;
  final bool isIncoming;
  final VoidCallback onTap;

  const ReferralCard({
    super.key,
    required this.referral,
    required this.onTap,
    this.isIncoming = false,
  });

  @override
  Widget build(BuildContext context) {
    final String route = isIncoming
        ? 'من ${referral.fromOrg} · ${referral.service}'
        : '${referral.service} ← ${referral.toOrg}';

    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ReferralStatusBadge(status: referral.status),

              const SizedBox(height: 8),

              Text(
                referral.familyName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                route,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                referralProgressNote(referral),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),

              if (referral.status == ReferralStatus.completed) ...[
                const SizedBox(height: 16),
                AppButton(
                  text: 'عرض التفاصيل والنتيجة',
                  type: AppButtonType.secondary,
                  onPressed: onTap,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
