import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sijil/core/theme/app_colors.dart';
import 'package:sijil/core/widgets/app_button.dart';
import 'package:sijil/core/widgets/app_status_card.dart';
import 'package:sijil/core/widgets/custom_app_bar.dart';
import 'package:sijil/features/data_conflicts/constants/data_conflict_demo_data.dart';
import 'package:sijil/features/data_conflicts/controllers/data_conflict_controller.dart';
import 'package:sijil/features/data_conflicts/models/data_conflict_model.dart';
import 'package:sijil/features/data_conflicts/widgets/conflict_details_card.dart';
import 'package:sijil/features/family_creation/widgets/review_section_card.dart';
import 'package:sijil/features/referrals/utils/referral_formatters.dart';

// Notice for the supervisor: two edits of the same field, the latest one was kept
// Open it with: Get.to(() => DataConflictScreen(conflict: conflict));
class DataConflictScreen extends StatelessWidget {
  final DataConflictModel conflict;

  DataConflictScreen({super.key, required this.conflict});

  late final DataConflictController controller = Get.put(
    DataConflictController(conflict),
  );

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.neutralBackground,

        // leading = back button on the right, subtitle = signed in supervisor
        appBar: CustomAppBar(
          title: 'تعارض في تحديث البيانات',
          subtitle: DataConflictDemoData.supervisorLabel,
          leading: Icons.arrow_back,
          onLeadingPressed: () => Get.back(),
        ),

        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppStatusCard(
                  title: 'احتُفظ بآخر تعديل تلقائياً',
                  message: 'لا يلزم دمج يدوي أو اختيار نسخة. أُضيفت النسختان إلى سجل التدقيق، وأُبلغ المشرف.',
                  type: AppStatusType.success,
                ),

                const SizedBox(height: 24),

                // What happened
                ConflictDetailsCard(
                  children: [
                    ReviewRow(
                      label: 'الأسرة · الجهة',
                      value:
                          '${conflict.familyName} · ${conflict.organization}',
                    ),
                    ReviewRow(
                      label: 'الحقل الذي تغيّر',
                      value: conflict.fieldLabel,
                    ),
                    ReviewRow(
                      label: 'اكتشاف التعارض',
                      value: formatDateTime(conflict.detectedAt),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                const Text(
                  'التعديل السابق',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 16),

                ConflictDetailsCard(
                  tag: 'محفوظ في سجل التدقيق',
                  children: [
                    ReviewRow(label: 'القيمة', value: conflict.previous.value),
                    ReviewRow(label: 'الموظف', value: conflict.previous.editor),
                    ReviewRow(
                      label: 'وقت التعديل',
                      value: formatDateTime(conflict.previous.editedAt),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                const Text(
                  'آخر تعديل · القيمة الحالية',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 16),

                ConflictDetailsCard(
                  tag: 'اعتُمد تلقائياً لأنه الأحدث',
                  isHighlighted: true,
                  children: [
                    ReviewRow(
                      label: 'القيمة الحالية',
                      value: conflict.current.value,
                    ),
                    ReviewRow(label: 'الموظف', value: conflict.current.editor),
                    ReviewRow(
                      label: 'وقت التعديل',
                      value: formatDateTime(conflict.current.editedAt),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                const Text(
                  'يُحفظ من غيّر البيانات وما الذي تغيّر ومتى. إن احتاجت القيمة الحالية إلى تصحيح، يُسجّل تعديل جديد بالصلاحية المناسبة، دون محو التاريخ.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 24),

                AppButton(
                  text: 'تم الاطلاع على الإشعار',
                  icon: Icons.check,
                  onPressed: controller.acknowledge,
                ),

                const SizedBox(height: 16),

                AppButton(
                  text: 'فتح سجل التغييرات',
                  type: AppButtonType.secondary,
                  onPressed: controller.openChangeLog,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
