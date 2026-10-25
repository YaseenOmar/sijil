import 'package:flutter/material.dart';
import 'package:sijil/core/theme/app_colors.dart';

// "تحققت من البيانات مع الأسرة" confirmation (touch target >= 48dp)
class ConfirmCheckboxTile extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const ConfirmCheckboxTile({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: value ? AppColors.successBackground : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: value ? AppColors.primary : AppColors.border),
      ),
      child: InkWell(
        onTap: () => onChanged(!value),
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                Checkbox(
                  value: value,
                  activeColor: AppColors.primary,
                  onChanged: (checked) => onChanged(checked ?? false),
                ),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: value ? AppColors.success : AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
