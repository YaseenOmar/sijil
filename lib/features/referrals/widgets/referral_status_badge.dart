import 'package:flutter/material.dart';
import 'package:sijil/core/theme/app_colors.dart';
import 'package:sijil/features/referrals/models/referral_model.dart';

// Small status pill (color + text, not color only)
class ReferralStatusBadge extends StatelessWidget {
  final ReferralStatus status;

  // Use it when the screen needs a different text than the default label
  final String? label;

  const ReferralStatusBadge({super.key, required this.status, this.label});

  @override
  Widget build(BuildContext context) {
    final Color color = _getColor();
    final Color background = _getBackground();

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label ?? status.label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }

  Color _getColor() {
    switch (status) {
      case ReferralStatus.pendingSend:
        return AppColors.warning;
      case ReferralStatus.completed:
        return AppColors.success;
      case ReferralStatus.rejected:
        return AppColors.error;
      default:
        return AppColors.neutral;
    }
  }

  Color _getBackground() {
    switch (status) {
      case ReferralStatus.pendingSend:
        return AppColors.warningBackground;
      case ReferralStatus.completed:
        return AppColors.successBackground;
      case ReferralStatus.rejected:
        return AppColors.errorBackground;
      default:
        return AppColors.disabledBackground;
    }
  }
}
