
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool isRequired;
  final bool enabled;
  final bool readOnly;
  final String? errorText;
  final String? helperText;
  final TextInputType keyboardType;
  final int maxLines;

  final bool obscureText;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconPressed;

  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.isRequired = false,
    this.enabled = true,
    this.readOnly = false,
    this.errorText,
    this.helperText,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.obscureText = false,
    this.suffixIcon,
    this.onSuffixIconPressed,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasError =
        errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isRequired ? '$label *' : label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          readOnly: readOnly,
          keyboardType: keyboardType,
          maxLines: maxLines,
          obscureText: obscureText,
          onChanged: onChanged,
          validator: validator,
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize: 15,
            color: enabled
                ? AppColors.textPrimary
                : AppColors.disabledText,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: AppColors.textSecondary,
            ),
            filled: true,
            fillColor: (!enabled || readOnly)
                ? AppColors.neutralBackground
                : AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            errorText: errorText,
            helperText: helperText,
            errorMaxLines: 3,
            helperMaxLines: 3,

            suffixIcon: suffixIcon != null
                ? IconButton(
              icon: Icon(
                suffixIcon,
                color: AppColors.textSecondary,
              ),
              onPressed: onSuffixIconPressed,
            )
                : null,

            border: _border(AppColors.border),
            enabledBorder: _border(
              hasError ? AppColors.error : AppColors.border,
            ),
            focusedBorder: _border(
              hasError ? AppColors.error : AppColors.primary,
            ),
            errorBorder: _border(AppColors.error),
            focusedErrorBorder: _border(AppColors.error),
            disabledBorder: _border(AppColors.border),
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
