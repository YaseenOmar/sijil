import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sijil/core/theme/app_colors.dart';
import 'package:sijil/core/widgets/app_button.dart';
import 'package:sijil/core/widgets/app_status_card.dart';
import 'package:sijil/features/family_creation/utils/text_utils.dart';
import 'package:sijil/features/referrals/models/referral_model.dart';
import 'package:sijil/features/referrals/utils/referral_formatters.dart';
import 'package:sijil/features/referrals/widgets/referral_flow_scaffold.dart';
import 'package:sijil/features/referrals/widgets/referral_info_card.dart';
import 'package:sijil/features/referrals/widgets/referral_summary_card.dart';
import 'package:sijil/features/referrals/widgets/referral_timeline.dart';

// Referral details: summary, timeline and the service result
// Open it with: Get.to(() => ReferralDetailsScreen(referral: referral));
class ReferralDetailsScreen extends StatelessWidget {
  final ReferralModel referral;

  const ReferralDetailsScreen({super.key, required this.referral});

  @override
  Widget build(BuildContext context) {
    final List<ReferralStep> steps = referral.steps;

    return ReferralFlowScaffold(
      title: 'تفاصيل الإحالة',
      breadcrumb: ' مسار الخدمة',
      subtitleLine: 'الإحالة ${toArabicDigits(referral.number)} · صادرة',
      children: [
        ReferralSummaryCard(referral: referral),

        const SizedBox(height: 24),

        const Text(
          'مسار الإحالة',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),

        const SizedBox(height: 16),

        // Empty state: the referral was not sent yet
        if (steps.isEmpty)
          const AppStatusCard(
            title: 'لم تُرسل الإحالة بعد',
            message: 'الإحالة محفوظة على الجهاز وبانتظار الإرسال.',
            type: AppStatusType.offline,
          )
        else
          ReferralTimeline(steps: steps),

        if (referral.result != null) ...[
          const SizedBox(height: 24),

          const Text(
            'نتيجة الخدمة',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 16),

          ReferralInfoCard(
            children: [
              Text(
                referral.result!,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.textPrimary,
                ),
              ),
              if (referral.resultNote != null) ...[
                const SizedBox(height: 8),
                Text(
                  referral.resultNote!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ],

        if (referral.status == ReferralStatus.completed &&
            referral.notifiedAt != null) ...[
          const SizedBox(height: 24),

          AppStatusCard(
            title: 'أُبلغ الموظف المحيل بإتمام الخدمة',
            message:
                'وصل إشعار إلى ${referral.sentBy ?? '-'} بتاريخ ${formatDateTime(referral.notifiedAt!)}. وتظهر تحديثات كل مرحلة في مركز الإشعارات.',
            type: AppStatusType.success,
          ),
        ],

        const SizedBox(height: 24),

        AppButton(
          text: 'العودة إلى الإحالات',
          type: AppButtonType.secondary,
          onPressed: () => Get.back(),
        ),
      ],
    );
  }
}
