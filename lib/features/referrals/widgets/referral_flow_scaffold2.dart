import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sijil/core/theme/app_colors.dart';
import 'package:sijil/core/widgets/custom_app_bar.dart';

// Shared page shell for the referral screens:
// RTL + CustomAppBar + scrollable body + tap outside to close keyboard
// Leading icon = right side (back by default), action icon = left side (optional)
class ReferralFlowScaffold2 extends StatelessWidget {
  final String title;

  // Small line above the title (ex: "٠١٦ · متابعة الخدمات")
  final String breadcrumb;

  // Line under the title (ex: the signed in employee), shown first in the body
  final String? subtitleLine;

  final List<Widget> children;
  final IconData icon;
  final bool iconAtStart;
  final VoidCallback? onIconPressed;

  // Optional icon on the left side of the app bar
  final IconData? actionIcon;
  final VoidCallback? onActionPressed;

  final Widget? bottomNavigationBar;

  const ReferralFlowScaffold2({
    super.key,
    required this.title,
    required this.breadcrumb,
    required this.children,
    this.subtitleLine,
    this.icon = Icons.arrow_back,
    this.iconAtStart = true,
    this.onIconPressed,
    this.actionIcon,
    this.onActionPressed,
    this.bottomNavigationBar, void Function()? onLeadingPressed, IconData? leadingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
          backgroundColor: AppColors.neutralBackground,
          appBar: CustomAppBar(
            title: title,
            subtitle: breadcrumb,
            leading: Icons.arrow_back,
            onLeadingPressed: () => Get.back(),
          ),
          bottomNavigationBar: bottomNavigationBar,

          // SingleChildScrollView prevents bottom overflow when keyboard opens
          body: SafeArea(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (subtitleLine != null) ...[
                    Text(
                      subtitleLine!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
