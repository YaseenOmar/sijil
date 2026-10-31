
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:sijil/core/theme/app_colors.dart';
import 'package:sijil/core/widgets/app_button.dart';
import 'package:sijil/core/widgets/app_status_card.dart';
import 'package:sijil/core/widgets/app_text_field.dart';
import 'package:sijil/core/widgets/custom_app_bar.dart';

import 'package:sijil/features/auth/controllers/user_session_controller.dart';

import 'package:sijil/features/family_creation/utils/text_utils.dart';
import 'package:sijil/features/family_creation/widgets/review_section_card.dart';

import 'package:sijil/features/service_catalog/controllers/add_service_controller.dart';
import 'package:sijil/features/service_catalog/utils/service_validators.dart';
import 'package:sijil/features/service_catalog/widgets/service_review_card.dart';
import 'package:sijil/features/service_catalog/widgets/service_status_pill.dart';
import 'package:sijil/features/service_catalog/widgets/toggle_option_tile.dart';

import 'package:sijil/features/staff/widgets/form_dropdown_field.dart';

class AddServiceScreen extends StatefulWidget {
  const AddServiceScreen({super.key});

  @override
  State<AddServiceScreen> createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends State<AddServiceScreen> {
  late final AddServiceController controller;
  late final String _controllerTag;

  final UserSessionController session =
  Get.find<UserSessionController>();

  @override
  void initState() {
    super.initState();

    // إنشاء Controller مستقل لكل شاشة.
    _controllerTag = identityHashCode(this).toString();

    controller = Get.put(
      AddServiceController(),
      tag: _controllerTag,
    );
  }

  @override
  void dispose() {
    if (Get.isRegistered<AddServiceController>(
      tag: _controllerTag,
    )) {
      Get.delete<AddServiceController>(
        tag: _controllerTag,
      );
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Scaffold(
          backgroundColor: AppColors.neutralBackground,

          appBar: CustomAppBar(
            title: 'إضافة خدمة',
            subtitle:
            '${session.fullName.value} • ${session.organizationName.value}',
            leading: Icons.arrow_back,
            onLeadingPressed: () => Get.back(),
          ),

          body: SafeArea(
            child: SingleChildScrollView(
              keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 24,
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  // حالة الخدمة
                  const ServiceStatusPill(
                    text: 'خدمة جديدة · لم يتم الحفظ بعد',
                  ),

                  const SizedBox(height: 24),

                  // ==============================
                  // بيانات الخدمة
                  // ==============================

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
                          hint: 'مثال: توفير حقائب ومستلزمات دراسية للأسر المستفيدة',
                          controller: controller.descriptionController,
                          keyboardType: TextInputType.multiline,
                          maxLines: 3,
                          isRequired: true,
                          validator: ServiceValidators.description,
                        ),

                        const SizedBox(height: 16),

                        // التصنيف
                        Obx(
                              () => FormDropdownField(
                            key: ValueKey(controller.category.value),
                            label: 'تصنيف الخدمة',
                            hint: 'اختر تصنيف الخدمة',
                            isRequired: true,
                            value: controller.category.value,

                            items: AddServiceController.categories.entries
                                .map(
                                  (entry) => DropdownMenuItem<String>(
                                value: entry.key,
                                child: Text(
                                  entry.value,
                                  style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 15,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            )
                                .toList(),

                            onChanged: controller.selectCategory,

                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'يرجى اختيار تصنيف الخدمة';
                              }
                              return null;
                            },
                          ),
                        ),

                        const SizedBox(height: 16),

                        AppTextField(
                          label: 'وحدة الخدمة',
                          hint: 'مثال: طرد، حقيبة، جلسة',
                          helperText:
                          'اختياري: الوحدة المستخدمة عند تقديم الخدمة.',
                          controller: controller.unitController,
                        ),

                        const SizedBox(height: 24),

                        // ==============================
                        // إعدادات التوافر
                        // ==============================

                        const Text(
                          'إعدادات التوافر',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Obx(
                              () => ToggleOptionTile(
                            label: 'الخدمة متاحة حاليًا',
                            value: controller.isActive.value,
                            onChanged: controller.setIsActive,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Obx(
                              () => ToggleOptionTile(
                            label: 'السماح باستقبال إحالات لهذه الخدمة',
                            value: controller.acceptsReferrals.value,
                            onChanged: controller.setAcceptsReferrals,
                          ),
                        ),

                        const SizedBox(height: 12),

                        const Text(
                          'إيقاف الخدمة يمنع استخدامها في تخصيصات جديدة. '
                              'أما إيقاف الإحالات فيمنع استقبال إحالات جديدة '
                              'دون إيقاف الخدمة نفسها.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            color: AppColors.textSecondary,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ==============================
                        // منع تكرار المساعدة
                        // ==============================

                        const Text(
                          'منع تكرار المساعدة',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Obx(
                              () => ToggleOptionTile(
                            label: 'تطبيق فترة منع تكرار لهذه الخدمة',
                            value: controller.hasCooldown.value,
                            onChanged: controller.setHasCooldown,
                          ),
                        ),

                        Obx(() {
                          if (!controller.hasCooldown.value) {
                            return const Padding(
                              padding: EdgeInsets.only(top: 10),
                              child: Text(
                                'لا توجد فترة منع تكرار لهذه الخدمة.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            );
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 16),

                              AppTextField(
                                label: 'فترة منع التكرار (بالأيام)',
                                hint: 'مثال: 30',
                                helperText:
                                'تبدأ الفترة من تاريخ التسليم الفعلي، '
                                    'وليس من تاريخ تخصيص المساعدة.',
                                controller:
                                controller.cooldownDaysController,
                                keyboardType: TextInputType.number,
                                isRequired: true,
                                onChanged:
                                controller.onCooldownDaysChanged,
                                validator:
                                ServiceValidators.cooldownDays,
                              ),

                              const SizedBox(height: 16),

                              AppTextField(
                                label: 'سبب فترة منع التكرار',
                                hint:
                                'مثال: طرد غذائي واحد لكل أسرة خلال 30 يومًا',
                                controller:
                                controller.cooldownReasonController,
                                keyboardType: TextInputType.multiline,
                                maxLines: 3,
                                isRequired: true,
                                validator:
                                ServiceValidators.cooldownReason,
                              ),
                            ],
                          );
                        }),

                        const SizedBox(height: 14),

                        const AppStatusCard(
                          title: 'متى تبدأ فترة المنع؟',
                          message:
                          'لا يبدأ حساب فترة منع التكرار عند تخصيص المساعدة. '
                              'تبدأ فقط بعد تسجيل التسليم الفعلي للأسرة.',
                          type: AppStatusType.info,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ==============================
                  // معاينة الخدمة
                  // ==============================

                  Obx(
                        () => ServiceReviewCard(
                      lines: [
                        controller.isActive.value
                            ? 'الخدمة متاحة حاليًا'
                            : 'الخدمة غير متاحة حاليًا',

                        controller.acceptsReferrals.value
                            ? 'استقبال الإحالات مفعّل'
                            : 'استقبال الإحالات غير مفعّل',

                        controller.hasCooldown.value
                            ? 'منع التكرار لمدة ${toArabicDigits(controller.cooldownDaysValue)} يومًا'
                            : 'بدون فترة منع تكرار',
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ==============================
                  // مراجعة وحفظ
                  // ==============================

                  Obx(
                        () => AppButton(
                      text: 'مراجعة الخدمة وتأكيد الحفظ',
                      isLoading: controller.isLoading.value,
                      onPressed: controller.isLoading.value
                          ? null
                          : () {
                        if (controller.validateForReview()) {
                          _showReviewSheet();
                        }
                      },
                    ),
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

  // ==========================================
  // نافذة مراجعة البيانات قبل الحفظ
  // ==========================================

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
                  'مراجعة بيانات الخدمة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'تحقق من البيانات قبل حفظ الخدمة ضمن خدمات مؤسستك.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 16),

                ReviewSectionCard(
                  title: 'بيانات الخدمة',
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
                      label: 'التصنيف',
                      value: AddServiceController.categories[
                      controller.category.value] ??
                          '-',
                    ),

                    ReviewRow(
                      label: 'الوحدة',
                      value: controller.unitController.text.trim().isEmpty
                          ? 'غير محددة'
                          : controller.unitController.text.trim(),
                    ),

                    ReviewRow(
                      label: 'حالة الخدمة',
                      value: controller.isActive.value
                          ? 'متاحة'
                          : 'غير متاحة',
                    ),

                    ReviewRow(
                      label: 'استقبال الإحالات',
                      value: controller.acceptsReferrals.value
                          ? 'مفعّل'
                          : 'غير مفعّل',
                    ),

                    ReviewRow(
                      label: 'فترة منع التكرار',
                      value: controller.hasCooldown.value
                          ? '${toArabicDigits(controller.cooldownDaysValue)} يومًا'
                          : 'بدون فترة منع',
                    ),

                    if (controller.hasCooldown.value)
                      ReviewRow(
                        label: 'سبب فترة المنع',
                        value: controller.cooldownReasonController.text.trim(),
                      ),

                    if (controller.hasCooldown.value)
                      const ReviewRow(
                        label: 'بداية فترة المنع',
                        value: 'من تاريخ التسليم الفعلي',
                      ),
                  ],
                ),

                const SizedBox(height: 24),

                Obx(
                      () => AppButton(
                    text: 'تأكيد الحفظ',
                    icon: Icons.check,
                    isLoading: controller.isLoading.value,
                    onPressed: controller.isLoading.value
                        ? null
                        : controller.confirmSave,
                  ),
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
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
    );
  }
}
