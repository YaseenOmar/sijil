
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:sijil/core/theme/app_colors.dart';

import 'package:sijil/features/home/employee/views/home_screen.dart';
import 'package:sijil/features/home/manager/views/manager_home_screen.dart';
import 'package:sijil/features/families/views/widgets/family_list_screen.dart';
import 'package:sijil/features/assistance/views/assistance_dashboard_screen.dart';
import 'package:sijil/features/referrals/views/referrals_screen.dart';
import 'package:sijil/features/account/views/account_settings_screen.dart';
import 'package:sijil/features/service_catalog/views/services_screen.dart';

import '../../features/auth/controllers/user_session_controller.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    final sessionController = Get.find<UserSessionController>();

    final orgId = sessionController.organizationId.value;

    if (orgId.isEmpty) {
      Get.snackbar(
        'خطأ',
        'لم يتم العثور على المؤسسة المرتبطة بحسابك',
      );
    }

    return NavigationBar(
      selectedIndex: selectedIndex,
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.successBackground,

      onDestinationSelected: (index) {
        if (index == selectedIndex) return;

        switch (index) {
          case 0:
            if (sessionController.isSupervisor) {
              Get.off(() => ManagerHomeScreen());
            } else if (sessionController.isFieldWorker) {
              Get.off(() => HomeScreen());
            }
            break;

          case 1:
            Get.off(() => FamilyListScreen());
            break;

          case 2:
            if (sessionController.isSupervisor) {
              Get.off(() => ServicesScreen());
            } else if (sessionController.isFieldWorker) {
              Get.off(() => AssistanceDashboardScreen(organizationId: orgId,));
            }
            break;
            break;

          case 3:
            Get.off(() => ReferralsScreen());
            break;

          case 4:
            Get.off(() => AccountSettingsScreen());
            break;
        }
      },

      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(
            Icons.home,
            color: AppColors.primary,
          ),
          label: 'الرئيسية',
        ),
        NavigationDestination(
          icon: Icon(Icons.groups_outlined),
          label: 'الأسر',
        ),
        NavigationDestination(
          icon: Icon(Icons.volunteer_activism_outlined),
          label: 'المساعدات',
        ),
        NavigationDestination(
          icon: Icon(Icons.send_outlined),
          label: 'الإحالات',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          label: 'الحساب',
        ),
      ],
    );
  }
}
