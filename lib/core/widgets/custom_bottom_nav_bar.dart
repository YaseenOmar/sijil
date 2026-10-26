import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../features/families/views/widgets/family_list_screen.dart';
import '../../features/home/views/home_screen.dart';
import '../theme/app_colors.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;

  const CustomBottomNavBar({super.key, required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex,
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.successBackground,

      onDestinationSelected: (index) {
        // Don't navigate if already on selected page
        if (index == selectedIndex) return;

        switch (index) {
          case 0:
            Get.off(() => const HomeScreen());
            break;

          case 1:
            Get.off(() => const FamilyListScreen());
            break;

          case 2:
            // Assistance screen (later)
            break;

          case 3:
            // Referrals screen (later)
            break;

          case 4:
            // Account screen (later)
            break;
        }
      },

      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home, color: AppColors.primary),
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
