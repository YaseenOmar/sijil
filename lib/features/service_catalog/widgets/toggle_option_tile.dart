import 'package:flutter/material.dart';
import 'package:sijil/core/theme/app_colors.dart';

// On / off option (touch target >= 56dp).
// The state is shown with icon + color, not color only.
class ToggleOptionTile extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const ToggleOptionTile({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: value,
      label: label,
      child: Material(
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: value
                            ? AppColors.success
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  Icon(
                    value ? Icons.check_circle_outline : Icons.circle_outlined,
                    size: 24,
                    color: value ? AppColors.primary : AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
