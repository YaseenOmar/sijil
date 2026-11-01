
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_app_bar.dart';

import 'assign_assistance_screen.dart';
import 'assistance_history_screen.dart';

class AssistanceDuplicateWarningScreen
    extends StatelessWidget {
  // Family information
  final FamilyInfo family;

  // Service information
  final String serviceName;

  // Previous assignment information
  final DateTime? lastAssignedAt;
  final DateTime nextEligibleAt;
  final String? lastAssignmentId;

  // Server-provided message
  final String? message;

  const AssistanceDuplicateWarningScreen({
    super.key,
    required this.family,
    required this.serviceName,
    required this.nextEligibleAt,
    this.lastAssignedAt,
    this.lastAssignmentId,
    this.message,
  });

  // =========================================================
  // DATE FORMATTING
  // =========================================================

  String _formatDate(DateTime date) {
    final localDate = date.toLocal();

    final day = localDate.day.toString().padLeft(2, '0');
    final month = localDate.month.toString().padLeft(2, '0');

    return '$day/$month/${localDate.year}';
  }

  // =========================================================
  // REMAINING COOLDOWN
  // =========================================================

  String _remainingCooldown() {
    final now = DateTime.now().toUtc();

    final remaining = nextEligibleAt
        .toUtc()
        .difference(now);

    if (remaining <= Duration.zero) {
      return 'وصل موعد انتهاء فترة المنع. '
          'يجب إعادة التحقق من الأهلية عبر الخادم.';
    }

    final days = remaining.inDays;
    final hours = remaining.inHours % 24;

    if (days > 0) {
      return 'المدة المتبقية تقريبًا: '
          '$days يوم و$hours ساعة';
    }

    final totalHours = remaining.inHours;

    if (totalHours > 0) {
      return 'المدة المتبقية تقريبًا: '
          '$totalHours ساعة';
    }

    return 'تبقى أقل من ساعة على انتهاء فترة المنع';
  }

  // =========================================================
  // OPEN FAMILY HISTORY
  // =========================================================

  Future<void> _openFamilyHistory() async {
    await Get.to(
          () => AssistanceHistoryScreen(
        family: family,
      ),
    );
  }

  // =========================================================
  // INFORMATION ROW
  // =========================================================

  Widget _buildInfoRow({
    required String label,
    required String value,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 18,
              color: AppColors.primary,
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
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
          title: 'التحقق من المساعدة',
          subtitle: 'منع تكرار التخصيص',
          leading: Icons.arrow_back,
          onLeadingPressed: () => Get.back(),
        ),

        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.stretch,
              children: [
                // -----------------------------------
                // WARNING CARD
                // -----------------------------------

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                    BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.grey.shade200,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Warning icon

                      Container(
                        padding:
                        const EdgeInsets.all(16),
                        decoration:
                        const BoxDecoration(
                          color: Color(0xFFFFF3CD),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFF996500),
                          size: 36,
                        ),
                      ),

                      const SizedBox(height: 16),

                      const Text(
                        'لا يمكن تخصيص المساعدة حاليًا',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        message?.trim().isNotEmpty == true
                            ? message!
                            : 'سبق تخصيص نفس الخدمة لهذه '
                            'الأسرة، وما زالت ضمن فترة '
                            'منع التكرار المحددة.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          height: 1.6,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // -----------------------------------
                      // ASSIGNMENT DETAILS
                      // -----------------------------------

                      Container(
                        width: double.infinity,
                        padding:
                        const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:
                          const Color(0xFFF7F9F8),
                          borderRadius:
                          BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow(
                              label: 'الأسرة',
                              value: family.name,
                              icon:
                              Icons.family_restroom,
                            ),

                            _buildInfoRow(
                              label: 'الخدمة',
                              value: serviceName,
                              icon:
                              Icons.volunteer_activism_outlined,
                            ),

                            if (lastAssignedAt != null)
                              _buildInfoRow(
                                label:
                                'تاريخ التخصيص السابق',
                                value: _formatDate(
                                  lastAssignedAt!,
                                ),
                                icon:
                                Icons.history_outlined,
                              ),

                            _buildInfoRow(
                              label:
                              'انتهاء فترة منع التكرار',
                              value: _formatDate(
                                nextEligibleAt,
                              ),
                              icon:
                              Icons.event_available_outlined,
                            ),

                            if (lastAssignmentId != null &&
                                lastAssignmentId!
                                    .isNotEmpty)
                              _buildInfoRow(
                                label:
                                'معرف التخصيص السابق',
                                value: lastAssignmentId!,
                                icon:
                                Icons.receipt_long_outlined,
                              ),

                            const Divider(),

                            const SizedBox(height: 10),

                            Row(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  color:
                                  AppColors.primary,
                                  size: 19,
                                ),

                                const SizedBox(width: 8),

                                Expanded(
                                  child: Text(
                                    _remainingCooldown(),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight:
                                      FontWeight.w600,
                                      color:
                                      AppColors.primary,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // -----------------------------------
                // VIEW FAMILY HISTORY
                // -----------------------------------

                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _openFamilyHistory,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      AppColors.primary,
                      foregroundColor: Colors.white,
                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(
                      Icons.history,
                    ),
                    label: const Text(
                      'عرض سجل مساعدات الأسرة',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // -----------------------------------
                // RETURN BUTTON
                // -----------------------------------

                SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () => Get.back(),
                    style:
                    OutlinedButton.styleFrom(
                      foregroundColor:
                      AppColors.primary,
                      side: BorderSide(
                        color: Colors.grey.shade300,
                      ),
                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(
                      Icons.arrow_back,
                    ),
                    label: const Text(
                      'العودة لتعديل الاختيار',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // -----------------------------------
                // INFORMATION MESSAGE
                // -----------------------------------

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                    BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.shade200,
                    ),
                  ),
                  child: const Row(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.primary,
                        size: 20,
                      ),

                      SizedBox(width: 10),

                      Expanded(
                        child: Text(
                          'لم يتم إنشاء تخصيص جديد '
                              'لهذه الأسرة في الطلب المرفوض.\n'
                              'تبدأ فترة منع التكرار من تاريخ '
                              'التخصيص السابق، وليس من '
                              'تاريخ التسليم.\n'
                              'يجب إعادة التحقق من الأهلية '
                              'عند محاولة التخصيص مجددًا.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
