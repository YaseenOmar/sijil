import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sijil/core/theme/app_colors.dart';
import 'package:sijil/core/widgets/app_button.dart';
import 'package:sijil/core/widgets/app_status_card.dart';
import 'package:sijil/core/widgets/custom_app_bar.dart';
import 'package:sijil/features/notifications/constants/notification_demo_data.dart';
import 'package:sijil/features/notifications/controllers/notifications_controller.dart';
import 'package:sijil/features/notifications/widgets/notification_card.dart';

// Notifications list: all / unread tabs and the read state
// Open it with: Get.to(() => NotificationsScreen());
class NotificationsScreen extends StatelessWidget {
  NotificationsScreen({super.key});

  final NotificationsController controller = Get.put(
    NotificationsController(),
  );

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.neutralBackground,
        appBar: CustomAppBar(
          title: 'الإشعارات',
          subtitle: NotificationDemoData.supervisorLabel,
          leading: Icons.arrow_back,
          onLeadingPressed: () => Get.back(),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // تبويبات: الكل / غير المقروءة
                _NotificationTabs(controller: controller),

                const SizedBox(height: 16),

                const AppStatusCard(
                  title: 'إشعارات المتابعة ضمن جهتك',
                  message:
                      'تظهر لك تنبيهات التعارض ومشكلات المزامنة وتحديثات '
                      'إحالات الجهة. يتلقى كل عامل تحديثات أعماله فقط، '
                      'ويصل إشعار الإتمام إلى الموظف المحيل.',
                  type: AppStatusType.info,
                  icon: Icons.shield_outlined,
                ),

                const SizedBox(height: 16),

                // قائمة الإشعارات: تحميل / خطأ / فارغة / نجاح
                // (بتتحدث مع تغيير التاب أو حالة القراءة)
                Obx(() {
                  if (controller.isLoading.value) {
                    return const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: AppStatusCard(
                        title: 'جاري التحميل',
                        message: 'نجهز قائمة الإشعارات.',
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
                            onPressed: controller.loadNotifications,
                          ),
                        ],
                      ),
                    );
                  }

                  final items = controller.visibleNotifications;

                  if (items.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: AppStatusCard(
                        title: 'لا توجد إشعارات',
                        message: controller.selectedTab.value == 1
                            ? 'لا توجد إشعارات غير مقروءة الآن.'
                            : 'لا توجد إشعارات بعد.',
                        type: AppStatusType.empty,
                      ),
                    );
                  }

                  return Column(
                    children: items.map((notification) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: NotificationCard(
                          notification: notification,
                          onTap: () => controller.markAsRead(notification.id),
                        ),
                      );
                    }).toList(),
                  );
                }),

                // معطل لما ما يكون في إشعارات غير مقروءة
                Obx(
                  () => AppButton(
                    text: 'تحديد إشعاراتي كمقروءة',
                    type: AppButtonType.secondary,
                    isEnabled: controller.unreadCount > 0,
                    onPressed: controller.markAllAsRead,
                  ),
                ),

                const SizedBox(height: 16),

                const AppStatusCard(
                  title: 'على شاشة القفل: إشعار عام فقط',
                  message:
                      '«لديك تحديث جديد في سجل». لا تظهر أسماء الأسر أو '
                      'نوع الخدمة أو تفاصيل الهوية خارج التطبيق.',
                  type: AppStatusType.success,
                  icon: Icons.lock_outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// التبويبات: الكل / غير المقروءة
class _NotificationTabs extends StatelessWidget {
  final NotificationsController controller;

  const _NotificationTabs({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.disabledBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            _TabItem(
              label: 'الكل',
              isSelected: controller.selectedTab.value == 0,
              onTap: () => controller.changeTab(0),
            ),
            _TabItem(
              label: 'غير المقروءة',
              isSelected: controller.selectedTab.value == 1,
              onTap: () => controller.changeTab(1),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: label,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
