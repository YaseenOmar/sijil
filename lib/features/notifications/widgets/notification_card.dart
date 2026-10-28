import 'package:flutter/material.dart';
import 'package:sijil/core/theme/app_colors.dart';
import 'package:sijil/features/notifications/models/notification_model.dart';

// كارد إشعار واحد: لونه وشارته بيتغيروا حسب حالة القراءة
class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;

  const NotificationCard({
    super.key,
    required this.notification,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isRead = notification.isRead;

    return Material(
      // غير مقروء: خلفية خضراء فاتحة | مقروء: أبيض
      color: isRead ? AppColors.surface : AppColors.successBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isRead ? AppColors.border : AppColors.successBackground,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // الشارة (مقروء / غير مقروء)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: _StatusBadge(notification: notification),
              ),
              const SizedBox(height: 8),

              // العنوان
              Text(
                notification.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 8),

              // النص
              Text(
                notification.body,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 10),

              // الوقت
              Text(
                notification.time,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// الشارة الصغيرة اللي فوق الكارد
class _StatusBadge extends StatelessWidget {
  final NotificationModel notification;

  const _StatusBadge({required this.notification});

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final Color textColor;
    late final Color background;

    if (notification.isRead) {
      label = 'مقروء';
      textColor = AppColors.neutral;
      background = AppColors.disabledBackground;
    } else if (notification.type == NotificationType.alert) {
      label = 'غير مقروء';
      textColor = AppColors.error;
      background = AppColors.errorBackground;
    } else if (notification.type == NotificationType.supervisorOnly) {
      label = 'للمشرف · غير مقروء';
      textColor = AppColors.warning;
      background = AppColors.warningBackground;
    } else {
      label = 'غير مقروء';
      textColor = AppColors.success;
      background = Colors.transparent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}