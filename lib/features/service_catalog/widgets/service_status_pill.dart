import 'package:flutter/material.dart';
import 'package:sijil/core/theme/app_colors.dart';

// Small neutral pill at the top of the screen (ex: "خدمة جديدة · إعدادات لم تُحفظ بعد")
class ServiceStatusPill extends StatelessWidget {
  final String text;

  const ServiceStatusPill({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.disabledBackground,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.neutral,
          ),
        ),
      ),
    );
  }
}
