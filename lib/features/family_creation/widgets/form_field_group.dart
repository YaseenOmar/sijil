import 'package:flutter/material.dart';
import 'package:sijil/core/theme/app_colors.dart';

// Label (+ inline helper) + custom input (chips, image...) + inline error message
class FormFieldGroup extends StatelessWidget {
  final String label;
  final bool isRequired;
  final String? helperText;
  final String? errorText;
  final Widget child;

  const FormFieldGroup({
    super.key,
    required this.label,
    required this.child,
    this.isRequired = false,
    this.helperText,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ex: "الاحتياجات * · يمكن اختيار أكثر من حاجة"
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: isRequired ? '$label *' : label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              if (helperText != null)
                TextSpan(
                  text: ' · $helperText',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        child,

        if (errorText != null) ...[
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error_outline, size: 16, color: AppColors.error),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  errorText!,
                  style: const TextStyle(fontSize: 12, color: AppColors.error),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
