
import 'package:flutter/material.dart';
import 'package:sijil/core/theme/app_colors.dart';

class FormDropdownField extends StatelessWidget {
  final String label;
  final bool isRequired;
  final String? hint;
  final String? helperText;
  final String? value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?>? onChanged;
  final String? Function(String?)? validator;

  const FormDropdownField({
    super.key,
    required this.label,
    required this.items,
    required this.onChanged,
    this.isRequired = false,
    this.hint,
    this.helperText,
    this.value,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    // Ensure selected value exists in the available items.
    // Useful when items are loaded asynchronously from Firestore.
    final bool valueExists = value != null &&
        items.any((item) => item.value == value);

    final String? selectedValue =
    valueExists ? value : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isRequired ? '$label *' : label,
          style: const TextStyle(
            fontSize: 14,
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),

        const SizedBox(height: 8),

        DropdownButtonFormField<String>(
          // Rebuild field state when external value changes.
          key: ValueKey<String?>(
            selectedValue,
          ),

          initialValue: selectedValue,
          items: items,
          onChanged: onChanged,
          validator: validator,

          isExpanded: true,

          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.textSecondary,
          ),

          dropdownColor: AppColors.surface,
          borderRadius: BorderRadius.circular(12),

          style: const TextStyle(
            fontSize: 15,
            fontFamily: 'Cairo',
            color: AppColors.textPrimary,
          ),

          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: AppColors.textSecondary,
            ),

            helperText: helperText,
            helperMaxLines: 3,
            errorMaxLines: 3,

            filled: true,
            fillColor: AppColors.surface,

            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),

            border: _border(AppColors.border),
            enabledBorder: _border(AppColors.border),
            focusedBorder: _border(AppColors.primary),
            errorBorder: _border(AppColors.error),
            focusedErrorBorder: _border(AppColors.error),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _border(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color),
    );
  }
}
