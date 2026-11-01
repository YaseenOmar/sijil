
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:sijil/core/theme/app_colors.dart';
import 'package:sijil/core/widgets/app_button.dart';
import 'package:sijil/core/widgets/app_status_card.dart';
import 'package:sijil/core/widgets/app_text_field.dart';

import 'package:sijil/features/family_creation/widgets/confirm_checkbox_tile.dart';
import 'package:sijil/features/staff/widgets/form_dropdown_field.dart';

import '../controllers/create_referral_controller.dart';
import '../utils/referral_validators.dart';
import '../widgets/referral_flow_scaffold2.dart';
import '../widgets/share_scope_card.dart';

class CreateReferralScreen extends StatelessWidget {
  CreateReferralScreen({super.key});

  final CreateReferralController controller =
  Get.put(CreateReferralController());

  @override
  Widget build(BuildContext context) {

    return ReferralFlowScaffold2(
      title: 'إنشاء إحالة',
      breadcrumb: 'تنسيق الخدمة',
      children: [
        Obx(() {
          if (controller.isLoading.value) {
            return const AppStatusCard(
              title: 'جاري تحميل البيانات',
              message: 'جاري تجهيز الأسر والمؤسسات المتاحة',
              type: AppStatusType.loading,
            );
          }

          if (controller.loadError.value != null) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppStatusCard(
                  title: 'تعذر تحميل البيانات',
                  message: controller.loadError.value!,
                  type: AppStatusType.error,
                ),
                const SizedBox(height: 16),
                AppButton(
                  text: 'إعادة المحاولة',
                  type: AppButtonType.secondary,
                  onPressed: controller.loadInitialData,
                ),
              ],
            );
          }

          return _buildReferralForm();
        }),
      ],
    );
  }

  Widget _buildReferralForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ---------------- Family ----------------
              Obx(
                    () => FormDropdownField(
                  label: 'الأسرة',
                  hint: 'اختر الأسرة',
                  isRequired: true,
                  value: controller.selectedFamilyId.value,
                  items: controller.families.map((family) {
                    final String id = family['id'] as String;
                    final String name =
                    family['headName'] as String;

                    return DropdownMenuItem<String>(
                      value: id,
                      child: Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: controller.selectFamily,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى اختيار الأسرة';
                    }
                    return null;
                  },
                ),
              ),

              const SizedBox(height: 16),

              // ---------------- Organization ----------------
              Obx(
                    () => FormDropdownField(
                  label: 'الجهة المستقبلة',
                  hint: 'اختر الجهة',
                  helperText:
                  'اختر المؤسسة التي ستقدم الخدمة للأسرة',
                  isRequired: true,
                  value:
                  controller.selectedOrganizationId.value,
                  items: controller.organizations.map((org) {
                    final String id = org['id'] as String;
                    final String name = org['name'] as String;

                    return DropdownMenuItem<String>(
                      value: id,
                      child: Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: controller.selectReceivingOrg,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى اختيار الجهة المستقبلة';
                    }
                    return null;
                  },
                ),
              ),

              const SizedBox(height: 16),

              // ---------------- Service ----------------
              Obx(() {
                final bool hasOrganization =
                    controller.selectedOrganizationId.value !=
                        null;

                final bool loading =
                    controller.isLoadingServices.value;

                return Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.stretch,
                  children: [
                    FormDropdownField(
                      label: 'نوع الخدمة',
                      hint: !hasOrganization
                          ? 'اختر الجهة المستقبلة أولاً'
                          : loading
                          ? 'جاري تحميل الخدمات'
                          : 'اختر نوع الخدمة',
                      helperText: hasOrganization
                          ? 'الخدمات التي تقدمها الجهة وتقبل الإحالات'
                          : null,
                      isRequired: true,
                      value: controller.selectedServiceId.value,
                      items: controller.services.map((service) {
                        final String id =
                        service['id'] as String;
                        final String name =
                        service['name'] as String;

                        return DropdownMenuItem<String>(
                          value: id,
                          child: Text(
                            name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: hasOrganization && !loading
                          ? controller.selectServiceType
                          : null,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'يرجى اختيار نوع الخدمة';
                        }
                        return null;
                      },
                    ),

                    if (loading) ...[
                      const SizedBox(height: 8),
                      const LinearProgressIndicator(),
                    ],

                    if (controller.servicesError.value !=
                        null) ...[
                      const SizedBox(height: 12),
                      AppStatusCard(
                        title: 'تعذر تحميل الخدمات',
                        message:
                        controller.servicesError.value!,
                        type: AppStatusType.error,
                      ),
                      const SizedBox(height: 8),
                      AppButton(
                        text: 'إعادة تحميل الخدمات',
                        type: AppButtonType.secondary,
                        onPressed: () {
                          final orgId = controller
                              .selectedOrganizationId.value;
                          if (orgId != null) {
                            controller.loadServices(orgId);
                          }
                        },
                      ),
                    ] else if (hasOrganization &&
                        !loading &&
                        controller.services.isEmpty) ...[
                      const SizedBox(height: 12),
                      const AppStatusCard(
                        title: 'لا توجد خدمات متاحة',
                        message:
                        'هذه المؤسسة لا توفر حالياً خدمات متاحة للإحالة',
                        type: AppStatusType.info,
                      ),
                    ],
                  ],
                );
              }),

              const SizedBox(height: 16),

              // ---------------- Reason ----------------
              AppTextField(
                label: 'سبب الإحالة',
                hint:
                'مثال: تحتاج الأسرة إلى تقييم تأهيلي لأحد أفرادها',
                helperText:
                'اكتب المعلومات اللازمة لتقديم الخدمة فقط',
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

        // ---------------- Sharing information ----------------
        const ShareScopeCard(),

        const SizedBox(height: 16),

        Obx(
              () => ConfirmCheckboxTile(
            label: 'أوضحت للأسرة غرض الإحالة ونطاق المشاركة',
            value: controller.isConfirmed.value,
            onChanged: controller.setConfirmed,
          ),
        ),

        const SizedBox(height: 24),

        // ---------------- Submit ----------------
        Obx(() {
          final bool isSupervisor =
              controller.role == 'supervisor';

          return AppButton(
            text: isSupervisor
                ? 'إرسال الإحالة'
                : 'إرسال الطلب للمشرف',
            icon: Icons.send_outlined,
            isLoading: controller.isSaving.value,
            isEnabled: !controller.isSaving.value &&
                !controller.isLoadingServices.value,
            onPressed: controller.submitReferral,
          );
        }),

        const SizedBox(height: 16),

        Text(
          controller.role == 'supervisor'
              ? 'سيتم إرسال الإحالة إلى المؤسسة المستقبلة لمراجعتها.'
              : 'سيتم إرسال طلب الإحالة إلى مشرف مؤسستك للموافقة عليه قبل تحويله إلى الجهة المستقبلة.',
          style: const TextStyle(
            fontSize: 12,
            height: 1.6,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
