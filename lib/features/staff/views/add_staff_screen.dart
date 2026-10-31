
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:sijil/core/theme/app_colors.dart';
import 'package:sijil/core/widgets/app_button.dart';
import 'package:sijil/core/widgets/app_status_card.dart';
import 'package:sijil/core/widgets/app_text_field.dart';
import 'package:sijil/core/widgets/custom_app_bar.dart';

import 'package:sijil/features/family_creation/widgets/confirm_checkbox_tile.dart';
import 'package:sijil/features/family_creation/widgets/review_section_card.dart';

import 'package:sijil/features/staff/controllers/add_staff_controller.dart';
import 'package:sijil/features/staff/utils/staff_validators.dart';
import 'package:sijil/features/staff/widgets/form_dropdown_field.dart';

import '../../auth/controllers/user_session_controller.dart';

class AddStaffScreen extends StatefulWidget {
  const AddStaffScreen({super.key});

  @override
  State<AddStaffScreen> createState() =>
      _AddStaffScreenState();
}

class _AddStaffScreenState extends State<AddStaffScreen> {
  late final AddStaffController controller;

  final UserSessionController session =
  Get.find<UserSessionController>();

  // ID -> Name
  Map<String, String> areaNames = {};

  @override
  void initState() {
    super.initState();

    controller = Get.put(AddStaffController());

    // Current invitation rules support
    // field workers only.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        controller.selectRole('عامل ميداني');
      }
    });
  }

  String get organizationId =>
      session.organizationId.value;

  // --------------------------------------
  // Areas from Firestore
  // --------------------------------------

  Widget _buildAreasDropdown() {
    if (organizationId.isEmpty) {
      return const AppStatusCard(
        title: 'تعذر تحديد المؤسسة',
        message: 'يرجى تسجيل الدخول مجددًا.',
        type: AppStatusType.error,
      );
    }

    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('organizations')
          .doc(organizationId)
          .collection('areas')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const AppStatusCard(
            title: 'خطأ في تحميل المناطق',
            message:
            'تعذر قراءة مناطق المؤسسة. تحقق من الصلاحيات.',
            type: AppStatusType.error,
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final areaDocs = snapshot.data!.docs;

        areaNames = {
          for (final doc in areaDocs)
            doc.id: (
                doc.data()['name'] is String &&
                    (doc.data()['name'] as String)
                        .trim()
                        .isNotEmpty
            )
                ? doc.data()['name'] as String
                : doc.id,
        };

        if (areaDocs.isEmpty) {
          return const AppStatusCard(
            title: 'لا توجد مناطق',
            message:
            'يجب إضافة منطقة للمؤسسة قبل إضافة موظف.',
            type: AppStatusType.info,
          );
        }

        return Obx(() {
          final selectedId = controller.areaId.value;

          final validValue =
          areaNames.containsKey(selectedId)
              ? selectedId
              : null;

          return FormDropdownField(
            label: 'المنطقة المكلف بها',
            hint: 'اختر المنطقة',
            isRequired: true,
            value: validValue,
            items: areaDocs.map((doc) {
              return DropdownMenuItem<String>(
                value: doc.id,
                child: Text(
                  areaNames[doc.id] ?? doc.id,
                ),
              );
            }).toList(),
            onChanged: controller.selectArea,
            validator: StaffValidators.area,
          );
        });
      },
    );
  }

  // --------------------------------------
  // Confirm and review
  // --------------------------------------

  void _reviewBeforeAdding() {
    if (!session.isSupervisor) {
      Get.snackbar(
        'لا توجد صلاحية',
        'إضافة الموظفين متاحة للمشرف فقط.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (organizationId.isEmpty) {
      Get.snackbar(
        'خطأ',
        'لم يتم تحديد المؤسسة.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (!areaNames.containsKey(
      controller.areaId.value,
    )) {
      Get.snackbar(
        'تنبيه',
        'يرجى اختيار منطقة موجودة في المؤسسة.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (controller.role.value != 'عامل ميداني') {
      Get.snackbar(
        'تنبيه',
        'إضافة الدعوات متاحة للموظفين الميدانيين فقط.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (controller.validateForReview()) {
      _showReviewSheet();
    }
  }

  // --------------------------------------
  // Screen
  // --------------------------------------

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () =>
            FocusManager.instance.primaryFocus
                ?.unfocus(),
        child: Scaffold(
          backgroundColor:
          AppColors.neutralBackground,

          appBar: CustomAppBar(
            title: 'إضافة موظف',
            subtitle:
            '${session.fullName.value} • ${session.organizationName.value}',
            leading: Icons.arrow_back,
            onLeadingPressed: () => Get.back(),
          ),

          body: SafeArea(
            child: SingleChildScrollView(
              keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior
                  .onDrag,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 24,
              ),

              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.stretch,
                children: [
                  const AppStatusCard(
                    title: 'إضافة موظف إلى مؤسستك',
                    message:
                    'سيتم إنشاء دعوة معلقة للموظف. لا يُنشأ حساب المستخدم إلا بعد قبول الدعوة والتحقق من البريد الإلكتروني.',
                    type: AppStatusType.info,
                  ),

                  const SizedBox(height: 24),

                  Form(
                    key: controller.formKey,
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                      children: [
                        // ----------------------
                        // Full name
                        // ----------------------

                        AppTextField(
                          label: 'الاسم الكامل',
                          hint: 'أدخل اسم الموظف',
                          controller:
                          controller.fullNameController,
                          isRequired: true,
                          onChanged:
                          controller.onNameChanged,
                          validator:
                          StaffValidators.fullName,
                        ),

                        const SizedBox(height: 16),

                        // ----------------------
                        // Email
                        // ----------------------

                        AppTextField(
                          label:
                          'البريد الإلكتروني',
                          hint: 'name@example.com',
                          controller:
                          controller.emailController,
                          keyboardType:
                          TextInputType.emailAddress,
                          isRequired: true,
                          helperText:
                          'سيستخدم الموظف هذا البريد لقبول الدعوة.',
                          validator:
                          StaffValidators.email,
                        ),

                        const SizedBox(height: 16),

                        // ----------------------
                        // Role
                        // ----------------------

                        Obx(
                              () => FormDropdownField(
                            label: 'الدور الوظيفي',
                            hint: 'اختر الدور',
                            isRequired: true,
                            value: controller.role.value,
                            items: const [
                              DropdownMenuItem<String>(
                                value: 'عامل ميداني',
                                child: Text('عامل ميداني'),
                              ),
                              DropdownMenuItem<String>(
                                value: 'مشرف',
                                child: Text('مشرف'),
                              ),
                            ],
                            onChanged: controller.selectRole,
                            validator: StaffValidators.role,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ----------------------
                        // Organization areas
                        // ----------------------

                        _buildAreasDropdown(),

                      ],
                    ),
                  ),

                  const SizedBox(height: 24),


                  // ----------------------
                  // Confirmation
                  // ----------------------

                  Obx(
                        () => ConfirmCheckboxTile(
                      label:
                      'راجعت بيانات الموظف والبريد الإلكتروني والمنطقة',
                      value:
                      controller.isConfirmed.value,
                      onChanged:
                      controller.setConfirmed,
                    ),
                  ),

                  const SizedBox(height: 16),

                  const AppStatusCard(
                    title: 'مراجعة قبل الحفظ',
                    message:
                    'بعد تأكيد البيانات سيتم تسجيل دعوة معلقة. تفعيل الحساب مرتبط بقبول الموظف للدعوة.',
                    type: AppStatusType.info,
                  ),

                  const SizedBox(height: 24),

                  // ----------------------
                  // Review button
                  // ----------------------

                  AppButton(
                    text:
                    'مراجعة البيانات وتأكيد الإضافة',
                    onPressed: _reviewBeforeAdding,
                  ),

                  const SizedBox(height: 16),

                  // ----------------------
                  // Cancel
                  // ----------------------

                  AppButton(
                    text: 'إلغاء والعودة',
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

  // --------------------------------------
  // Review bottom sheet
  // --------------------------------------

  void _showReviewSheet() {
    Get.bottomSheet(
      Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
              CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'مراجعة بيانات الموظف',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 16),

                ReviewSectionCard(
                  title: 'بيانات الدعوة',
                  children: [
                    ReviewRow(
                      label: 'الاسم الكامل',
                      value: controller
                          .fullName.value,
                    ),
                    ReviewRow(
                      label:
                      'البريد الإلكتروني',
                      value: controller.email,
                      valueDirection:
                      TextDirection.ltr,
                    ),
                    ReviewRow(
                      label: 'المؤسسة',
                      value: session
                          .organizationName.value,
                    ),
                    ReviewRow(
                      label: 'الدور الوظيفي',
                      value: 'عامل ميداني',
                    ),
                    ReviewRow(
                      label: 'المنطقة',
                      value: areaNames[
                      controller.areaId.value] ??
                          '-',
                    ),
                    const ReviewRow(
                      label: 'حالة الدعوة',
                      value: 'بانتظار القبول',
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                Obx(
                      () => AppButton(
                    text: 'تأكيد الإضافة',
                    icon: Icons.check,
                    isLoading:
                    controller.isLoading.value,
                    onPressed:
                    controller.isLoading.value
                        ? null
                        : controller.confirmAdd,
                  ),
                ),

                const SizedBox(height: 16),

                AppButton(
                  text: 'رجوع',
                  type: AppButtonType.secondary,
                  onPressed: () => Get.back(),
                ),
              ],
            ),
          ),
        ),
      ),
      backgroundColor:
      AppColors.neutralBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
    );
  }
}
