
import 'package:flutter/material.dart';
import 'package:sijil/core/theme/app_colors.dart';
import 'package:sijil/core/widgets/app_button.dart';

import '../models/referral_model.dart';
import '../utils/referral_formatters.dart';
import 'referral_status_badge.dart';

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
        ? 'من ${referral.sourceOrganizationName} · '
        '${referral.serviceName}'
        : '${referral.serviceName} ← '
        '${referral.targetOrganizationName}';

    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(
          color: AppColors.border,
        ),
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
              // Referral status
              ReferralStatusBadge(
                status: referral.status,
              ),

              const SizedBox(height: 8),

              // Family name
              Text(
                referral.familyName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 4),

              // Service and organization
              Text(
                route,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 4),

              // Referral progress
              Text(
                referralProgressNote(referral),
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 16),

              // Details button
              AppButton(
                text: referral.status == ReferralStatus.completed
                    ? 'عرض التفاصيل والنتيجة'
                    : 'عرض تفاصيل الإحالة',
                type: AppButtonType.secondary,
                onPressed: onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
