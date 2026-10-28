import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sijil/core/theme/app_colors.dart';
import 'package:sijil/core/widgets/app_button.dart';
import 'package:sijil/core/widgets/app_status_card.dart';
import 'package:sijil/core/widgets/custom_app_bar.dart';
import 'package:sijil/features/notifications/controllers/notifications_controller.dart';
import 'package:sijil/features/notifications/widgets/notification_card.dart';

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
          subtitle: 'نورا إبراهيم · مشرفة جمعية الأمان',
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
                      'ويصل إشعار إتمام إلى الموظف المحيل.',
                  type: AppStatusType.info,
                  icon: Icons.shield_outlined,
                ),

                const SizedBox(height: 16),

                // قائمة الإشعارات (بتتحدث مع تغيير التاب أو حالة القراءة)
                Obx(() {
                  final items = controller.visibleNotifications;

                  if (items.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          'لا توجد إشعارات غير مقروءة',
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: items.map((notification) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: NotificationCard(
                          notification: notification,
                          onTap: () => controller.markAsRead(notification.id),
                        ),
                      );
                    }).toList(),
                  );
                }),

                const SizedBox(height: 4),

                AppButton(
                  text: 'تحديد إشعاراتي كمقروءة',
                  type: AppButtonType.secondary,
                  onPressed: controller.markAllAsRead,
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
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}