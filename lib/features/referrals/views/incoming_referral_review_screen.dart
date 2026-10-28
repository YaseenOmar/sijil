import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sijil/core/theme/app_colors.dart';
import 'package:sijil/core/widgets/app_button.dart';
import 'package:sijil/core/widgets/app_status_card.dart';
import 'package:sijil/core/widgets/app_text_field.dart';
import 'package:sijil/features/family_creation/utils/text_utils.dart';
import 'package:sijil/features/family_creation/widgets/review_section_card.dart';
import 'package:sijil/features/referrals/constants/referral_demo_data.dart';
import 'package:sijil/features/referrals/controllers/incoming_referral_controller.dart';
import 'package:sijil/features/referrals/models/referral_model.dart';
import 'package:sijil/features/referrals/utils/referral_formatters.dart';
import 'package:sijil/features/referrals/widgets/referral_flow_scaffold.dart';
import 'package:sijil/features/referrals/widgets/referral_info_card.dart';
import 'package:sijil/features/referrals/widgets/referral_status_badge.dart';

// Incoming referral review for the supervisor: accept, or reject with a reason
// Open it with: Get.to(() => IncomingReferralReviewScreen(referral: referral));
class IncomingReferralReviewScreen extends StatelessWidget {
  final ReferralModel referral;

  IncomingReferralReviewScreen({super.key, required this.referral});

  late final IncomingReferralController controller = Get.put(
    IncomingReferralController(referral),
  );

  @override
  Widget build(BuildContext context) {
    return ReferralFlowScaffold(
      title: 'مراجعة إحالة واردة',
      breadcrumb: 'قرار الجهة المستقبلة',
      subtitleLine: ReferralDemoData.supervisorLabel,
      children: [
        ReferralStatusBadge(
          status: referral.status,
          label: controller.isWaitingDecision
              ? 'استُلمت · بانتظار القرار'
              : referral.status.label,
        ),

        const SizedBox(height: 16),

        // Only the referral content is visible, not the family record
        ReferralInfoCard(
          children: [
            ReviewRow(label: 'الجهة المحيلة', value: referral.fromOrg),
            ReviewRow(
              label: 'الأسرة · بيانات الإحالة فقط',
              value:
                  '${referral.familyName} · ${membersLabel(referral.membersCount)}',
            ),
            ReviewRow(
              label: 'التواصل المصرح به',
              value: formatPhone(referral.contactPhone),
              valueDirection: TextDirection.ltr,
            ),
            ReviewRow(label: 'المنطقة', value: referral.area),
            ReviewRow(label: 'الخدمة المطلوبة', value: referral.service),
            ReviewRow(
              label: 'تاريخ الاستلام',
              value: formatDateTime(referral.receivedAt ?? referral.createdAt),
            ),
          ],
        ),

        const SizedBox(height: 24),

        const Text(
          'سبب الإحالة',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          referral.reason,
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
            color: AppColors.textPrimary,
          ),
        ),

        const SizedBox(height: 16),

        AppStatusCard(
          title: 'وصول محدود بمحتوى الإحالة',
          message:
              'لا تتيح هذه الصفحة استعراض أسر ${referral.fromOrg} أو فتح سجلاتها الكاملة. تُشارك نتيجة القرار مع الجهة المحيلة.',
          type: AppStatusType.success,
        ),

        const SizedBox(height: 24),

        // The decision is available only while the referral waits for it
        if (!controller.isWaitingDecision)
          const AppStatusCard(
            title: 'تم اتخاذ قرار بشأن هذه الإحالة',
            message: 'لا يمكن تغيير القرار من هذه الصفحة.',
            type: AppStatusType.info,
          )
        else ...[
          AppButton(
            text: 'قبول الإحالة وبدء المراجعة',
            icon: Icons.check,
            onPressed: controller.acceptReferral,
          ),

          const SizedBox(height: 24),

          const Text(
            'أو رفض الإحالة مع توضيح السبب',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 16),

          Obx(
            () => AppTextField(
              label: 'سبب الرفض',
              hint: 'لم يُكتب السبب بعد',
              controller: controller.rejectReasonController,
              keyboardType: TextInputType.multiline,
              maxLines: 3,
              isRequired: true,
              errorText: controller.rejectError,
              onChanged: controller.onRejectReasonChanged,
            ),
          ),

          const SizedBox(height: 16),

          Obx(
            () => AppButton(
              text: 'تأكيد رفض الإحالة',
              isEnabled: controller.canReject,
              onPressed: controller.rejectReferral,
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            'الرفض يحتاج سبباً، ويُرسل إشعار به إلى الموظف المحيل. القبول ينقل الحالة إلى «قيد المراجعة» ولا يعني تقديم الخدمة.',
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
