
import 'package:flutter/material.dart';
import 'package:sijil/core/theme/app_colors.dart';

import '../models/referral_model.dart';
import '../utils/referral_formatters.dart';
import 'referral_info_card.dart';

class ReferralTimeline extends StatelessWidget {
  final List<ReferralStep> steps;

  const ReferralTimeline({
    super.key,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) {
      return const ReferralInfoCard(
        children: [
          Text(
            'لا توجد مراحل مسجلة لهذه الإحالة بعد.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      );
    }

    return ReferralInfoCard(
      children: List.generate(steps.length, (index) {
        final ReferralStep step = steps[index];
        final bool isLast = index == steps.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Timeline icon and connecting line
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
                        margin: const EdgeInsets.symmetric(
                          vertical: 4,
                        ),
                        color: AppColors.border,
                      ),
                    ),
                ],
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: isLast ? 0 : 24,
                  ),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
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

                      if (step.actor.trim().isNotEmpty &&
                          step.actor != '-') ...[
                        const SizedBox(height: 4),
                        Text(
                          step.actor,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
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
