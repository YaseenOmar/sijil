import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sijil/core/theme/app_colors.dart';
import 'package:sijil/core/widgets/custom_app_bar.dart';

// Shared page shell for the family creation screens:
// RTL + CustomAppBar + scrollable body + tap outside to close keyboard
class FamilyFlowScaffold extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const FamilyFlowScaffold({
    super.key,
    required this.title,
    required this.children,
    this.icon = Icons.family_restroom_outlined,
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
            icon: icon,
            iconAtStart: true,
            onIconPressed: () => Get.back(),
          ),

          // SingleChildScrollView prevents bottom overflow when keyboard opens
          body: SafeArea(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
