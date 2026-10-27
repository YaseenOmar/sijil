import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sijil/core/theme/app_colors.dart';
import 'package:sijil/core/widgets/app_status_card.dart';
import 'package:sijil/core/widgets/custom_app_bar.dart';
import 'package:sijil/features/families/views/widgets/family_list_screen.dart';
import 'package:sijil/features/family_creation/views/family_basic_info_screen.dart';
import 'package:sijil/features/home/widgets/home_area_row.dart';
import 'package:sijil/features/home/widgets/home_bottom_nav_bar.dart';
import 'package:sijil/features/home/widgets/home_quick_actions.dart';
import 'package:sijil/features/home/widgets/home_stats_grid.dart';
import 'package:sijil/core/widgets/custom_bottom_nav_bar.dart';

/// Main screen shown after a successful login.
///
/// This screen only arranges the sections and handles navigation.
/// Each section lives in its own widget inside `widgets/`.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const double _screenPadding = 20;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.neutralBackground,
        appBar:  CustomAppBar(
          title: 'صباح الخير، أحمد',
          action: Icons.notifications_outlined,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(_screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'جمعية الأمان · العامل الميداني',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                const AppStatusCard(
                  title: 'دون اتصال · ٧ عمليات بانتظار المزامنة',
                  message:
                  'تابع عملك على الجهاز. تُرسل التغييرات عند عودة الاتصال.',
                  type: AppStatusType.offline,
                ),
                const SizedBox(height: 20),
                const HomeAreaRow(),
                const SizedBox(height: 16),
                const HomeStatsGrid(),
                const SizedBox(height: 24),
                HomeQuickActions(onAddFamily: _openCreateFamily),
              ],
            ),
          ),
        ),
        bottomNavigationBar: CustomBottomNavBar(selectedIndex: 0)
      ),
    );
  }

  void _openCreateFamily() {
    Get.to(() => FamilyBasicInfoScreen());
  }

  void _onTabSelected(HomeTab tab) {
    // Only the families tab is inside the sprint scope.
    // The other tabs are visual only for now.
    if (tab == HomeTab.families) {
      Get.to(() => const FamilyListScreen());
    }
  }
}
