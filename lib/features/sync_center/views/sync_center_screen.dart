import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sijil/core/theme/app_colors.dart';
import 'package:sijil/core/widgets/app_button.dart';
import 'package:sijil/core/widgets/app_status_card.dart';
import 'package:sijil/core/widgets/custom_app_bar.dart';
import 'package:sijil/features/family_creation/utils/text_utils.dart';
import 'package:sijil/features/referrals/utils/referral_formatters.dart';
import 'package:sijil/features/service_catalog/widgets/toggle_option_tile.dart';
import 'package:sijil/features/sync_center/controllers/sync_center_controller.dart';
import 'package:sijil/features/sync_center/widgets/sync_operation_card.dart';
import 'package:sijil/features/sync_center/widgets/sync_stat_card.dart';

// Sync center: the operations saved on the device and waiting for the server
// Open it with: Get.to(() => SyncCenterScreen());
class SyncCenterScreen extends StatelessWidget {
  SyncCenterScreen({super.key});

  final SyncCenterController controller = Get.put(SyncCenterController());

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.neutralBackground,

        // leading = back button on the right
        appBar: CustomAppBar(
          title: 'مركز المزامنة',
          leading: Icons.arrow_back,
          onLeadingPressed: () => Get.back(),
        ),

        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Connection state
                Obx(
                  () => controller.isOnline.value
                      ? const AppStatusCard(
                          title: 'متصل بالإنترنت',
                          message: 'يمكنك مزامنة العمليات المحفوظة الآن.',
                          type: AppStatusType.online,
                        )
                      : const AppStatusCard(
                          title: 'لا يوجد اتصال بالإنترنت',
                          message: 'كل العمليات التالية محفوظة محلياً ولم تُؤكَّد مزامنتها.',
                          type: AppStatusType.offline,
                        ),
                ),

                const SizedBox(height: 16),

                Obx(
                  () => Row(
                    children: [
                      Expanded(
                        child: SyncStatCard(
                          value: toArabicDigits(controller.pendingCount),
                          label: 'عمليات في الانتظار',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SyncStatCard(
                          value: toArabicDigits(controller.attachmentsCount),
                          label: 'مرفقات للرفع',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  'آخر مزامنة ناجحة: ${formatDateTime(controller.lastSuccessfulSync)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 16),

                Obx(
                  () => ToggleOptionTile(
                    label: 'المزامنة التلقائية عند عودة الاتصال',
                    value: controller.autoSync.value,
                    onChanged: controller.setAutoSync,
                  ),
                ),

                const SizedBox(height: 24),

                // Queue
                Obx(
                  () => Text(
                    'طابور العمليات · ${toArabicDigits(controller.operations.length)} عمليات',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Obx(() {
                  if (controller.operations.isEmpty) {
                    return const AppStatusCard(
                      title: 'لا توجد عمليات في الانتظار',
                      message: 'كل أعمالك متزامنة مع الخادم.',
                      type: AppStatusType.empty,
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final operation in controller.operations) ...[
                        SyncOperationCard(operation: operation),
                        const SizedBox(height: 16),
                      ],
                    ],
                  );
                }),

                const AppStatusCard(
                  title: 'المرفقات تحتاج وقتاً إضافياً',
                  message: 'يبقى إثبات الاستلام أو صورة الهوية في الانتظار حتى اكتمال رفعه. لا تحذف المرفق أثناء المزامنة.',
                  type: AppStatusType.info,
                ),

                const SizedBox(height: 16),

                // Disabled while offline
                Obx(
                  () => AppButton(
                    text: controller.isOnline.value
                        ? 'مزامنة الآن'
                        : 'المزامنة الآن · غير متاحة دون اتصال',
                    icon: controller.isOnline.value ? Icons.sync : null,
                    isEnabled: controller.isOnline.value,
                    onPressed: controller.syncNow,
                  ),
                ),

                const SizedBox(height: 16),

                AppButton(
                  text: 'فتح إعدادات الاتصال',
                  icon: Icons.wifi,
                  type: AppButtonType.secondary,
                  onPressed: controller.openConnectionSettings,
                ),

                const SizedBox(height: 16),

                const Text(
                  'يبقى عملك محفوظاً في مساحة البيانات المحلية المحمية عند فقد الاتصال. لا يلزم إدخال العمليات مرة أخرى.',
                  style: TextStyle(
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
    );
  }
}
