
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:sijil/core/theme/app_colors.dart';
import 'package:sijil/core/widgets/app_button.dart';
import 'package:sijil/core/widgets/custom_app_bar.dart';
import 'package:sijil/core/widgets/custom_bottom_nav_bar.dart';

import 'package:sijil/features/auth/controllers/user_session_controller.dart';
import 'package:sijil/features/families/controllers/family_list_controller.dart';
import 'package:sijil/features/families/views/widgets/family_card.dart';
import 'package:sijil/features/family_creation/views/family_basic_info_screen.dart';

import 'family_details_screen.dart';

enum FamilySortMode {
  defaultOrder,
  name,
  membersCount,
}

class FamilyListScreen extends StatefulWidget {
  const FamilyListScreen({super.key});

  @override
  State<FamilyListScreen> createState() =>
      _FamilyListScreenState();
}

class _FamilyListScreenState extends State<FamilyListScreen> {
  late final UserSessionController session;
  late final FamilyListController controller;

  FamilySortMode sortMode = FamilySortMode.defaultOrder;

  @override
  void initState() {
    super.initState();

    session = Get.find<UserSessionController>();

    controller = Get.isRegistered<FamilyListController>()
        ? Get.find<FamilyListController>()
        : Get.put(FamilyListController());
  }

  String get areaTitle {
    if (session.role.value == 'supervisor') {
      return 'أسر المؤسسة';
    }

    final name = session.areaName.value.trim();

    return name.isNotEmpty
        ? 'أسر $name'
        : 'أسر منطقتك';
  }

  String get areaSubtitle {
    if (session.role.value == 'supervisor') {
      return 'جميع مناطق المؤسسة';
    }

    final name = session.areaName.value.trim();

    return name.isNotEmpty
        ? '$name · نطاقك المكلف به'
        : 'نطاقك المكلف به';
  }

  void _openFilters() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20, 8, 20, 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'ترتيب الأسر',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                _sortTile(
                  sheetContext,
                  'الترتيب الافتراضي',
                  FamilySortMode.defaultOrder,
                ),
                _sortTile(
                  sheetContext,
                  'حسب اسم رب الأسرة',
                  FamilySortMode.name,
                ),
                _sortTile(
                  sheetContext,
                  'حسب عدد أفراد الأسرة',
                  FamilySortMode.membersCount,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sortTile(
      BuildContext sheetContext,
      String title,
      FamilySortMode mode,
      ) {
    final selected = sortMode == mode;

    return ListTile(
      title: Text(title),
      leading: Icon(
        selected
            ? Icons.radio_button_checked
            : Icons.radio_button_unchecked,
        color: selected
            ? AppColors.primary
            : AppColors.textSecondary,
      ),
      onTap: () {
        setState(() {
          sortMode = mode;
        });

        Navigator.of(sheetContext).pop();
      },
    );
  }

  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20, 18, 20, 0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'البحث في السجلات المحلية',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          // Search input
          TextField(
            textAlign: TextAlign.right,
            textInputAction: TextInputAction.search,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'الاسم أو رقم الهوية أو الجوال',
              hintStyle: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: AppColors.textSecondary,
              ),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: AppColors.border,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
            ),
            onChanged: controller.filterFamilies,
          ),

          const SizedBox(height: 14),

          // Filter button
          SizedBox(
            height: 54,
            child: OutlinedButton.icon(
              onPressed: _openFilters,
              icon: const Icon(
                Icons.tune,
                size: 21,
              ),
              label: const Text(
                'البحث والتصفية',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                backgroundColor: AppColors.surface,
                side: const BorderSide(
                  color: AppColors.border,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyList() {
    return Expanded(
      child: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
            ),
          );
        }

        if (controller.errorMessage.isNotEmpty) {
          return _buildErrorState();
        }

        final families = controller.families.toList();

        if (sortMode == FamilySortMode.name) {
          families.sort(
                (a, b) => a.headName.compareTo(b.headName),
          );
        } else if (sortMode ==
            FamilySortMode.membersCount) {
          families.sort(
                (a, b) => b.membersCount.compareTo(a.membersCount),
          );
        }

        final isSearching =
            controller.searchQuery.value.isNotEmpty;

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: controller.fetchFamilies,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              0, 22, 0, 18,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                ),
                child: Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        areaTitle,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${families.length} أسرة',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 17),

              if (families.isEmpty)
                _buildEmptyState(isSearching)
              else
                ...families.map(
                      (family) => Padding(
                    padding: const EdgeInsets.only(
                      bottom: 12,
                    ),
                       child:  FamilyCard(
                          family: family,
                          areaName: session.areaName.value,
                          onTap: () {
                            Get.to(
                                  () => FamilyDetailsScreen(family: family),
                            );
                          },
                        ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildEmptyState(bool isSearching) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 70,
      ),
      child: Column(
        children: [
          Icon(
            isSearching
                ? Icons.search_off_outlined
                : Icons.groups_outlined,
            size: 56,
            color: AppColors.textSecondary
                .withValues(alpha: 0.6),
          ),
          const SizedBox(height: 16),
          Text(
            isSearching
                ? 'لا توجد نتائج تطابق البحث'
                : 'لا توجد أسر مسجلة حاليًا',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSearching
                ? 'جرّب البحث باسم آخر أو رقم الهوية أو الجوال'
                : 'يمكنك إضافة أسرة جديدة باستخدام الزر بالأسفل',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 12),
            Text(
              controller.errorMessage.value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: controller.fetchFamilies,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        20, 12, 20, 10,
      ),
      color: AppColors.neutralBackground,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppButton(
            text: 'إضافة أسرة',
            icon: Icons.add,
            onPressed: () async {
              await Get.to(
                    () => FamilyBasicInfoScreen(),
              );

              if (!mounted || controller.isClosed) return;

              await controller.fetchFamilies();
            },
          ),
          const SizedBox(height: 12),
          Text(
            session.role.value == 'supervisor'
                ? 'يمكنك مراجعة سجلات الأسر ضمن المؤسسة.'
                : 'تظهر لك أسر منطقتك فقط، وفق صلاحيات حسابك.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.neutralBackground,
        appBar: CustomAppBar(
          title: 'الأسر',
          subtitle: areaSubtitle,
          action: Icons.tune,
        ),
        body: SafeArea(
          child: Column(
            children: [
              _buildSearchSection(),
              _buildFamilyList(),
              _buildBottomAction(),
            ],
          ),
        ),
        bottomNavigationBar: CustomBottomNavBar(
          selectedIndex: 1,
        ),
      ),
    );
  }
}
