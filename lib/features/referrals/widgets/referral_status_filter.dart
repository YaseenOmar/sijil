import 'package:flutter/material.dart';
import 'package:sijil/core/theme/app_colors.dart';

// Status filter as two columns of radio tiles, single select (touch target >= 48dp)
class ReferralStatusFilter extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  const ReferralStatusFilter({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final List<Widget> rows = [];

    for (int i = 0; i < options.length; i += 2) {
      final bool hasSecond = i + 1 < options.length;

      rows.add(
        Row(
          children: [
            Expanded(child: _tile(options[i])),
            const SizedBox(width: 8),
            Expanded(
              child: hasSecond ? _tile(options[i + 1]) : const SizedBox(),
            ),
          ],
        ),
      );

      if (hasSecond && i + 2 < options.length) {
        rows.add(const SizedBox(height: 16));
      }
    }

    return Column(children: rows);
  }

  Widget _tile(String option) {
    return _FilterTile(
      label: option,
      isSelected: option == selected,
      onTap: () => onSelected(option),
    );
  }
}

class _FilterTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterTile({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.check_circle_outline
                        : Icons.circle_outlined,
                    size: 22,
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
                        color: isSelected
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
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
