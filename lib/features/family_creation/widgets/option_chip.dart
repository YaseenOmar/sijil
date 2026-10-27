import 'package:flutter/material.dart';
import 'package:sijil/core/theme/app_colors.dart';

// Selectable option (touch target >= 48dp).
// Selection is shown with icon + color, not color only.
class OptionChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const OptionChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = isSelected ? AppColors.success : AppColors.textPrimary;

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: Material(
        color: isSelected ? AppColors.successBackground : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                    size: 20,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
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

// Two chips per row (a last single chip takes the full row)
class OptionChipWrap extends StatelessWidget {
  final List<String> options;
  final List<String> selected;
  final ValueChanged<String> onTap;

  const OptionChipWrap({
    super.key,
    required this.options,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double fullWidth = constraints.maxWidth;
        final double itemWidth = ((fullWidth - 8) / 2).floorToDouble();
        final bool hasSingleLast = options.length.isOdd;

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(options.length, (index) {
            final String option = options[index];
            final bool isSingleLast =
                hasSingleLast && index == options.length - 1;

            return SizedBox(
              width: isSingleLast ? fullWidth : itemWidth,
              child: OptionChip(
                label: option,
                isSelected: selected.contains(option),
                onTap: () => onTap(option),
              ),
            );
          }),
        );
      },
    );
  }
}
