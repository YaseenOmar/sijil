import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sijil/core/theme/app_colors.dart';
import 'package:sijil/core/widgets/app_button.dart';
import 'package:sijil/core/widgets/app_status_card.dart';
import 'package:sijil/core/widgets/app_text_field.dart';
import 'package:sijil/features/family_creation/widgets/confirm_checkbox_tile.dart';
import 'package:sijil/features/referrals/constants/referral_demo_data.dart';
import 'package:sijil/features/referrals/constants/referral_options.dart';
import 'package:sijil/features/referrals/controllers/create_referral_controller.dart';
import 'package:sijil/features/referrals/utils/referral_validators.dart';
import 'package:sijil/features/referrals/widgets/referral_flow_scaffold.dart';
import 'package:sijil/features/referrals/widgets/share_scope_card.dart';
import 'package:sijil/features/staff/widgets/form_dropdown_field.dart';

// Create a referral and save it to be sent later
// Open it with: Get.to(() => CreateReferralScreen());
class CreateReferralScreen extends StatelessWidget {
  CreateReferralScreen({super.key});

  final CreateReferralController controller = Get.put(
    CreateReferralController(),
  );

  @override
  Widget build(BuildContext context) {
    return ReferralFlowScaffold(
      title: 'إنشاء إحالة',
      breadcrumb: ' تنسيق الخدمة',
      children: [
        Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Family (single select)
              Obx(
                () => FormDropdownField(
                  label: 'الأسرة',
                  hint: 'اختر الأسرة',
                  isRequired: true,
                  value: controller.familyName.value,
                  items: ReferralDemoData.families
                      .map(
                        (family) => DropdownMenuItem(
                          value: family.name,
                          child: Text(family.name),
                        ),
                      )
                      .toList(),
                  onChanged: controller.selectFamily,
                  validator: ReferralValidators.family,
                ),
              ),

              const SizedBox(height: 16),

              // Receiving organization (single select)
              Obx(
                () => FormDropdownField(
                  label: 'الجهة المستقبلة',
                  hint: 'اختر الجهة',
                  helperText: ReferralOptions.orgHelper,
                  isRequired: true,
                  value: controller.receivingOrg.value,
                  items: ReferralOptions.receivingOrgs
                      .map(
                        (org) => DropdownMenuItem(value: org, child: Text(org)),
                      )
                      .toList(),
                  onChanged: controller.selectReceivingOrg,
                  validator: ReferralValidators.receivingOrg,
                ),
              ),

              const SizedBox(height: 16),

              // Service type (single select)
              Obx(
                () => FormDropdownField(
                  label: 'نوع الخدمة',
                  hint: 'اختر نوع الخدمة',
                  isRequired: true,
                  value: controller.serviceType.value,
                  items: ReferralOptions.serviceTypes
                      .map(
                        (service) => DropdownMenuItem(
                          value: service,
                          child: Text(service),
                        ),
                      )
                      .toList(),
                  onChanged: controller.selectServiceType,
                  validator: ReferralValidators.serviceType,
                ),
              ),

              const SizedBox(height: 16),

              AppTextField(
                label: 'سبب الإحالة',
                hint: 'مثال: تحتاج الأسرة إلى تقييم تأهيلي لأحد أفرادها',
                helperText: 'اكتب ما يلزم لتقديم الخدمة فقط. تجنّب التفاصيل الطبية غير الضرورية.',
                controller: controller.reasonController,
                keyboardType: TextInputType.multiline,
                maxLines: 3,
                isRequired: true,
                validator: ReferralValidators.reason,
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        const ShareScopeCard(),

        const SizedBox(height: 16),

        Obx(
          () => ConfirmCheckboxTile(
            label: 'أوضحت للأسرة غرض الإحالة ونطاق المشاركة',
            value: controller.isConfirmed.value,
            onChanged: controller.setConfirmed,
          ),
        ),

        const SizedBox(height: 16),

        const AppStatusCard(
          title: 'دون اتصال · الإحالة لم تُرسل',
          message: 'تُحفظ في طابور الإرسال. بعد المزامنة ستظهر «أُرسلت»، ولا تظهر «استُلمت» إلا بتأكيد الجهة المستقبلة.',
          type: AppStatusType.offline,
        ),

        const SizedBox(height: 24),

        Obx(
          () => AppButton(
            text: 'حفظ للإرسال لاحقاً',
            icon: Icons.save_outlined,
            isLoading: controller.isSaving.value,
            onPressed: controller.saveForLater,
          ),
        ),

        const SizedBox(height: 16),

        const Text(
          'الحالة بعد الحفظ: بانتظار الإرسال · على الجهاز.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
