import 'package:flutter/material.dart';
import 'package:sijil/core/theme/app_colors.dart';

/// Tabs of the bottom bar, in the same order they are displayed.
enum HomeTab { home, families, aid, referrals, account }

class HomeBottomNavBar extends StatelessWidget {
  const HomeBottomNavBar({super.key, required this.onTabSelected});

  final ValueChanged<HomeTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: HomeTab.home.index,
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.successBackground,
      onDestinationSelected: (index) => onTabSelected(HomeTab.values[index]),
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
