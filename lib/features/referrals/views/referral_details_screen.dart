
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:sijil/core/theme/app_colors.dart';
import 'package:sijil/core/widgets/app_button.dart';
import 'package:sijil/core/widgets/app_status_card.dart';
import 'package:sijil/core/widgets/app_text_field.dart';

import 'package:sijil/features/family_creation/utils/text_utils.dart';

import '../controllers/referral_details_controller.dart';
import '../models/referral_model.dart';
import '../widgets/referral_flow_scaffold.dart';
import '../widgets/referral_info_card.dart';
import '../widgets/referral_summary_card.dart';
import '../widgets/referral_timeline.dart';

class ReferralDetailsScreen extends StatelessWidget {
  final ReferralModel referral;

  ReferralDetailsScreen({
    super.key,
    required this.referral,
  });

  late final ReferralDetailsController controller = Get.put(
    ReferralDetailsController(referral.id),
    tag: referral.id,
  );

  @override
  Widget build(BuildContext context) {
    return ReferralFlowScaffold(
      title: 'تفاصيل الإحالة',
      breadcrumb: 'مسار الخدمة',
      subtitleLine:
      'الإحالة ${toArabicDigits(referral.number)} · صادرة',
      children: [
        Obx(() {
          if (controller.isLoading.value) {
            return const AppStatusCard(
              title: 'جاري التحميل',
              message: 'نجهز تفاصيل الإحالة',
              type: AppStatusType.loading,
            );
          }

          final item = controller.referral.value;

          if (item == null) {
            return AppStatusCard(
              title: 'تعذر عرض الإحالة',
              message: controller.loadError.value ??
                  'الإحالة غير موجودة',
              type: AppStatusType.error,
            );
          }

          return _buildDetails(item);
        }),
      ],
    );
  }

  Widget _buildDetails(ReferralModel item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ---------------- Summary ----------------
        ReferralSummaryCard(referral: item),

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


        Obx(() {
          if (controller.isLoadingSteps.value) {
            return const AppStatusCard(
              title: 'جاري تحميل مسار الإحالة',
              message: 'نجهز سجل العمليات',
              type: AppStatusType.loading,
            );
          }

          final error = controller.stepsError.value;

          if (error != null) {
            return AppStatusCard(
              title: 'تعذر تحميل مسار الإحالة',
              message: error,
              type: AppStatusType.error,
            );
          }

          return ReferralTimeline(
            steps: controller.referralSteps.toList(),
          );
        }),


        // ---------------- Rejection ----------------
        if (item.isRejected &&
            item.rejectionReason != null) ...[
          const SizedBox(height: 24),

          AppStatusCard(
            title: 'سبب رفض الإحالة',
            message: item.rejectionReason!,
            type: AppStatusType.error,
          ),
        ],

        // ---------------- Result ----------------
        if (item.result != null) ...[
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
                item.result!,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.textPrimary,
                ),
              ),

              if (item.resultNote != null) ...[
                const SizedBox(height: 8),
                Text(
                  item.resultNote!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ],

        // ---------------- Supervisor Decision ----------------
        Obx(() {
          if (!controller.canReview) {
            return const SizedBox.shrink();
          }

          return _buildSupervisorActions();
        }),

        const SizedBox(height: 24),

        AppButton(
          text: 'العودة إلى الإحالات',
          type: AppButtonType.secondary,
          onPressed: () => Get.back(),
        ),
      ],
    );
  }

  Widget _buildSupervisorActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),

        const Text(
          'قرار المشرف',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),

        const SizedBox(height: 16),

        Obx(
              () => AppButton(
            text: 'اعتماد وإرسال الإحالة',
            icon: Icons.check_circle_outline,
            isLoading: controller.isProcessing.value,
            isEnabled: !controller.isProcessing.value,
            onPressed: controller.approveReferral,
          ),
        ),

        const SizedBox(height: 16),

        Obx(
              () => AppButton(
            text: 'رفض الإحالة',
            type: AppButtonType.secondary,
            isEnabled: !controller.isProcessing.value,
            onPressed: controller.toggleRejectField,
          ),
        ),

        Obx(() {
          if (!controller.showRejectField.value) {
            return const SizedBox.shrink();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),

              AppTextField(
                label: 'سبب الرفض',
                hint: 'اكتب سبب رفض الإحالة',
                controller: controller.rejectReasonController,
                keyboardType: TextInputType.multiline,
                maxLines: 3,
                isRequired: true,
                onChanged: controller.onRejectReasonChanged,
              ),

              const SizedBox(height: 16),

              Obx(
                    () => AppButton(
                  text: 'تأكيد رفض الإحالة',
                  isLoading: controller.isProcessing.value,
                  isEnabled: controller.canReject &&
                      !controller.isProcessing.value,
                  onPressed: controller.rejectReferral,
                ),
              ),
            ],
          );
        }),

        const SizedBox(height: 16),

        Obx(() {
          final error = controller.loadError.value;

          if (error == null) {
            return const SizedBox.shrink();
          }

          return AppStatusCard(
            title: 'تعذر تنفيذ العملية',
            message: error,
            type: AppStatusType.error,
          );
        }),
      ],
    );
  }
}
