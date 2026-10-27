import 'package:flutter/material.dart';
import 'package:sijil/core/theme/app_colors.dart';
import 'package:sijil/features/referrals/widgets/referral_info_card.dart';

// "ما الذي سيُشارك؟" what the receiving organization will see
class ShareScopeCard extends StatelessWidget {
  const ShareScopeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ReferralInfoCard(
      children: [
        const Text(
          'ما الذي سيُشارك؟',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'اسم رب الأسرة، رقم التواصل، المنطقة، نوع الخدمة وسبب الإحالة. لا تُشارك صورة الهوية أو سجل المساعدات الكامل.',
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: AppColors.textPrimary,
          ),
        ),

        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.successBackground,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'مشاركة عبر إحالة رسمية فقط',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.success,
            ),
          ),
        ),
      ],
    );
  }
}
