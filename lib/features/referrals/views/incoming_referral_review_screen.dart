
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:sijil/core/theme/app_colors.dart';
import 'package:sijil/core/widgets/app_button.dart';
import 'package:sijil/core/widgets/app_status_card.dart';
import 'package:sijil/core/widgets/app_text_field.dart';

import 'package:sijil/features/family_creation/utils/text_utils.dart';
import 'package:sijil/features/family_creation/widgets/review_section_card.dart';

import '../controllers/incoming_referral_controller.dart';
import '../models/referral_model.dart';
import '../utils/referral_formatters.dart';
import '../widgets/referral_flow_scaffold.dart';
import '../widgets/referral_info_card.dart';
import '../widgets/referral_status_badge.dart';

class IncomingReferralReviewScreen extends StatefulWidget {
  final ReferralModel referral;

  const IncomingReferralReviewScreen({
    super.key,
    required this.referral,
  });

  @override
  State<IncomingReferralReviewScreen> createState() =>
      _IncomingReferralReviewScreenState();
}

class _IncomingReferralReviewScreenState
    extends State<IncomingReferralReviewScreen> {
  late final String controllerTag;
  late final IncomingReferralController controller;

  @override
  void initState() {
    super.initState();

    controllerTag = 'incoming_${widget.referral.id}';

    controller = Get.put(
      IncomingReferralController(widget.referral),
      tag: controllerTag,
    );
  }

  @override
  void dispose() {
    if (Get.isRegistered<IncomingReferralController>(
      tag: controllerTag,
    )) {
      Get.delete<IncomingReferralController>(
        tag: controllerTag,
      );
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ReferralFlowScaffold(
      title: 'مراجعة إحالة واردة',
      breadcrumb: 'متابعة الإحالة',
      subtitleLine: 'المؤسسة المستقبلة',
      children: [
        Obx(() {
          if (controller.isLoading.value) {
            return const AppStatusCard(
              title: 'جاري تحميل الإحالة',
              message: 'نجهز بيانات الإحالة',
              type: AppStatusType.loading,
            );
          }

          final referral = controller.referral;

          if (referral == null) {
            return AppStatusCard(
              title: 'تعذر عرض الإحالة',
              message: controller.loadError.value ??
                  'الإحالة غير موجودة',
              type: AppStatusType.error,
            );
          }

          return _buildContent(referral);
        }),
      ],
    );
  }

  Widget _buildContent(ReferralModel referral) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ReferralStatusBadge(status: referral.status),

        const SizedBox(height: 16),

        // ---------------- Referral Information ----------------

        ReferralInfoCard(
          children: [
            ReviewRow(
              label: 'الجهة المحيلة',
              value: referral.sourceOrganizationName,
            ),
            ReviewRow(
              label: 'الأسرة',
              value:
              '${referral.familyName} · ${membersLabel(referral.membersCount)}',
            ),
            ReviewRow(
              label: 'رقم التواصل',
              value: formatPhone(referral.contactPhone),
              valueDirection: TextDirection.ltr,
            ),
            ReviewRow(
              label: 'المنطقة',
              value: referral.areaId,
            ),
            ReviewRow(
              label: 'الخدمة المطلوبة',
              value: referral.serviceName,
            ),
            ReviewRow(
              label: 'تاريخ الإرسال',
              value: formatDateTime(
                referral.sourceApprovedAt ??
                    referral.createdAt,
              ),
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

        const AppStatusCard(
          title: 'بيانات الإحالة فقط',
          message:
          'تُعرض البيانات المصرح بمشاركتها دون إتاحة الوصول '
              'إلى سجل الأسرة الأصلي لدى المؤسسة المحيلة.',
          type: AppStatusType.info,
          icon: Icons.lock_outline,
        ),

        const SizedBox(height: 24),

        // ---------------- Actions by Status ----------------

        if (referral.status ==
            ReferralStatus.pendingTargetApproval)
          _buildDecisionSection(),

        if (referral.status == ReferralStatus.accepted)
          _buildStartServiceSection(),

        if (referral.status == ReferralStatus.inProgress)
          _buildCompleteServiceSection(),

        if (referral.status == ReferralStatus.completed)
          _buildCompletedSection(referral),

        if (referral.status == ReferralStatus.rejectedByTarget)
          _buildRejectedSection(referral),

        // ---------------- Errors ----------------

        Obx(() {
          final error = controller.loadError.value;

          if (error == null) {
            return const SizedBox.shrink();
          }

          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: AppStatusCard(
              title: 'تعذر تنفيذ العملية',
              message: error,
              type: AppStatusType.error,
            ),
          );
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

  // ---------------- Accept / Reject ----------------

  Widget _buildDecisionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
            text: 'قبول الإحالة',
            icon: Icons.check,
            isLoading: controller.isProcessing.value,
            isEnabled: !controller.isProcessing.value,
            onPressed: controller.acceptReferral,
          ),
        ),

        const SizedBox(height: 24),

        const Text(
          'أو رفض الإحالة مع توضيح السبب',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),

        const SizedBox(height: 16),

        Obx(
              () => AppTextField(
            label: 'سبب الرفض',
            hint: 'اكتب سبب رفض الإحالة',
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
            isEnabled: controller.canReject &&
                !controller.isProcessing.value,
            onPressed: controller.rejectReferral,
          ),
        ),
      ],
    );
  }

  // ---------------- Start Service ----------------

  Widget _buildStartServiceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppStatusCard(
          title: 'تم قبول الإحالة',
          message:
          'أصبحت الأسرة ضمن سجلات الأسر المستقبلة. '
              'يمكن الآن بدء تقديم الخدمة المطلوبة.',
          type: AppStatusType.success,
        ),

        const SizedBox(height: 16),

        Obx(
              () => AppButton(
            text: 'بدء تقديم الخدمة',
            icon: Icons.play_arrow_outlined,
            isLoading: controller.isProcessing.value,
            isEnabled: !controller.isProcessing.value,
            onPressed: controller.startService,
          ),
        ),
      ],
    );
  }

  // ---------------- Complete Service ----------------

  Widget _buildCompleteServiceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'إنهاء تقديم الخدمة',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'أدخل نتيجة الخدمة التي تم تقديمها للأسرة.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),

        const SizedBox(height: 16),

        AppTextField(
          label: 'نتيجة الخدمة',
          hint: 'مثال: تم تقديم الخدمة المطلوبة للأسرة',
          controller: controller.resultController,
          keyboardType: TextInputType.multiline,
          maxLines: 3,
          isRequired: true,
        ),

        const SizedBox(height: 16),

        AppTextField(
          label: 'ملاحظات إضافية',
          hint: 'أضف ملاحظات عند الحاجة',
          controller: controller.resultNoteController,
          keyboardType: TextInputType.multiline,
          maxLines: 3,
        ),

        const SizedBox(height: 24),

        Obx(
              () => AppButton(
            text: 'إنهاء الخدمة وحفظ النتيجة',
            icon: Icons.check_circle_outline,
            isLoading: controller.isProcessing.value,
            isEnabled: !controller.isProcessing.value,
            onPressed: controller.completeService,
          ),
        ),
      ],
    );
  }

  // ---------------- Completed ----------------

  Widget _buildCompletedSection(ReferralModel referral) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppStatusCard(
          title: 'تم تقديم الخدمة',
          message:
          'اكتملت الإحالة وتم حفظ نتيجة الخدمة.',
          type: AppStatusType.success,
        ),

        if (referral.result != null) ...[
          const SizedBox(height: 16),

          ReferralInfoCard(
            children: [
              ReviewRow(
                label: 'نتيجة الخدمة',
                value: referral.result!,
              ),

              if (referral.resultNote != null &&
                  referral.resultNote!.isNotEmpty)
                ReviewRow(
                  label: 'ملاحظات',
                  value: referral.resultNote!,
                ),

              if (referral.completedAt != null)
                ReviewRow(
                  label: 'تاريخ إكمال الخدمة',
                  value: formatDateTime(referral.completedAt!),
                ),
            ],
          ),
        ],
      ],
    );
  }

  // ---------------- Rejected ----------------

  Widget _buildRejectedSection(ReferralModel referral) {
    return AppStatusCard(
      title: 'تم رفض الإحالة',
      message: referral.rejectionReason ??
          'لم يتم تسجيل سبب الرفض',
      type: AppStatusType.error,
    );
  }
}
