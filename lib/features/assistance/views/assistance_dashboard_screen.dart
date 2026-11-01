
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:sijil/core/theme/app_colors.dart';
import 'package:sijil/core/widgets/custom_app_bar.dart';
import 'package:sijil/core/widgets/custom_bottom_nav_bar.dart';

import '../controllers/assistance_controller.dart';
import '../data/assistance_repository.dart';
import '../data/assistance_remote_data_source.dart';
import '../models/assistance_assignment_model.dart';

import 'assign_assistance_screen.dart';

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

  String? selectedServiceId;
  DateTimeRange? selectedDateRange;

  final Map<String, String> familyNames = {};

  bool isLoadingFamilyNames = false;

  @override
  void initState() {
    super.initState();

    // Reuse the registered controller if available.
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
      if (mounted) {
        _refreshDashboard();
      }
    });
  }

  // =========================================================
  // REFRESH DASHBOARD
  // =========================================================

  Future<void> _refreshDashboard() async {
    await Future.wait([
      controller.loadServices(),
      controller.loadDashboardAssignments(),
    ]);

    if (!mounted) return;

    if (controller.dashboardError.value.isEmpty) {
      await _loadFamilyNames();
    }
  }

  // =========================================================
  // LOAD FAMILY NAMES
  // =========================================================

  Future<void> _loadFamilyNames() async {
    if (isLoadingFamilyNames) return;

    try {
      setState(() {
        isLoadingFamilyNames = true;
      });

      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        return;
      }

      final firestore = FirebaseFirestore.instance;

      final profileDoc = await firestore
          .collection('users')
          .doc(user.uid)
          .get(const GetOptions(source: Source.server));

      final profile = profileDoc.data();

      if (profile == null ||
          profile['status'] != 'active' ||
          profile['organizationId'] != widget.organizationId) {
        return;
      }

      final role = profile['role'] as String?;

      if (role != 'field_worker' && role != 'supervisor') {
        return;
      }

      final areaId = profile['areaId'] as String?;

      final assignments =
      controller.dashboardAssignments.toList();

      final familyIds = assignments
          .map((assignment) => assignment.familyId)
          .where((id) => id.isNotEmpty)
          .toSet();

      final familiesCollection = firestore
          .collection('organizations')
          .doc(widget.organizationId)
          .collection('families');

      final loadedNames = <String, String>{};

      for (final familyId in familyIds) {
        try {
          final doc = await familiesCollection
              .doc(familyId)
              .get(const GetOptions(source: Source.server));

          if (!doc.exists) continue;

          final data = doc.data();

          if (data == null) continue;

          // Preserve field-worker area restrictions.
          if (role == 'field_worker' &&
              data['areaId'] != areaId) {
            continue;
          }

          loadedNames[familyId] =
              data['headName'] as String? ?? familyId;
        } on FirebaseException {
          // A missing or inaccessible family should not
          // prevent the dashboard from loading.
          continue;
        }
      }

      if (!mounted) return;

      setState(() {
        familyNames
          ..clear()
          ..addAll(loadedNames);
      });
    } catch (_) {
      // Assignment data can still be displayed using IDs.
    } finally {
      if (mounted) {
        setState(() {
          isLoadingFamilyNames = false;
        });
      }
    }
  }

  // =========================================================
  // DATE FILTER
  // =========================================================

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
    final localDate = date.toLocal();

    return '${localDate.day}/'
        '${localDate.month}/'
        '${localDate.year}';
  }

  // =========================================================
  // FILTER ASSIGNMENTS
  // =========================================================

  List<AssistanceAssignmentModel> get filteredAssignments {
    final result = controller.dashboardAssignments.where(
          (assignment) {
        if (selectedServiceId != null &&
            assignment.serviceId != selectedServiceId) {
          return false;
        }

        if (selectedDateRange != null) {
          final date = assignment.assignedAt.toLocal();

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
      },
    ).toList();

    result.sort(
          (a, b) => b.assignedAt.compareTo(a.assignedAt),
    );

    return result;
  }

  // =========================================================
  // DISPLAY HELPERS
  // =========================================================

  String _serviceName(String serviceId) {
    for (final service in controller.services) {
      if (service.id == serviceId) {
        return service.name;
      }
    }

    return 'خدمة ($serviceId)';
  }

  String _familyName(String familyId) {
    return familyNames[familyId] ?? familyId;
  }

  String _statusText(String status) {
    switch (status) {
      case AssistanceAssignmentModel.statusAssigned:
        return 'تم التخصيص';

      case AssistanceAssignmentModel.statusDelivered:
        return 'تم التسليم';

      case AssistanceAssignmentModel.statusCanceled:
        return 'ملغاة';

      default:
        return 'حالة غير معروفة';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case AssistanceAssignmentModel.statusAssigned:
        return Colors.orange.shade800;

      case AssistanceAssignmentModel.statusDelivered:
        return AppColors.primary;

      case AssistanceAssignmentModel.statusCanceled:
        return Colors.red.shade700;

      default:
        return Colors.grey.shade700;
    }
  }

  // =========================================================
  // METRIC CARD
  // =========================================================

  Widget _buildMetricCard({
    required String value,
    required String title,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 16,
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
          Icon(
            icon,
            color: AppColors.primary,
            size: 25,
          ),

          const SizedBox(height: 8),

          Text(
            value,
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // ASSIGNMENT DETAILS
  // =========================================================

  void _showAssignmentDetails(
      AssistanceAssignmentModel assignment,
      ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تفاصيل المساعدة'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  _detailRow(
                    'الأسرة',
                    _familyName(assignment.familyId),
                  ),

                  _detailRow(
                    'الخدمة',
                    _serviceName(assignment.serviceId),
                  ),

                  _detailRow(
                    'تاريخ التخصيص',
                    _formatDate(assignment.assignedAt),
                  ),

                  _detailRow(
                    'الحالة',
                    _statusText(assignment.status),
                  ),

                  _detailRow(
                    'معرف الموظف',
                    assignment.assignedBy,
                  ),

                  if (assignment.nextEligibleAt != null)
                    _detailRow(
                      'تاريخ انتهاء فترة المنع',
                      _formatDate(
                        assignment.nextEligibleAt!,
                      ),
                    ),

                  if (assignment.notes.isNotEmpty)
                    _detailRow(
                      'ملاحظات',
                      assignment.notes,
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text('إغلاق'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // ASSIGNMENT CARD
  // =========================================================

  Widget _buildAssignmentCard(
      AssistanceAssignmentModel assignment,
      ) {
    final color = _statusColor(assignment.status);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        _showAssignmentDetails(assignment);
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
            Row(
              children: [
                const Icon(
                  Icons.family_restroom,
                  color: AppColors.primary,
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: Text(
                    _familyName(assignment.familyId),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              _serviceName(assignment.serviceId),
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade800,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'تاريخ التخصيص: '
                  '${_formatDate(assignment.assignedAt)}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 10),

            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(7),
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

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor:
        AppColors.neutralBackground,

        appBar: CustomAppBar(
          title: 'المساعدات',
          action: Icons.refresh,
          onActionPressed: _refreshDashboard,
        ),

        body: RefreshIndicator(
          onRefresh: _refreshDashboard,
          child: SingleChildScrollView(
            physics:
            const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.stretch,
              children: [
                // -----------------------------------
                // DASHBOARD METRICS
                // -----------------------------------

                Obx(() {
                  final assignments =
                      controller.dashboardAssignments;

                  final totalAssignments = assignments
                      .where(
                        (item) =>
                    item.status !=
                        AssistanceAssignmentModel
                            .statusCanceled,
                  )
                      .length;

                  final uniqueFamilies = assignments
                      .where(
                        (item) =>
                    item.status !=
                        AssistanceAssignmentModel
                            .statusCanceled,
                  )
                      .map((item) => item.familyId)
                      .toSet()
                      .length;

                  return Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          value: '$totalAssignments',
                          title:
                          'تخصيصات ضمن آخر 100 عملية',
                          icon:
                          Icons.volunteer_activism_outlined,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: _buildMetricCard(
                          value: '$uniqueFamilies',
                          title:
                          'أسر ضمن العمليات المحمّلة',
                          icon: Icons.groups_outlined,
                        ),
                      ),
                    ],
                  );
                }),

                const SizedBox(height: 18),

                // -----------------------------------
                // DATE FILTER
                // -----------------------------------

                const Text(
                  'الفترة',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                InkWell(
                  onTap: _selectDateRange,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                      BorderRadius.circular(10),
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

                        const SizedBox(width: 10),

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
                            icon: const Icon(
                              Icons.close,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // -----------------------------------
                // SERVICE FILTER
                // -----------------------------------

                const Text(
                  'نوع المساعدة',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Obx(() {
                  final services =
                  controller.services.toList();

                  final selectedExists =
                  services.any(
                        (item) =>
                    item.id == selectedServiceId,
                  );

                  final selectedValue =
                  selectedServiceId != null &&
                      selectedExists
                      ? selectedServiceId!
                      : '';

                  return DropdownButtonFormField<String>(
                    key: ValueKey(selectedValue),
                    initialValue: selectedValue,
                    isExpanded: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius:
                        BorderRadius.circular(10),
                      ),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: '',
                        child: Text(
                          'جميع المساعدات',
                        ),
                      ),

                      ...services.map(
                            (service) =>
                            DropdownMenuItem<String>(
                              value: service.id,
                              child: Text(
                                service.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedServiceId =
                        value == null ||
                            value.isEmpty
                            ? null
                            : value;
                      });
                    },
                  );
                }),

                const SizedBox(height: 22),

                // -----------------------------------
                // LATEST ASSIGNMENTS
                // -----------------------------------

                const Text(
                  'آخر عمليات المساعدات',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  'يتم عرض وتصفية آخر 100 عملية كحد أقصى.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 12),

                Obx(() {
                  if (controller
                      .isDashboardLoading.value) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(30),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (controller
                      .dashboardError.value.isNotEmpty) {
                    return Column(
                      children: [
                        Text(
                          controller.dashboardError.value,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.red,
                          ),
                        ),

                        TextButton(
                          onPressed: _refreshDashboard,
                          child: const Text(
                            'إعادة المحاولة',
                          ),
                        ),
                      ],
                    );
                  }

                  final list = filteredAssignments;

                  if (list.isEmpty) {
                    return const Padding(
                      padding:
                      EdgeInsets.symmetric(vertical: 30),
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

                const SizedBox(height: 20),

                // -----------------------------------
                // CREATE ASSIGNMENT
                // -----------------------------------

                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await Get.to(
                            () => const CreateAssistanceScreen(),
                      );

                      if (mounted) {
                        await _refreshDashboard();
                      }
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
                      backgroundColor:
                      AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
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
