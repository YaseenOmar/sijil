import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sijil/core/theme/app_colors.dart';
import 'package:sijil/core/widgets/app_button.dart';
import 'package:sijil/core/widgets/app_status_card.dart';
import 'package:sijil/core/widgets/app_text_field.dart';
import 'package:sijil/features/family_creation/constants/family_options.dart';
import 'package:sijil/features/family_creation/controllers/family_creation_controller.dart';
import 'package:sijil/features/family_creation/utils/family_validators.dart';
import 'package:sijil/features/family_creation/widgets/family_flow_scaffold.dart';
import 'package:sijil/features/family_creation/widgets/form_field_group.dart';
import 'package:sijil/features/family_creation/widgets/id_card_image_field.dart';
import 'package:sijil/features/family_creation/widgets/option_chip.dart';
import 'package:sijil/features/family_creation/widgets/step_progress_header.dart';

// Step 2/3: housing and needs
class FamilyHousingNeedsScreen extends StatelessWidget {
  FamilyHousingNeedsScreen({super.key});

  final FamilyCreationController controller =
      Get.find<FamilyCreationController>();

  @override
  Widget build(BuildContext context) {
    return FamilyFlowScaffold(
      title: 'أسرة جديدة',
      icon: Icons.family_restroom_outlined,
      children: [
        const StepProgressHeader(
          currentStep: 2,
          sectionTitle: 'السكن والاحتياجات',
        ),

        const SizedBox(height: 24),

        Form(
          key: controller.housingFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Area is assigned to the employee, so it is read only
              AppTextField(
                label: 'المنطقة المكلف بها',
                controller: controller.areaNameController,
                readOnly: true,
              ),

              const SizedBox(height: 16),

              AppTextField(
                label: 'العنوان التفصيلي',
                hint: 'مثال: شارع الزيتون، بناء 12، قرب المدرسة',
                controller: controller.addressController,
                keyboardType: TextInputType.streetAddress,
                maxLines: 3,
                isRequired: true,
                validator: FamilyValidators.address,
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Housing status (single select)
        Obx(
          () => FormFieldGroup(
            label: 'حالة السكن',
            isRequired: true,
            errorText: controller.housingError.value,
            child: OptionChipWrap(
              options: FamilyOptions.housingStatuses,
              selected: [
                if (controller.housingStatus.value != null)
                  controller.housingStatus.value!,
              ],
              onTap: controller.selectHousingStatus,
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Needs (multi select)
        Obx(
          () => FormFieldGroup(
            label: 'الاحتياجات',
            isRequired: true,
            helperText: 'يمكن اختيار أكثر من احتياج',
            errorText: controller.needsError.value,
            child: OptionChipWrap(
              options: FamilyOptions.needs,
              selected: controller.selectedNeeds.toList(),
              onTap: controller.toggleNeed,
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Optional ID card image
        Obx(
          () => FormFieldGroup(
            label: 'صورة بطاقة الهوية - اختياري',
            child: IdCardImageField(
              imagePath: controller.idCardImagePath.value,
              sizeKb: controller.idCardImageSizeKb.value,
              onPick: _showImageSourceSheet,
              onRemove: controller.removeIdCardImage,
            ),
          ),
        ),

        const SizedBox(height: 16),

        const AppStatusCard(
          title: 'قبل التصوير',
          message: 'اطلب موافقة الأسرة أولاً، وتأكد من وضوح الصورة وعدم تصوير أي بيانات غير لازمة.',
          type: AppStatusType.info,
        ),

        const SizedBox(height: 24),

        AppButton(
          text: 'التالي: مراجعة البيانات',
          icon: Icons.arrow_forward,
          onPressed: controller.submitHousingInfo,
        ),

        const SizedBox(height: 16),

        AppButton(
          text: 'السابق: البيانات الأساسية',
          type: AppButtonType.secondary,
          onPressed: () => Get.back(),
        ),
      ],
    );
  }

  // Choose camera or gallery
  void _showImageSourceSheet() {
    Get.bottomSheet(
      Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'إرفاق صورة الهوية',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 8),

                ListTile(
                  leading: const Icon(
                    Icons.photo_camera_outlined,
                    color: AppColors.primary,
                  ),
                  title: const Text('التقاط صورة بالكاميرا'),
                  onTap: () {
                    Get.back();
                    controller.pickIdCardImage(ImageSource.camera);
                  },
                ),

                ListTile(
                  leading: const Icon(
                    Icons.photo_library_outlined,
                    color: AppColors.primary,
                  ),
                  title: const Text('اختيار من المعرض'),
                  onTap: () {
                    Get.back();
                    controller.pickIdCardImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    );
  }
}
