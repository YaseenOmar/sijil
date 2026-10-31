import 'package:flutter/material.dart';
import 'package:sijil/core/theme/app_colors.dart';

enum AppStatusType {
  loading,
  empty,
  info,
  error,
  offline,
  success,
  online,
}

class AppStatusCard extends StatelessWidget {
  final String title;
  final String message;
  final AppStatusType type;
  final IconData? icon;//هادا

  const AppStatusCard({
    super.key,
    required this.title,
    required this.message,
    this.type = AppStatusType.info,
    this.icon,//وهادا
  });

  @override
  Widget build(BuildContext context) {
    final Color color = _getColor();
    final Color background = _getBackground();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon ?? _getIcon(),
            color: color,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 14,
                    color: color,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getColor() {
    switch (type) {
      case AppStatusType.error:
        return AppColors.error;
      case AppStatusType.offline:
        return AppColors.warning;
      case AppStatusType.success:
        return AppColors.success;
      default:
        return AppColors.neutral;
    }
  }

  Color _getBackground() {
    switch (type) {
      case AppStatusType.error:
        return AppColors.errorBackground;
      case AppStatusType.offline:
        return AppColors.warningBackground;
      case AppStatusType.success:
        return AppColors.successBackground;
      case AppStatusType.online:
        return AppColors.successBackground;
      case AppStatusType.info:
        return AppColors.successBackground;
      default:
        return AppColors.neutralBackground;
    }
  }

  IconData _getIcon() {
    switch (type) {
      case AppStatusType.loading:
        return Icons.refresh;
      case AppStatusType.empty:
        return Icons.people_outline;
      case AppStatusType.info:
        return Icons.info_outline;
      case AppStatusType.error:
        return Icons.error_outline;
      case AppStatusType.offline:
        return Icons.wifi_off;
      case AppStatusType.online:
        return Icons.wifi;
      case AppStatusType.success:
        return Icons.check_circle_outline;
    }
  }
}
