import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sijil/core/theme/app_colors.dart';
import 'package:sijil/core/widgets/app_button.dart';
import 'package:sijil/core/widgets/app_status_card.dart';
import 'package:sijil/core/widgets/custom_bottom_nav_bar.dart';
import 'package:sijil/features/family_creation/utils/text_utils.dart';
import 'package:sijil/features/family_creation/widgets/option_chip.dart';
import 'package:sijil/features/referrals/constants/referral_demo_data.dart';
import 'package:sijil/features/referrals/constants/referral_options.dart';
import 'package:sijil/features/referrals/controllers/referrals_controller.dart';
import 'package:sijil/features/referrals/widgets/referral_card.dart';
import 'package:sijil/features/referrals/widgets/referral_flow_scaffold.dart';
import 'package:sijil/features/referrals/widgets/referral_tabs.dart';

// Referrals list: outgoing / incoming tabs, status filter and the latest referrals
// Open it with: Get.to(() => ReferralsScreen());
class ReferralsScreen extends StatelessWidget {
  ReferralsScreen({super.key});

  final ReferralsController controller = Get.put(ReferralsController());

  @override
  Widget build(BuildContext context) {
    return ReferralFlowScaffold(
      title: 'الإحالات',
      breadcrumb: 'متابعة الخدمات',
      subtitleLine: ReferralDemoData.fieldWorkerLabel,

      // Filter icon on the end side: it clears the status filter
      icon: Icons.tune,
      iconAtStart: false,
      onIconPressed: controller.resetFilter,

      // TODO: connect the destinations with the app navigation
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: 3,
      ),
      children: [
        Obx(
          () => ReferralTabs(
            labels: [
              'الصادرة ${toArabicDigits(controller.outgoing.length)}',
              'الواردة · للمشرف',
            ],
            selectedIndex: controller.tabIndex.value,
            onChanged: controller.selectTab,
          ),
        ),

        const SizedBox(height: 16),

        const Text(
          'تعرض لك الإحالات التي أنشأتها في منطقتك. يستقبل المشرف الإحالات الواردة للجهة.',
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: AppColors.textSecondary,
          ),
        ),

        const SizedBox(height: 16),

        // Status filter (single select)
        Obx(
          () => OptionChipWrap(
            options: ReferralOptions.filters,
            selected: [controller.selectedFilter.value],
            onTap: controller.selectFilter,
          ),
        ),

        const SizedBox(height: 24),

        // Section title + count
        Obx(
          () => Row(
            children: [
              Expanded(
                child: Text(
                  controller.tabIndex.value == 0
                      ? 'آخر الإحالات الصادرة'
                      : 'آخر الإحالات الواردة',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '${toArabicDigits(controller.visibleReferrals.length)} إحالات',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Loading / error / empty / success
        Obx(() {
          if (controller.isLoading.value) {
            return const AppStatusCard(
              title: 'جاري التحميل',
              message: 'نجهز قائمة الإحالات.',
              type: AppStatusType.loading,
            );
          }

          final String? error = controller.loadError.value;

          if (error != null) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppStatusCard(
                  title: 'تعذر التحميل',
                  message: error,
                  type: AppStatusType.error,
                ),
                const SizedBox(height: 16),
                AppButton(
                  text: 'إعادة المحاولة',
                  type: AppButtonType.secondary,
                  onPressed: controller.loadReferrals,
                ),
              ],
            );
          }

          final items = controller.visibleReferrals;

          if (items.isEmpty) {
            return const AppStatusCard(
              title: 'لا توجد إحالات',
              message: 'لا توجد إحالات مطابقة للتصفية الحالية.',
              type: AppStatusType.empty,
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final referral in items) ...[
                ReferralCard(
                  referral: referral,
                  isIncoming: controller.tabIndex.value == 1,
                  onTap: () => controller.openReferral(referral),
                ),
                const SizedBox(height: 16),
              ],
            ],
          );
        }),

        const AppStatusCard(
          title: 'حالة الإحالة تُحدَّث بعد المزامنة',
          message: 'الحفظ محلياً لا يعني الإرسال أو الاستلام لدى الجهة الأخرى.',
          type: AppStatusType.info,
        ),

        const SizedBox(height: 24),

        AppButton(
          text: 'إنشاء إحالة',
          icon: Icons.add,
          onPressed: controller.openCreateReferral,
        ),
      ],
    );
  }
}
