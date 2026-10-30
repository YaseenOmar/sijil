
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:sijil/core/widgets/custom_app_bar.dart';
import 'package:sijil/core/widgets/custom_bottom_nav_bar.dart';
import 'package:sijil/core/theme/app_colors.dart';

import '../controllers/assistance_controller.dart';
import '../data/assistance_repository.dart';
import '../data/assistance_remote_data_source.dart';
import '../models/assistance_assignment_model.dart';
import '../models/assistance_model.dart';

import 'assign_assistance_screen.dart';
import 'assistance_history_screen.dart';

class AssistanceDashboardScreen extends StatefulWidget {
  final String organizationId;

  const AssistanceDashboardScreen({
    super.key,
    required this.organizationId,
  });

  @override
  State<AssistanceDashboardScreen> createState() =>
      _AssistanceDashboardScreenState();
}

class _AssistanceDashboardScreenState
    extends State<AssistanceDashboardScreen> {
  late final AssistanceController controller;

  String? selectedAssistanceId;
  DateTimeRange? selectedDateRange;

  @override
  void initState() {
    super.initState();

    if (Get.isRegistered<AssistanceController>()) {
      controller = Get.find<AssistanceController>();
    } else {
      controller = Get.put(
        AssistanceController(
          organizationId: widget.organizationId,
          repository: AssistanceRepository(
            remoteDataSource: AssistanceRemoteDataSource(),
          ),
        ),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadDashboardAssignments();
    });
  }

  Future<void> _selectDateRange() async {
    final now = DateTime.now();

    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1),
      initialDateRange: selectedDateRange,
      helpText: 'اختر الفترة الزمنية',
    );

    if (result != null && mounted) {
      setState(() {
        selectedDateRange = result;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day}';
  }

  List<AssistanceAssignmentModel> get filteredAssignments {
    return controller.dashboardAssignments.where((assignment) {
      if (selectedAssistanceId != null &&
          assignment.assistanceId != selectedAssistanceId) {
        return false;
      }

      if (selectedDateRange != null) {
        final date = assignment.assignedAt;
        final start = selectedDateRange!.start;
        final end = selectedDateRange!.end;

        final startDate = DateTime(
          start.year,
          start.month,
          start.day,
        );

        final endExclusive = DateTime(
          end.year,
          end.month,
          end.day + 1,
        );

        if (date.isBefore(startDate) ||
            !date.isBefore(endExclusive)) {
          return false;
        }
      }

      return true;
    }).toList()
      ..sort(
            (a, b) => b.assignedAt.compareTo(a.assignedAt),
      );
  }

  String _assistanceName(String assistanceId) {
    for (final assistance in controller.assistances) {
      if (assistance.id == assistanceId) {
        return assistance.name;
      }
    }
    return assistanceId;
  }

  String _statusText(String status) {
    switch (status) {
      case AssistanceAssignmentModel.statusAssigned:
        return 'تم التخصيص';

      case AssistanceAssignmentModel.statusDelivered:
        return 'تم التسليم';

      case AssistanceAssignmentModel.statusCancelled:
        return 'ملغاة';

      default:
        return 'غير معروفة';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case AssistanceAssignmentModel.statusDelivered:
        return AppColors.primary;

      case AssistanceAssignmentModel.statusCancelled:
        return Colors.red.shade700;

      default:
        return Colors.orange.shade800;
    }
  }

  Widget _buildMetricCard(
      String value,
      String title,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 14,
        horizontal: 12,
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
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentCard(
      AssistanceAssignmentModel assignment,
      ) {
    final color = _statusColor(assignment.status);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Get.to(
              () => const AssistanceHistoryScreen(),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade200,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الأسرة: ${assignment.familyId}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              _assistanceName(assignment.assistanceId),
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              'تاريخ التخصيص: '
                  '${_formatDate(assignment.assignedAt)}'
                  ' · المنطقة: ${assignment.areaId}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 8),

            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _statusText(assignment.status),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ),
          ],
        ),
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
          title: 'المساعدات',
          action: Icons.refresh,
          onActionPressed: () async {
            await controller.loadAssistances();
            await controller.loadDashboardAssignments();
          },
        ),

        body: RefreshIndicator(
          onRefresh: () async {
            await controller.loadAssistances();
            await controller.loadDashboardAssignments();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Obx(() {
                  final assignments =
                      controller.dashboardAssignments;

                  final now = DateTime.now();

                  final deliveredThisMonth = assignments.where(
                        (item) =>
                    item.status ==
                        AssistanceAssignmentModel.statusDelivered &&
                        item.assignedAt.year == now.year &&
                        item.assignedAt.month == now.month,
                  ).length;

                  final benefitedFamilies = assignments
                      .where(
                        (item) =>
                    item.status !=
                        AssistanceAssignmentModel.statusCancelled,
                  )
                      .map((item) => item.familyId)
                      .toSet()
                      .length;

                  return Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          '$deliveredThisMonth',
                          'عمليات مسلّمة من تخصيصات هذا الشهر',
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: _buildMetricCard(
                          '$benefitedFamilies',
                          'أسر لديها تخصيصات',
                        ),
                      ),
                    ],
                  );
                }),

                const SizedBox(height: 16),

                const Text(
                  'الفترة',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                InkWell(
                  onTap: _selectDateRange,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 18,
                        ),
                        const SizedBox(width: 8),

                        Expanded(
                          child: Text(
                            selectedDateRange == null
                                ? 'جميع الفترات المحمّلة'
                                : '${_formatDate(selectedDateRange!.start)}'
                                ' - '
                                '${_formatDate(selectedDateRange!.end)}',
                          ),
                        ),

                        if (selectedDateRange != null)
                          IconButton(
                            onPressed: () {
                              setState(() {
                                selectedDateRange = null;
                              });
                            },
                            icon: const Icon(Icons.close),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                const Text(
                  'نوع المساعدة',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Obx(() {
                  final types =
                  controller.assistances.toList();

                  return DropdownButtonFormField<String>(
                    value: selectedAssistanceId != null &&
                        types.any(
                              (item) =>
                          item.id == selectedAssistanceId,
                        )
                        ? selectedAssistanceId
                        : null,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    hint: const Text('جميع أنواع المساعدات'),
                    items: [
                      const DropdownMenuItem<String>(
                        value: '',
                        child: Text('جميع المساعدات'),
                      ),
                      ...types.map(
                            (assistance) => DropdownMenuItem(
                          value: assistance.id,
                          child: Text(assistance.name),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedAssistanceId =
                        value == null || value.isEmpty
                            ? null
                            : value;
                      });
                    },
                  );
                }),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'آخر عمليات المساعدات',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    TextButton(
                      onPressed: () {
                        Get.to(
                              () => const AssistanceHistoryScreen(),
                        );
                      },
                      child: const Text(
                        'عرض جميع العمليات',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Obx(() {
                  if (controller.isDashboardLoading.value) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(30),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (controller.dashboardError.value.isNotEmpty) {
                    return Column(
                      children: [
                        Text(controller.dashboardError.value),
                        TextButton(
                          onPressed:
                          controller.loadDashboardAssignments,
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    );
                  }

                  final list = filteredAssignments;

                  if (list.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 30),
                      child: Center(
                        child: Text(
                          'لا توجد عمليات مساعدات لعرضها',
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics:
                    const NeverScrollableScrollPhysics(),
                    itemCount: list.length,
                    separatorBuilder: (_, __) =>
                    const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      return _buildAssignmentCard(
                        list[index],
                      );
                    },
                  );
                }),

                const SizedBox(height: 14),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 18,
                        color: Colors.grey,
                      ),

                      SizedBox(width: 8),

                      Expanded(
                        child: Text(
                          'تعرض الشاشة العمليات المسموح بها '
                              'وفق صلاحيات حسابك. '
                              'فترة منع التكرار تبدأ من تاريخ التخصيص.',
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await Get.to(
                            () => const CreateAssistanceScreen(),
                      );

                      await controller.loadDashboardAssignments();
                    },
                    icon: const Icon(
                      Icons.add,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'تخصيص مساعدة',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),
              ],
            ),
          ),
        ),

        bottomNavigationBar:
        const CustomBottomNavBar(selectedIndex: 2),
      ),
    );
  }
}
