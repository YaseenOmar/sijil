import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sijil/core/theme/app_colors.dart';
import 'package:sijil/core/widgets/app_button.dart';
import 'package:sijil/core/widgets/app_status_card.dart';
import 'package:sijil/core/widgets/custom_bottom_nav_bar.dart';
import 'package:sijil/features/family_creation/utils/text_utils.dart';
import 'package:sijil/features/family_creation/widgets/option_chip.dart';
import 'package:sijil/features/referrals/constants/referral_options.dart';
import 'package:sijil/features/referrals/controllers/referrals_controller.dart';
import 'package:sijil/features/referrals/models/referral_model.dart';
import 'package:sijil/features/referrals/utils/referral_formatters.dart';
import 'package:sijil/features/referrals/widgets/incoming_referral_card.dart';
import 'package:sijil/features/referrals/widgets/referral_card.dart';
import 'package:sijil/features/referrals/widgets/referral_flow_scaffold.dart';
import 'package:sijil/features/referrals/widgets/referral_status_filter.dart';
import 'package:sijil/features/referrals/widgets/referral_tabs.dart';

// Referrals list: outgoing tab (field worker) / incoming tab (supervisor)
// Open it with: Get.to(() => ReferralsScreen());
class ReferralsScreen extends StatelessWidget {
  ReferralsScreen({super.key});

  final ReferralsController controller = Get.put(ReferralsController());

  @override
  Widget build(BuildContext context) {
    // The header and the body change with the selected tab
    return Obx(() {
      final bool isIncoming = controller.tabIndex.value == 1;

      return ReferralFlowScaffold(
        title: 'الإحالات',
        breadcrumb: isIncoming
            ? 'الإحالات الواردة'
            : 'الإحالات الصادرة',

        // Action icon on the left side: it clears the status filter (outgoing only)
        actionIcon: Icons.tune,
        onActionPressed: isIncoming ? null : controller.resetFilter,


        bottomNavigationBar: const CustomBottomNavBar(selectedIndex: 3),
        children: [
          Obx(
                () => ReferralTabs(
              labels: [
                'الصادرة ${toArabicDigits(controller.outgoing.length)}',
                controller.isSupervisor ? 'الواردة · للمشرف' : 'الواردة · المقبولة',
              ],
              selectedIndex: controller.tabIndex.value,
              onChanged: controller.selectTab,
            ),
          ),

          const SizedBox(height: 16),

          if (isIncoming) ..._incomingChildren() else ..._outgoingChildren(),
        ],
      );
    });
  }

  // ---------- Outgoing tab ----------
  List<Widget> _outgoingChildren() {
    return [
      const Text(
        'تابع الإحالات الصادرة وحالتها، وانتقل إلى الواردة لمتابعة الخدمات المقبولة.',
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
            const Expanded(
              child: Text(
                'آخر الإحالات الصادرة',
                style: TextStyle(
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

      _buildList(isIncoming: false),

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
    ];
  }

  // ---------- Incoming tab (supervisor) ----------
  List<Widget> _incomingChildren() {
    return [

      const SizedBox(height: 24),

      const Text(
        'تصفية الحالة',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),

      const SizedBox(height: 16),

      // Status filter (single select)
      Obx(
        () => controller.isFieldWorker
            ? const SizedBox.shrink()
            : ReferralStatusFilter(
          options: ReferralOptions.incomingFilters,
          selected: controller.selectedIncomingFilter.value,
          onSelected: controller.selectIncomingFilter,
        ),
      ),

      const SizedBox(height: 16),

      // How many referrals match and how many are shown
      Obx(() {
        final int total = controller.filteredIncoming.length;

        if (controller.isLoading.value || total == 0) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            incomingListNote(
              filter: controller.selectedIncomingFilter.value,
              shown: controller.displayedIncoming.length,
              total: total,
            ),
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
        );
      }),

      _buildList(isIncoming: true),

      // The rest of the referrals stays hidden until the supervisor asks for it
      Obx(() {
        final int hidden = controller.hiddenIncomingCount;

        if (hidden == 0) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: AppButton(
            text: showRestLabel(hidden),
            type: AppButtonType.secondary,
            onPressed: controller.showRestOfIncoming,
          ),
        );
      }),

      Obx(
        () => AppStatusCard(
          title: 'محتوى الإحالة فقط',
          message: _scopeMessage(controller.displayedIncoming),
          type: AppStatusType.success,
          icon: Icons.lock_outline,
        ),
      ),

    ];
  }

  String _scopeMessage(List<ReferralModel> items) {
    final Set<String> orgs = items.map((item) => item.fromOrg).toSet();

    if (orgs.length == 1) {
      return 'لا تتيح القائمة البحث في أسر ${orgs.first} أو فتح سجلها الكامل. قرار القبول أو الرفض متاح للمشرف ضمن الجهة فقط.';
    }

    return 'لا تتيح القائمة البحث في أسر الجهات المحيلة أو فتح سجلاتها الكاملة. قرار القبول أو الرفض متاح للمشرف ضمن الجهة فقط.';
  }

  // ---------- Shared list: loading / error / empty / success ----------
  Widget _buildList({required bool isIncoming}) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: AppStatusCard(
            title: 'جاري التحميل',
            message: 'نجهز قائمة الإحالات.',
            type: AppStatusType.loading,
          ),
        );
      }

      final String? error = controller.loadError.value;

      if (error != null) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
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
          ),
        );
      }

      final List<ReferralModel> items = isIncoming
          ? controller.displayedIncoming
          : controller.visibleReferrals;

      if (items.isEmpty) {
        return const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: AppStatusCard(
            title: 'لا توجد إحالات',
            message: 'لا توجد إحالات مطابقة للتصفية الحالية.',
            type: AppStatusType.empty,
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final referral in items) ...[
            if (isIncoming)
              IncomingReferralCard(
                referral: referral,
                onTap: () => controller.openReferral(referral),
              )
            else
              ReferralCard(
                referral: referral,
                onTap: () => controller.openReferral(referral),
              ),
            const SizedBox(height: 16),
          ],
        ],
      );
    });
  }
}
