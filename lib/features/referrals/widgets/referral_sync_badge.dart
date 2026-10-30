import 'package:flutter/material.dart';
import 'package:sijil/core/theme/app_colors.dart';
import 'package:sijil/features/referrals/utils/referral_formatters.dart';

// Connection pill: online / offline + last sync time (presentational only)
class ReferralSyncBadge extends StatelessWidget {
  final bool isOnline;
  final DateTime lastSyncAt;

  const ReferralSyncBadge({
    super.key,
    required this.isOnline,
    required this.lastSyncAt,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = isOnline ? AppColors.success : AppColors.warning;
    final Color background = isOnline
        ? AppColors.successBackground
        : AppColors.warningBackground;

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          syncStatusLabel(isOnline: isOnline, lastSyncAt: lastSyncAt),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }
}
