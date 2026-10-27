import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CustomAppBar extends StatelessWidget
    implements PreferredSizeWidget {
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {

final String title;
final IconData icon;
final String? subtitle;

// Optional icons
final IconData? leading;
final IconData? action;

// Click actions
final VoidCallback? onLeadingPressed;
final VoidCallback? onActionPressed;

const CustomAppBar({
CustomAppBar({
super.key,
required this.title,
this.icon = Icons.verified_user_outlined,
this.subtitle,
this.leading,
this.action,
this.onLeadingPressed,
this.onActionPressed,
});

@override
Widget build(BuildContext context) {
return Container(
color: AppColors.background,
padding: const EdgeInsets.symmetric(
horizontal: 20,
vertical: 16,
),
child: SafeArea(
bottom: false,
child: Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
// title
Expanded(
child: Text(
title,
textAlign: TextAlign.right,
style: const TextStyle(
fontSize: 32,
fontWeight: FontWeight.bold,
color: AppColors.textPrimary,
),
),
),
return AppBar(
backgroundColor: AppColors.background,
elevation: 0,
scrolledUnderElevation: 0,
automaticallyImplyLeading: false,
toolbarHeight: 80,

const SizedBox(width: 16),
// Right icon in RTL
leadingWidth: leading != null ? 72 : null,
leading: leading != null
? Padding(
padding: const EdgeInsetsDirectional.only(
start: 20,
),
child: _buildIcon(
leading!,
onLeadingPressed,
),
)
: null,

// icon
Container(
width: 48,
height: 48,
decoration: BoxDecoration(
color: AppColors.neutralBackground,
borderRadius: BorderRadius.circular(20),
),
child: Icon(
icon,
color: AppColors.primary,
size: 34,
// Title and subtitle
title: Column(
crossAxisAlignment: CrossAxisAlignment.start,
mainAxisSize: MainAxisSize.min,
children: [
Text(
title,
style: const TextStyle(
fontSize: 24,
fontWeight: FontWeight.bold,
color: AppColors.textPrimary,
),
),

if (subtitle != null) ...[
const SizedBox(height: 5),
Text(
subtitle!,
style: const TextStyle(
fontSize: 13,
color: AppColors.textSecondary,
),
),
],
],
),

// Left icon in RTL
actions: action != null
? [
Padding(
padding: const EdgeInsetsDirectional.only(
end: 20,
),
child: _buildIcon(
action!,
onActionPressed,
),
),
]
: null,
);
}


Widget _buildIcon(
IconData icon,
VoidCallback? onPressed,
) {
return Center(
child: Container(
width: 48,
height: 48,
decoration: BoxDecoration(
color: AppColors.neutralBackground,
borderRadius: BorderRadius.circular(14),
),
child: onPressed != null
? IconButton(
icon: Icon(icon),
iconSize: 24,
color: AppColors.primary,
onPressed: onPressed,
)
: Icon(
icon,
size: 24,
color: AppColors.primary,
),
),
);
}

@override
Size get preferredSize => const Size.fromHeight(120);
Size get preferredSize => const Size.fromHeight(80);
}