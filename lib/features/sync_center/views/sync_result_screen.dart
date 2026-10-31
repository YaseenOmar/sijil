import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sijil/core/theme/app_colors.dart';
import 'package:sijil/core/widgets/app_button.dart';
import 'package:sijil/core/widgets/app_status_card.dart';
import 'package:sijil/core/widgets/custom_app_bar.dart';
import 'package:sijil/features/family_creation/utils/text_utils.dart';
import 'package:sijil/features/referrals/utils/referral_formatters.dart';
import 'package:sijil/features/sync_center/controllers/sync_result_controller.dart';
import 'package:sijil/features/sync_center/models/sync_operation.dart';
import 'package:sijil/features/sync_center/widgets/sync_operation_card.dart';
import 'package:sijil/features/sync_center/widgets/sync_stat_card.dart';

// Result of one sync round: what finished and what needs follow up
// Open it with: Get.to(() => SyncResultScreen());
class SyncResultScreen extends StatelessWidget {
  SyncResultScreen({super.key});

  final SyncResultController controller = Get.put(SyncResultController());

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.neutralBackground,

        // leading = back button on the right
        appBar: CustomAppBar(
          title: 'نتيجة المزامنة',
          leading: Icons.arrow_back,
          onLeadingPressed: () => Get.back(),
        ),

        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Obx(
              () => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildConnectionPill(),

                  const SizedBox(height: 16),

                  Text(
                    'اكتملت ${toArabicDigits(controller.syncedCount)} من ${toArabicDigits(controller.totalCount)} عمليات',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Progress of the round
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: controller.totalCount == 0
                          ? 0
                          : controller.syncedCount / controller.totalCount,
                      minHeight: 8,
                      backgroundColor: AppColors.border,
                      color: AppColors.primary,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: SyncStatCard(
                          value: toArabicDigits(controller.syncedCount),
                          label: 'تمت المزامنة',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SyncStatCard(
                          value: toArabicDigits(controller.remainingCount),
                          label: 'عمليات متبقية',
                        ),
                      ),
                    ],
                  ),

                  // The warning appears only when something is left
                  if (controller.remainingCount > 0) ...[
                    const SizedBox(height: 16),

                    AppStatusCard(
                      title: 'انتهت الجولة مع مشكلة قابلة لإعادة المحاولة',
                      message:
                          '${formatDateTime(controller.finishedAt)}. لم تُرسل ${controller.remainingSubject}؛ بياناتهما لا تزال محفوظة على الجهاز.',
                      type: AppStatusType.offline,
                    ),
                  ],

                  if (controller.completed.isNotEmpty) ...[
                    const SizedBox(height: 24),

                    const Text(
                      'العمليات المكتملة',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 16),

                    for (final operation in controller.completed) ...[
                      SyncOperationCard(operation: operation),
                      const SizedBox(height: 16),
                    ],
                  ],

                  if (controller.needsFollowUp.isNotEmpty) ...[
                    const SizedBox(height: 8),

                    const Text(
                      'بحاجة إلى متابعة',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 16),

                    for (final operation in controller.needsFollowUp) ...[
                      SyncOperationCard(
                        operation: operation,
                        onRetry: operation.status == SyncOperationStatus.failed
                            ? () => controller.retryAttachment(operation)
                            : null,
                      ),
                      const SizedBox(height: 16),
                    ],

                    AppButton(
                      text: 'مزامنة ${controller.remainingObject}',
                      icon: Icons.sync,
                      onPressed: controller.syncRemaining,
                    ),

                    const SizedBox(height: 16),
                  ],

                  Text(
                    'آخر مزامنة كاملة: ${formatDateTime(controller.lastFullSync)}. لا تُعرض هذه الجولة كمزامنة كاملة.',
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // "متصل بالإنترنت" pill
  Widget _buildConnectionPill() {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.successBackground,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'متصل بالإنترنت',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.success,
          ),
        ),
      ),
    );
  }
}
