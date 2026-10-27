import 'package:flutter/material.dart';
import 'package:sijil/core/theme/app_colors.dart';
import 'package:sijil/features/referrals/models/referral_model.dart';
import 'package:sijil/features/referrals/utils/referral_formatters.dart';
import 'package:sijil/features/referrals/widgets/referral_info_card.dart';

// "مسار الإحالة": steps with a vertical line (presentational only)
class ReferralTimeline extends StatelessWidget {
  final List<ReferralStep> steps;

  const ReferralTimeline({super.key, required this.steps});

  @override
  Widget build(BuildContext context) {
    return ReferralInfoCard(
      children: List.generate(steps.length, (index) {
        final ReferralStep step = steps[index];
        final bool isLast = index == steps.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon + line to the next step
              Column(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 24,
                    color: AppColors.primary,
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 1,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: AppColors.border,
                      ),
                    ),
                ],
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatDateTime(step.at),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        step.actor,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
