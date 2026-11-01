
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:sijil/core/theme/app_colors.dart';
import 'package:sijil/core/widgets/custom_app_bar.dart';
import 'package:sijil/core/widgets/custom_bottom_nav_bar.dart';

import '../controllers/service_catalog_controller.dart';
import '../data/models/service_model.dart';
import 'add_service_screen.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  late final ServiceCatalogController controller;
  late final String _controllerTag;

  final searchController = TextEditingController();

  String searchQuery = '';
  String selectedFilter = 'all';

  static const Map<String, String> categories = {
    'food': 'مساعدات غذائية',
    'hygiene': 'مستلزمات نظافة',
    'education': 'دعم تعليمي',
    'medical': 'دعم طبي',
    'shelter': 'دعم إيواء',
    'cash': 'مساعدات نقدية',
    'other': 'أخرى',
  };

  @override
  void initState() {
    super.initState();

    _controllerTag = identityHashCode(this).toString();

    controller = Get.put(
      ServiceCatalogController(),
      tag: _controllerTag,
    );
  }

  @override
  void dispose() {
    searchController.dispose();

    if (Get.isRegistered<ServiceCatalogController>(
      tag: _controllerTag,
    )) {
      Get.delete<ServiceCatalogController>(
        tag: _controllerTag,
      );
    }

    super.dispose();
  }

  List<ServiceModel> get filteredServices {
    return controller.services.where((service) {
      final query = searchQuery.trim().toLowerCase();

      final matchesSearch =
          service.name.toLowerCase().contains(query) ||
              service.description.toLowerCase().contains(query) ||
              (categories[service.category] ?? service.category)
                  .toLowerCase()
                  .contains(query);

      final matchesFilter = switch (selectedFilter) {
        'active' => service.isActive,
        'inactive' => !service.isActive,
        _ => true,
      };

      return matchesSearch && matchesFilter;
    }).toList();
  }

  Future<void> _openAddService() async {
    final result = await Get.to<bool>(
          () => const AddServiceScreen(),
    );

    if (!mounted) return;

    if (result == true) {
      await controller.loadServices();
    }
  }

  void _confirmStatusChange(ServiceModel service) {
    final newStatus = !service.isActive;

    Get.defaultDialog(
      title: newStatus ? 'تفعيل الخدمة' : 'إيقاف الخدمة',
      middleText: newStatus
          ? 'هل تريد تفعيل خدمة "${service.name}"؟'
          : 'هل تريد إيقاف خدمة "${service.name}"؟ '
          'لن تكون متاحة للتخصيصات الجديدة.',
      textConfirm: 'تأكيد',
      textCancel: 'إلغاء',
      confirmTextColor: Colors.white,
      buttonColor: AppColors.primary,
      onConfirm: () {
        Get.back();
        controller.changeServiceStatus(
          service,
          newStatus,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.neutralBackground,

        appBar: CustomAppBar(
          title: 'الخدمات',
          subtitle: 'إدارة خدمات المؤسسة',
          action: Icons.tune,
          onActionPressed: controller.loadServices,
        ),

        bottomNavigationBar:
        const CustomBottomNavBar(selectedIndex: 2),

        floatingActionButtonLocation:
        FloatingActionButtonLocation.centerFloat,

        floatingActionButton: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: FloatingActionButton.extended(
              heroTag: 'addServiceButton',
              onPressed: _openAddService,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              icon: const Icon(Icons.add),
              label: const Text(
                'إضافة خدمة',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),

        body: RefreshIndicator(
          onRefresh: controller.loadServices,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
            children: [

              // Service metrics
              Obx(
                    () => Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        '${controller.totalServices}',
                        'كل الخدمات',
                        Icons.inventory_2_outlined,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMetricCard(
                        '${controller.activeServices}',
                        'متاحة',
                        Icons.check_circle_outline,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMetricCard(
                        '${controller.inactiveServices}',
                        'متوقفة',
                        Icons.pause_circle_outline,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Search
              TextField(
                controller: searchController,
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'ابحث عن خدمة أو تصنيف',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey.shade200,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Status filters
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildFilterChip('all', 'الكل'),
                  _buildFilterChip('active', 'المتاحة'),
                  _buildFilterChip('inactive', 'المتوقفة'),
                ],
              ),

              const SizedBox(height: 24),

              const Text(
                'قائمة الخدمات',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 14),

              // Services list
              Obx(() {
                if (controller.isLoading.value) {
                  return const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (controller.errorMessage.value.isNotEmpty) {
                  return _buildMessageCard(
                    icon: Icons.error_outline,
                    message: controller.errorMessage.value,
                    showRetry: true,
                  );
                }

                final services = filteredServices;

                if (services.isEmpty) {
                  return _buildMessageCard(
                    icon: Icons.inventory_2_outlined,
                    message: controller.services.isEmpty
                        ? 'لم تتم إضافة خدمات إلى المؤسسة بعد'
                        : 'لا توجد خدمات مطابقة للبحث',
                  );
                }

                return Column(
                  children: [
                    for (final service in services) ...[
                      _buildServiceCard(service),
                      const SizedBox(height: 12),
                    ],
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(
      String value,
      String title,
      IconData icon,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 16,
        horizontal: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 23,
            color: AppColors.primary,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
      String value,
      String label,
      ) {
    final selected = selectedFilter == value;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: const Color(0xFFDDEDEA),
      labelStyle: TextStyle(
        fontFamily: 'Cairo',
        color: selected
            ? AppColors.primary
            : AppColors.textPrimary,
        fontWeight:
        selected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (_) {
        setState(() {
          selectedFilter = value;
        });
      },
    );
  }

  Widget _buildServiceCard(ServiceModel service) {
    final categoryName =
        categories[service.category] ?? service.category;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  service.name,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildStatusBadge(service.isActive),
            ],
          ),

          const SizedBox(height: 6),

          Text(
            categoryName,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            service.description,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              height: 1.6,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 14),

          Divider(color: Colors.grey.shade200),

          const SizedBox(height: 8),

          _buildDetailRow(
            Icons.inventory_outlined,
            'وحدة الخدمة',
            service.unit.isEmpty
                ? 'غير محددة'
                : service.unit,
          ),

          const SizedBox(height: 10),

          _buildDetailRow(
            Icons.call_split_outlined,
            'استقبال الإحالات',
            service.acceptsReferrals
                ? 'مفعّل'
                : 'غير مفعّل',
          ),

          const SizedBox(height: 10),

          _buildDetailRow(
            Icons.event_repeat_outlined,
            'منع التكرار',
            service.hasCooldown
                ? '${service.cooldownDays} يومًا'
                : 'غير مفعّل',
          ),

          if (service.hasCooldown &&
              (service.cooldownReason?.isNotEmpty ?? false)) ...[
            const SizedBox(height: 8),
            Text(
              'السبب: ${service.cooldownReason}',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],

          const SizedBox(height: 14),

          Obx(() {
            final updating =
            controller.updatingServiceIds.contains(service.id);

            return SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: updating
                    ? null
                    : () => _confirmStatusChange(service),
                icon: updating
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
                    : Icon(
                  service.isActive
                      ? Icons.pause_circle_outline
                      : Icons.play_circle_outline,
                ),
                label: Text(
                  service.isActive
                      ? 'إيقاف الخدمة'
                      : 'تفعيل الخدمة',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(
                    color: AppColors.primary,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    final color =
    isActive ? AppColors.primary : Colors.orange.shade800;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? 'متاحة' : 'متوقفة',
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildDetailRow(
      IconData icon,
      String title,
      String value,
      ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 17,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 8),
        Text(
          '$title: ',
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageCard({
    required IconData icon,
    required String message,
    bool showRetry = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: AppColors.textSecondary,
            size: 36,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Cairo',
              color: AppColors.textSecondary,
            ),
          ),
          if (showRetry) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: controller.loadServices,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ],
      ),
    );
  }
}
