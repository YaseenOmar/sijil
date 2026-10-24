import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sijil/core/widgets/app_button.dart';
import 'package:sijil/core/widgets/app_status_card.dart';
import 'package:sijil/features/family_creation/constants/family_options.dart';
import 'package:sijil/features/family_creation/controllers/family_creation_controller.dart';
import 'package:sijil/features/family_creation/utils/text_utils.dart';
import 'package:sijil/features/family_creation/widgets/family_flow_scaffold.dart';
import 'package:sijil/features/family_creation/widgets/review_section_card.dart';
import 'package:sijil/features/family_creation/widgets/step_progress_header.dart';

// Shown after step 1 when the national ID is already registered
class DuplicateFamilyScreen extends StatelessWidget {
  const DuplicateFamilyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FamilyCreationController>();
    final family = controller.existingFamily.value;

    return FamilyFlowScaffold(
      title: 'التحقق من الهوية',
      icon: Icons.badge_outlined,
      children: [
        const StepProgressHeader(
          currentStep: 1,
          sectionTitle: 'التحقق من الهوية',
        ),

        const SizedBox(height: 24),

        const AppStatusCard(
          title: 'هذه الأسرة مسجلة بالفعل',
          message: 'لا يمكن إنشاء سجل جديد بنفس رقم الهوية. صحح رقم الهوية إذا كان مدخلاً بالخطأ.',
          type: AppStatusType.error,
        ),

        const SizedBox(height: 16),

        if (family != null)
          ReviewSectionCard(
            title: 'السجل الموجود',
            children: [
              ReviewRow(label: 'رب الأسرة', value: family.headName),
              ReviewRow(
                label: 'الهوية',
                value: maskNationalId(family.nationalId),
                valueDirection: TextDirection.ltr,
              ),
              ReviewRow(
                label: 'المنطقة',
                value: FamilyOptions.areaName(family.areaId),
              ),
              ReviewRow(
                label: 'عدد الأفراد',
                value: membersLabel(family.membersCount),
              ),
            ],
          ),

        const SizedBox(height: 24),

        AppButton(
          text: 'العودة لتصحيح رقم الهوية',
          icon: Icons.arrow_forward,
          onPressed: () => Get.back(),
        ),

        const SizedBox(height: 16),

        AppButton(
          text: 'إلغاء والعودة للرئيسية',
          type: AppButtonType.secondary,
          onPressed: controller.goHome,
        ),
      ],
    );
  }
}
