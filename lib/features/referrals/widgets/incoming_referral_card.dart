
import 'package:flutter/material.dart';
import 'package:sijil/core/theme/app_colors.dart';
import 'package:sijil/core/widgets/app_button.dart';

import 'package:sijil/features/family_creation/utils/text_utils.dart';

import '../models/referral_model.dart';
import '../utils/referral_formatters.dart';
import 'referral_status_badge.dart';

class IncomingReferralCard extends StatelessWidget {
  final ReferralModel referral;
  final VoidCallback onTap;

  const IncomingReferralCard({
    super.key,
    required this.referral,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isWaiting =
        referral.status == ReferralStatus.pendingTargetApproval;

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
        children: [
          // Status
          ReferralStatusBadge(
            status: referral.status,
            label: isWaiting
                ? 'بانتظار قرار الجهة المستقبلة'
                : null,
          ),

          const SizedBox(height: 16),

          // Family name
          Text(
            referral.familyName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 16),

          // Referral information
          _InfoRow(
            label: 'الجهة المحيلة',
            value: referral.sourceOrganizationName,
          ),

          _InfoRow(
            label: 'الخدمة المطلوبة',
            value: referral.serviceName,
          ),

          _InfoRow(
            label: 'تاريخ إرسال الإحالة',
            value: formatDateTime(
              referral.sourceApprovedAt ?? referral.createdAt,
            ),
          ),

          Text(
            '${membersLabel(referral.membersCount)} · '
                'المنطقة: ${referral.areaId} · '
                'بيانات الإحالة فقط',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 16),

          // Review / details button
          AppButton(
            text: isWaiting
                ? 'مراجعة الإحالة الواردة'
                : 'عرض الإحالة',
            type: isWaiting
                ? AppButtonType.primary
                : AppButtonType.secondary,
            onPressed: onTap,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

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
