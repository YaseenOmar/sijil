import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sijil/core/theme/app_colors.dart';
import 'package:sijil/core/widgets/custom_app_bar.dart';

// Shared page shell for the referral screens:
// RTL + CustomAppBar + scrollable body + tap outside to close keyboard
class ReferralFlowScaffold extends StatelessWidget {
  final String title;

  // Small line above the title (ex: "٠١٦ · متابعة الخدمات")
  final String breadcrumb;

  // Line under the title (ex: the signed in employee), shown first in the body
  final String? subtitleLine;

  final List<Widget> children;
  final IconData icon;
  final bool iconAtStart;
  final VoidCallback? onIconPressed;
  final Widget? bottomNavigationBar;

  const ReferralFlowScaffold({
    super.key,
    required this.title,
    required this.breadcrumb,
    required this.children,
    this.subtitleLine,
    this.icon = Icons.arrow_back,
    this.iconAtStart = true,
    this.onIconPressed,
    this.bottomNavigationBar,
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
            icon: icon,
            iconOnRight: iconAtStart,
            onIconPressed: onIconPressed ?? () => Get.back(),
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
