import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sijil/core/widgets/app_button.dart';
import 'package:sijil/core/widgets/app_status_card.dart';
import 'package:sijil/core/widgets/app_text_field.dart';
import 'package:sijil/features/family_creation/controllers/family_creation_controller.dart';
import 'package:sijil/features/family_creation/utils/family_validators.dart';
import 'package:sijil/features/family_creation/widgets/family_flow_scaffold.dart';
import 'package:sijil/features/family_creation/widgets/step_progress_header.dart';

// Step 1/3: basic family data
// Open it with: Get.to(() => FamilyBasicInfoScreen());
class FamilyBasicInfoScreen extends StatelessWidget {
  FamilyBasicInfoScreen({super.key});

  final FamilyCreationController controller = Get.put(
    FamilyCreationController(),
  );

  @override
  Widget build(BuildContext context) {
    return FamilyFlowScaffold(
      title: 'أسرة جديدة',
      icon: Icons.arrow_back,
      children: [
        const StepProgressHeader(
          currentStep: 1,
          sectionTitle: 'البيانات الأساسية',
        ),

        const SizedBox(height: 24),

        Form(
          key: controller.basicFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: 'اسم رب الأسرة',
                hint: 'مثال: سامي يوسف الخطيب',
                controller: controller.headNameController,
                isRequired: true,
                validator: FamilyValidators.headName,
              ),

              const SizedBox(height: 16),

              AppTextField(
                label: 'رقم الهوية',
                hint: '9 أرقام',
                controller: controller.nationalIdController,
                keyboardType: TextInputType.number,
                isRequired: true,
                validator: FamilyValidators.nationalId,
              ),

              const SizedBox(height: 16),

              AppTextField(
                label: 'رقم الجوال',
                hint: '0599123456',
                controller: controller.phoneController,
                keyboardType: TextInputType.phone,
                isRequired: true,
                validator: FamilyValidators.phone,
              ),

              const SizedBox(height: 16),

              AppTextField(
                label: 'عدد أفراد الأسرة',
                hint: 'مثال: 5',
                controller: controller.membersCountController,
                keyboardType: TextInputType.number,
                isRequired: true,
                validator: FamilyValidators.membersCount,
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        const AppStatusCard(
          title: 'التحقق من الهوية',
          message: 'سيتم التحقق من رقم الهوية قبل المتابعة للتأكد من عدم تسجيل الأسرة مسبقاً. الاتصال بالإنترنت مطلوب.',
          type: AppStatusType.info,
        ),

        const SizedBox(height: 24),

        Obx(
          () => AppButton(
            text: 'التالي: السكن والاحتياجات',
            icon: Icons.arrow_forward,
            isLoading: controller.isCheckingId.value,
            onPressed: controller.submitBasicInfo,
          ),
        ),

        const SizedBox(height: 16),

        AppButton(
          text: 'إلغاء',
          type: AppButtonType.secondary,
          onPressed: () => Get.back(),
        ),
      ],
    );
  }
}
