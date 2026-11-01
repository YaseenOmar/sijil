
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_app_bar.dart';

import '../controllers/assistance_controller.dart';
import '../models/assistance_assignment_model.dart';
import 'assign_assistance_screen.dart';

class AssistanceHistoryScreen extends StatefulWidget {
  final FamilyInfo family;

  const AssistanceHistoryScreen({
    super.key,
    required this.family,
  });

  @override
  State<AssistanceHistoryScreen> createState() =>
      _AssistanceHistoryScreenState();
}

class _AssistanceHistoryScreenState
    extends State<AssistanceHistoryScreen> {
  final AssistanceController controller =
  Get.find<AssistanceController>();

  List<AssistanceAssignmentModel> assignments = [];

  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  // =========================================================
  // LOAD FAMILY ASSISTANCE HISTORY
  // =========================================================

  Future<void> _loadHistory() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await controller.loadFamilyHistory(
        widget.family.id,
      );

      result.sort(
            (a, b) => b.assignedAt.compareTo(a.assignedAt),
      );

      if (!mounted) return;

      setState(() {
        assignments = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'تعذر تحميل سجل المساعدات';
        isLoading = false;
      });
    }
  }

  // =========================================================
  // SERVICE NAME
  // =========================================================

  String _serviceName(String serviceId) {
    for (final service in controller.services) {
      if (service.id == serviceId) {
        return service.name;
      }
    }

    return 'خدمة ($serviceId)';
  }

  // =========================================================
  // FORMAT DATE
  // =========================================================

  String _formatDate(DateTime date) {
    final localDate = date.toLocal();

    final day = localDate.day.toString().padLeft(2, '0');
    final month = localDate.month.toString().padLeft(2, '0');

    return '$day/$month/${localDate.year}';
  }

  // =========================================================
  // STATUS HELPERS
  // =========================================================

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
        return Colors.grey;
    }
  }

  // =========================================================
  // SUMMARY
  // =========================================================

  Widget _buildSummary() {
    final totalAssignments = assignments.length;

    final activeAssignments = assignments.where(
          (item) =>
      item.status != AssistanceAssignmentModel.statusCanceled,
    ).length;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: 'إجمالي العمليات',
            value: totalAssignments.toString(),
            icon: Icons.assignment_outlined,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: _buildSummaryCard(
            title: 'عمليات غير ملغاة',
            value: activeAssignments.toString(),
            icon: Icons.volunteer_activism_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
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
          ),

          const SizedBox(height: 8),

          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(height: 4),

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
  // ASSIGNMENT CARD
  // =========================================================

  Widget _buildHistoryCard(
      AssistanceAssignmentModel assignment,
      ) {
    final statusColor = _statusColor(
      assignment.status,
    );

    return Container(
      padding: const EdgeInsets.all(16),
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
          // SERVICE NAME AND STATUS

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  _serviceName(assignment.serviceId),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _statusText(assignment.status),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ASSIGNMENT DATE

          _buildInfoRow(
            Icons.calendar_today_outlined,
            'تاريخ التخصيص',
            _formatDate(assignment.assignedAt),
          ),

          const SizedBox(height: 10),

          // EMPLOYEE

          _buildInfoRow(
            Icons.person_outline,
            'معرف الموظف',
            assignment.assignedBy,
          ),

          // COOLDOWN DATE

          if (assignment.nextEligibleAt != null) ...[
            const SizedBox(height: 10),

            _buildInfoRow(
              Icons.event_available_outlined,
              'نهاية فترة منع التكرار',
              _formatDate(
                assignment.nextEligibleAt!,
              ),
            ),
          ],

          // NOTES

          if (assignment.notes.trim().isNotEmpty) ...[
            const SizedBox(height: 12),

            const Divider(),

            const SizedBox(height: 8),

            const Text(
              'ملاحظات',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              assignment.notes,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(
      IconData icon,
      String label,
      String value,
      ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 17,
          color: AppColors.primary,
        ),

        const SizedBox(width: 8),

        Expanded(
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

              const SizedBox(height: 2),

              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================
  // EMPTY STATE
  // =========================================================

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 50,
        horizontal: 20,
      ),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 55,
            color: Colors.grey.shade400,
          ),

          const SizedBox(height: 14),

          const Text(
            'لا توجد مساعدات مسجلة لهذه الأسرة',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'يمكنك تخصيص مساعدة جديدة للأسرة '
                'من خلال الزر الموجود بالأسفل.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // OPEN ASSIGNMENT SCREEN
  // =========================================================

  Future<void> _openAssignAssistance() async {
    await Get.to(
          () => CreateAssistanceScreen(
        initialFamily: widget.family,
      ),
    );

    if (!mounted) return;

    await _loadHistory();
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.neutralBackground,

        appBar: CustomAppBar(
          title: 'سجل المساعدات',
          subtitle: widget.family.name,
          leading: Icons.arrow_back,
          onLeadingPressed: () => Get.back(),
          action: Icons.refresh,
          onActionPressed: _loadHistory,
        ),

        body: RefreshIndicator(
          onRefresh: _loadHistory,
          child: isLoading
              ? const Center(
            child: CircularProgressIndicator(),
          )
              : errorMessage != null
              ? ListView(
            physics:
            const AlwaysScrollableScrollPhysics(),
            children: [
              const SizedBox(height: 80),

              Center(
                child: Text(
                  errorMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Center(
                child: TextButton(
                  onPressed: _loadHistory,
                  child: const Text(
                    'إعادة المحاولة',
                  ),
                ),
              ),
            ],
          )
              : ListView(
            physics:
            const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              // FAMILY NAME

              Text(
                widget.family.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'عدد أفراد الأسرة: '
                    '${widget.family.membersCount}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),

              const SizedBox(height: 18),

              // SUMMARY

              _buildSummary(),

              const SizedBox(height: 24),

              // HISTORY TITLE

              Text(
                'جميع المساعدات '
                    '(${assignments.length} عملية)',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 14),

              // ASSIGNMENT LIST

              if (assignments.isEmpty)
                _buildEmptyState()
              else
                ...assignments.map(
                      (assignment) => Padding(
                    padding: const EdgeInsets.only(
                      bottom: 12,
                    ),
                    child: _buildHistoryCard(
                      assignment,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // =====================================================
        // CREATE ASSISTANCE BUTTON
        // =====================================================

        bottomNavigationBar: SafeArea(
          child: Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _openAssignAssistance,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(
                  Icons.add,
                ),
                label: const Text(
                  'تخصيص مساعدة جديدة',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
