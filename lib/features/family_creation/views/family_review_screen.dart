import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sijil/core/widgets/app_button.dart';
import 'package:sijil/core/widgets/app_status_card.dart';
import 'package:sijil/features/family_creation/constants/family_options.dart';
import 'package:sijil/features/family_creation/controllers/family_creation_controller.dart';
import 'package:sijil/features/family_creation/utils/text_utils.dart';
import 'package:sijil/features/family_creation/widgets/confirm_checkbox_tile.dart';
import 'package:sijil/features/family_creation/widgets/family_flow_scaffold.dart';
import 'package:sijil/features/family_creation/widgets/review_section_card.dart';
import 'package:sijil/features/family_creation/widgets/step_progress_header.dart';

// Step 3/3: review the data, then save to Firebase
class FamilyReviewScreen extends StatelessWidget {
  FamilyReviewScreen({super.key});

  final FamilyCreationController controller =
      Get.find<FamilyCreationController>();

  @override
  Widget build(BuildContext context) {
    return FamilyFlowScaffold(
      title: 'مراجعة الأسرة',
      icon: Icons.fact_check_outlined,
      children: [
        const StepProgressHeader(
          currentStep: 3,
          sectionTitle: 'المراجعة والحفظ',
        ),

        const SizedBox(height: 24),

        // Basic data
        Obx(
          () => ReviewSectionCard(
            title: 'البيانات الأساسية',
            onEdit: _canEdit ? controller.editBasicInfo : null,
            children: [
              ReviewRow(label: 'رب الأسرة', value: controller.headName),
              ReviewRow(
                label: 'الهوية',
                value: maskNationalId(controller.nationalId),
                valueDirection: TextDirection.ltr,
              ),
              ReviewRow(
                label: 'الجوال',
                value: controller.phone,
                valueDirection: TextDirection.ltr,
              ),
              ReviewRow(
                label: 'عدد الأفراد',
                value: membersLabel(controller.membersCount),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Housing and needs
        Obx(
          () => ReviewSectionCard(
            title: 'السكن والاحتياجات',
            onEdit: _canEdit ? controller.editHousingInfo : null,
            children: [
              ReviewRow(
                label: 'المنطقة',
                value: FamilyOptions.areaName(controller.areaId),
              ),
              ReviewRow(label: 'العنوان', value: controller.address),
              ReviewRow(
                label: 'حالة السكن',
                value: controller.housingStatus.value ?? '-',
              ),
              ReviewRow(
                label: 'الاحتياجات',
                value: controller.orderedNeeds.join('، '),
              ),
              ReviewRow(
                label: 'صورة الهوية',
                value: controller.idCardImagePath.value == null
                    ? 'لم يتم إرفاقها'
                    : 'مرفقة · محفوظة محلياً',
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Confirmation / success / error states
        Obx(() {
          if (controller.isSaved.value) {
            return const AppStatusCard(
              title: 'تم حفظ الأسرة',
              message: 'تم حفظ بيانات الأسرة بنجاح وستظهر في قائمة الأسر.',
              type: AppStatusType.success,
            );
          }

          final String? error = controller.saveError.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (error != null) ...[
                AppStatusCard(
                  title: 'تعذر حفظ الأسرة',
                  message: error,
                  type: AppStatusType.error,
                ),
                const SizedBox(height: 16),
              ],

              ConfirmCheckboxTile(
                label: 'تحققت من البيانات مع الأسرة',
                value: controller.isConfirmed.value,
                onChanged: controller.setConfirmed,
              ),
            ],
          );
        }),

        const SizedBox(height: 24),

        // Actions
        Obx(() {
          if (controller.isSaved.value) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppButton(
                  text: 'العودة إلى الشاشة الرئيسية',
                  icon: Icons.home_outlined,
                  onPressed: controller.goHome,
                ),

                const SizedBox(height: 16),

                AppButton(
                  text: 'تسجيل أسرة أخرى',
                  type: AppButtonType.secondary,
                  onPressed: controller.startAnotherFamily,
                ),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppButton(
                text: controller.saveError.value == null
                    ? 'حفظ الأسرة'
                    : 'إعادة المحاولة',
                icon: Icons.check,
                isLoading: controller.isSaving.value,
                isEnabled: controller.isConfirmed.value,
                onPressed: controller.saveFamily,
              ),

              const SizedBox(height: 16),

              AppButton(
                text: 'السابق: السكن والاحتياجات',
                type: AppButtonType.secondary,
                isEnabled: !controller.isSaving.value,
                onPressed: () => Get.back(),
              ),
            ],
          );
        }),
      ],
    );
  }

  // Editing is not allowed while saving or after saving
  bool get _canEdit => !controller.isSaving.value && !controller.isSaved.value;
}
