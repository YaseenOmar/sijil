import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sijil/core/theme/app_colors.dart';
import 'package:sijil/core/widgets/app_button.dart';
import 'package:sijil/core/widgets/app_status_card.dart';
import 'package:sijil/core/widgets/app_text_field.dart';
import 'package:sijil/core/widgets/custom_app_bar.dart';
import 'package:sijil/features/family_creation/widgets/confirm_checkbox_tile.dart';
import 'package:sijil/features/family_creation/widgets/review_section_card.dart';
import 'package:sijil/features/staff/constants/staff_options.dart';
import 'package:sijil/features/staff/controllers/add_staff_controller.dart';
import 'package:sijil/features/staff/utils/staff_validators.dart';
import 'package:sijil/features/staff/widgets/form_dropdown_field.dart';
import 'package:sijil/features/staff/widgets/permissions_preview_card.dart';

// Add a staff member (manager only)
// Open it with: Get.to(() => AddStaffScreen());
class AddStaffScreen extends StatelessWidget {
  AddStaffScreen({super.key});

  final AddStaffController controller = Get.put(AddStaffController());

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
          backgroundColor: AppColors.neutralBackground,
          appBar: CustomAppBar(
            title: 'إضافة موظف',
            subtitle: 'سجل',
            icon: Icons.arrow_back,
            onIconPressed: () => Get.back(),
            iconOnRight: true,
          ),

          // SingleChildScrollView prevents bottom overflow when keyboard opens
          body: SafeArea(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Signed in manager
                  const Text(
                    StaffOptions.currentManagerLabel,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 16),

                  const AppStatusCard(
                    title: 'إضافة حساب عمل لجهتك فقط',
                    message: 'تحقق من اسم الموظف وبريد العمل ونطاق الوصول. لا تُنشأ صلاحيات لحسابك من هذه الصفحة، وتُوثَّق التغييرات باسم المدير.',
                    type: AppStatusType.success,
                  ),

                  const SizedBox(height: 24),

                  Form(
                    key: controller.formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppTextField(
                          label: 'الاسم الكامل',
                          hint: 'مثال: هبة خالد',
                          controller: controller.fullNameController,
                          isRequired: true,
                          onChanged: controller.onNameChanged,
                          validator: StaffValidators.fullName,
                        ),

                        const SizedBox(height: 16),

                        AppTextField(
                          label: 'البريد الإلكتروني للعمل',
                          hint: 'name@alaman.org',
                          helperText:
                              'بريد توضيحي؛ تراجع صحته قبل إرسال الدعوة.',
                          controller: controller.emailController,
                          keyboardType: TextInputType.emailAddress,
                          isRequired: true,
                          validator: StaffValidators.email,
                        ),

                        const SizedBox(height: 16),

                        // Role (single select)
                        Obx(
                          () => FormDropdownField(
                            label: 'الدور الوظيفي',
                            hint: 'اختر الدور',
                            helperText: 'الأدوار الحالية: عامل ميداني، مشرف، مدير الجهة. لا يتاح دور إشراف الشبكة.',
                            isRequired: true,
                            value: controller.role.value,
                            items: StaffOptions.roleNames
                                .map(
                                  (role) => DropdownMenuItem(
                                    value: role,
                                    child: Text(role),
                                  ),
                                )
                                .toList(),
                            onChanged: controller.selectRole,
                            validator: StaffValidators.role,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Area (single select)
                        Obx(
                          () => FormDropdownField(
                            label: 'المنطقة المكلف بها',
                            hint: 'اختر المنطقة',
                            isRequired: true,
                            value: controller.areaId.value,
                            items: StaffOptions.areaIds
                                .map(
                                  (areaId) => DropdownMenuItem(
                                    value: areaId,
                                    child: Text(StaffOptions.areaName(areaId)),
                                  ),
                                )
                                .toList(),
                            onChanged: controller.selectArea,
                            validator: StaffValidators.area,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Requested account status (optional)
                        Obx(
                          () => FormDropdownField(
                            label: 'حالة الحساب المطلوبة',
                            value: controller.accountStatus.value,
                            items: StaffOptions.accountStatuses
                                .map(
                                  (status) => DropdownMenuItem(
                                    value: status,
                                    child: Text(status),
                                  ),
                                )
                                .toList(),
                            onChanged: controller.selectAccountStatus,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Updates while the user types or selects
                  Obx(
                    () => PermissionsPreviewCard(
                      name: controller.fullName.value,
                      areaName: controller.areaName,
                      role: controller.role.value,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Obx(
                    () => ConfirmCheckboxTile(
                      label: 'راجعت هوية الموظف والبريد والدور والمنطقة',
                      value: controller.isConfirmed.value,
                      onChanged: controller.setConfirmed,
                    ),
                  ),

                  const SizedBox(height: 16),

                  const AppStatusCard(
                    title: 'الحفظ يتطلب تأكيد الصلاحيات',
                    message: 'يظهر ملخص للصلاحيات قبل الإضافة. لا نعرض «دعوة مرسلة» إلا بعد تأكيد الشبكة؛ عند غياب التأكيد تبقى الدعوة معلّقة وغير مفعّلة.',
                    type: AppStatusType.offline,
                  ),

                  const SizedBox(height: 24),

                  AppButton(
                    text: 'مراجعة الصلاحيات وتأكيد الإضافة',
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

                  const SizedBox(height: 16),

                  const Text(
                    'تغيير الدور لاحقاً يحتاج تأكيد المدير وتسجيله في التدقيق؛ لا تصعيد ذاتي للصلاحيات.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Permissions summary before adding the employee
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
                  'مراجعة الصلاحيات',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 16),

                ReviewSectionCard(
                  title: 'بيانات الموظف',
                  children: [
                    ReviewRow(
                      label: 'الاسم الكامل',
                      value: controller.fullName.value,
                    ),
                    ReviewRow(
                      label: 'البريد الإلكتروني',
                      value: controller.email,
                      valueDirection: TextDirection.ltr,
                    ),
                    ReviewRow(
                      label: 'الدور الوظيفي',
                      value: controller.role.value ?? '-',
                    ),
                    ReviewRow(
                      label: 'المنطقة',
                      value: controller.areaName ?? '-',
                    ),
                    ReviewRow(
                      label: 'حالة الحساب',
                      value: controller.accountStatus.value ?? '-',
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                PermissionsPreviewCard(
                  name: controller.fullName.value,
                  areaName: controller.areaName,
                  role: controller.role.value,
                ),

                const SizedBox(height: 24),

                AppButton(
                  text: 'تأكيد الإضافة',
                  icon: Icons.check,
                  onPressed: controller.confirmAdd,
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
