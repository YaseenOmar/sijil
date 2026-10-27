import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final IconData icon;
  final IconData? leading;
  final IconData? action;
  final String? subtitle;
  final VoidCallback? onIconPressed;
  final VoidCallback? onLeadingPressed;
  final VoidCallback? onActionPressed;
  final bool iconAtStart;

  const CustomAppBar({
    super.key,
    required this.title,
    this.icon = Icons.verified_user_outlined,
    this.leading,
    this.action,
    this.subtitle,
    this.onIconPressed,
    this.onLeadingPressed,
    this.onActionPressed,
    this.iconAtStart = false,
  });

  @override
  Widget build(BuildContext context) {
    final compact = iconAtStart || subtitle != null;
    final leadingIcon =
        leading ?? (iconAtStart && action == null ? icon : null);
    final actionIcon =
        action ?? (!iconAtStart && leading == null ? icon : null);
    final leadingCallback =
        onLeadingPressed ??
        (leading != null || (iconAtStart && action == null)
            ? onIconPressed
            : null);
    final actionCallback =
        onActionPressed ??
        (action != null || (!iconAtStart && leading == null)
            ? onIconPressed
            : null);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        color: AppColors.background,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              if (leadingIcon != null) ...[
                _buildIcon(leadingIcon, leadingCallback, compact, true),
                const SizedBox(width: 16),
              ],
              Expanded(child: _buildTitle(compact)),
              if (actionIcon != null) ...[
                const SizedBox(width: 16),
                _buildIcon(actionIcon, actionCallback, compact, false),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(bool compact) {
    final titleText = Text(
      title,
      textAlign: TextAlign.right,
      style: TextStyle(
        fontSize: compact ? 24 : 32,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );

    if (subtitle == null) return titleText;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          subtitle!,
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        titleText,
      ],
    );
  }

  Widget _buildIcon(
    IconData icon,
    VoidCallback? onPressed,
    bool compact,
    bool isLeading,
  ) {
    return Semantics(
      button: onPressed != null,
      label: isLeading && onPressed != null ? 'رجوع' : null,
      child: Material(
        color: AppColors.neutralBackground,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(
              icon,
              color: AppColors.primary,
              size: compact ? 24 : 34,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(120);
}
