import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sijil/core/theme/app_colors.dart';
import 'package:sijil/core/widgets/app_button.dart';
import 'package:sijil/core/widgets/app_status_card.dart';
import 'package:sijil/core/widgets/app_text_field.dart';
import 'package:sijil/core/widgets/custom_app_bar.dart';
import 'package:sijil/features/family_creation/utils/text_utils.dart';
import 'package:sijil/features/family_creation/widgets/review_section_card.dart';
import 'package:sijil/features/service_catalog/constants/service_options.dart';
import 'package:sijil/features/service_catalog/controllers/add_service_controller.dart';
import 'package:sijil/features/service_catalog/utils/service_validators.dart';
import 'package:sijil/features/service_catalog/widgets/service_review_card.dart';
import 'package:sijil/features/service_catalog/widgets/service_status_pill.dart';
import 'package:sijil/features/service_catalog/widgets/toggle_option_tile.dart';
import 'package:sijil/features/staff/widgets/form_dropdown_field.dart';

// Add a service to the organization (manager only)
// Open it with: Get.to(() => AddServiceScreen());
class AddServiceScreen extends StatelessWidget {
  AddServiceScreen({super.key});

  final AddServiceController controller = Get.put(AddServiceController());

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
          backgroundColor: AppColors.neutralBackground,

          // leading = back button on the right, subtitle = manager name
          appBar: CustomAppBar(
            title: 'إضافة خدمة',
            subtitle: ServiceOptions.managerLabel,
            leading: Icons.arrow_back,
            onLeadingPressed: () => Get.back(),
          ),

          // SingleChildScrollView prevents bottom overflow when keyboard opens
          body: SafeArea(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const ServiceStatusPill(
                    text: 'خدمة جديدة · إعدادات لم تُحفظ بعد',
                  ),

                  const SizedBox(height: 16),

                  Form(
                    key: controller.formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppTextField(
                          label: 'اسم الخدمة',
                          hint: 'مثال: دعم تعليمي',
                          controller: controller.nameController,
                          isRequired: true,
                          onChanged: controller.onNameChanged,
                          validator: ServiceValidators.name,
                        ),

                        const SizedBox(height: 16),

                        AppTextField(
                          label: 'وصف الخدمة',
                          hint: 'مثال: توفير حقيبة مستلزمات دراسية للأسرة بعد تقييم الاحتياج.',
                          controller: controller.descriptionController,
                          keyboardType: TextInputType.multiline,
                          maxLines: 3,
                          isRequired: true,
                          validator: ServiceValidators.description,
                        ),

                        const SizedBox(height: 16),

                        // Availability (single select)
                        Obx(
                          () => FormDropdownField(
                            label: 'حالة التوافر المطلوبة',
                            hint: 'اختر حالة التوافر',
                            isRequired: true,
                            value: controller.availability.value,
                            items: ServiceOptions.availabilities
                                .map(
                                  (item) => DropdownMenuItem(
                                    value: item,
                                    child: Text(item),
                                  ),
                                )
                                .toList(),
                            onChanged: controller.selectAvailability,
                            validator: ServiceValidators.availability,
                          ),
                        ),

                        const SizedBox(height: 16),

                        Obx(
                          () => ToggleOptionTile(
                            label: 'السماح باستقبال إحالات لهذه الخدمة',
                            value: controller.acceptsReferrals.value,
                            onChanged: controller.setAcceptsReferrals,
                          ),
                        ),

                        const SizedBox(height: 16),

                        const Text(
                          'التوافر إعداد للجهة، وليس وعداً بقبول كل إحالة. يصبح منشوراً فقط بعد تأكيد حفظه وتحديثه على الخادم.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            color: AppColors.textSecondary,
                          ),
                        ),

                        const SizedBox(height: 24),

                        const Text(
                          'منع التكرار عند التسليم',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),

                        const SizedBox(height: 16),

                        Obx(
                          () => ToggleOptionTile(
                            label: 'تطبيق فترة منع لهذه الخدمة',
                            value: controller.hasCooldown.value,
                            onChanged: controller.setHasCooldown,
                          ),
                        ),

                        // Cooldown fields appear only when the period is enabled
                        Obx(() {
                          if (!controller.hasCooldown.value) {
                            return const SizedBox.shrink();
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 16),

                              AppTextField(
                                label: 'فترة منع التكرار (بالأيام)',
                                hint: 'مثال: 180',
                                helperText: 'لن تُسجّل خدمة أخرى من النوع نفسه للأسرة خلال هذه الفترة.',
                                controller: controller.cooldownDaysController,
                                keyboardType: TextInputType.number,
                                isRequired: true,
                                onChanged: controller.onCooldownDaysChanged,
                                validator: ServiceValidators.cooldownDays,
                              ),

                              const SizedBox(height: 16),

                              AppTextField(
                                label: 'سبب الفترة',
                                hint: 'مثال: حقيبة واحدة لكل فصل دراسي لتجنّب ازدواج التسليم.',
                                controller: controller.cooldownReasonController,
                                keyboardType: TextInputType.multiline,
                                maxLines: 3,
                                isRequired: true,
                                validator: ServiceValidators.cooldownReason,
                              ),
                            ],
                          );
                        }),

                        const SizedBox(height: 16),

                        AppTextField(
                          label: 'الوحدة',
                          hint: 'مثال: حقيبة تعليمية',
                          controller: controller.unitController,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Updates while the user types or changes the switches
                  Obx(
                    () => ServiceReviewCard(
                      lines: [controller.availabilityLine, controller.rulesLine],
                      note: 'تُسجّل الإضافة باسم ${ServiceOptions.managerName} مع وقت الحفظ. يمكن تعديل التوافر لاحقاً بتأكيد أثر الإيقاف على الإحالات الجديدة.',
                    ),
                  ),

                  const SizedBox(height: 16),

                  const AppStatusCard(
                    title: 'لا نَنشر خدمة غير مؤكَّدة',
                    message: 'عند تعذّر الاتصال تبقى الإعدادات بانتظار التأكيد، ولا تُعرض الخدمة لجهات أخرى باعتبارها متاحة حديثاً.',
                    type: AppStatusType.offline,
                  ),

                  const SizedBox(height: 24),

                  AppButton(
                    text: 'مراجعة الخدمة وتأكيد الحفظ',
                    onPressed: () {
                      if (controller.validateForReview()) {
                        _showReviewSheet();
                      }
                    },
                  ),

                  const SizedBox(height: 16),

                  AppButton(
                    text: 'إلغاء والعودة إلى الفريق والخدمات',
                    type: AppButtonType.secondary,
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Final confirmation before saving the service
  void _showReviewSheet() {
    Get.bottomSheet(
      Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'تأكيد حفظ الخدمة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 16),

                ReviewSectionCard(
                  title: 'إعدادات الخدمة',
                  children: [
                    ReviewRow(
                      label: 'اسم الخدمة',
                      value: controller.nameController.text.trim(),
                    ),
                    ReviewRow(
                      label: 'وصف الخدمة',
                      value: controller.descriptionController.text.trim(),
                    ),
                    ReviewRow(
                      label: 'حالة التوافر',
                      value: controller.availability.value ?? '-',
                    ),
                    ReviewRow(
                      label: 'استقبال الإحالات',
                      value: controller.acceptsReferrals.value
                          ? 'مفعّل'
                          : 'غير مفعّل',
                    ),
                    ReviewRow(
                      label: 'منع التكرار',
                      value: controller.hasCooldown.value
                          ? '${toArabicDigits(controller.cooldownDaysValue)} يوماً'
                          : 'غير مفعّل',
                    ),
                    if (controller.hasCooldown.value)
                      ReviewRow(
                        label: 'سبب الفترة',
                        value: controller.cooldownReasonController.text.trim(),
                      ),
                    ReviewRow(
                      label: 'الوحدة',
                      value: controller.unitController.text.trim().isEmpty
                          ? '-'
                          : controller.unitController.text.trim(),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                AppButton(
                  text: 'تأكيد الحفظ',
                  icon: Icons.check,
                  onPressed: controller.confirmSave,
                ),

                const SizedBox(height: 16),

                AppButton(
                  text: 'رجوع للتعديل',
                  type: AppButtonType.secondary,
                  onPressed: () => Get.back(),
                ),
              ],
            ),
          ),
        ),
      ),
      backgroundColor: AppColors.neutralBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    );
  }
}
