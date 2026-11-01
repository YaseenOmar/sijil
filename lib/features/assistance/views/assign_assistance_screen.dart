
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../controllers/assistance_controller.dart';

// =========================================================
// FAMILY INFO
// =========================================================

class FamilyInfo {
  final String id;
  final String name;
  final int membersCount;
  final String area;
  final String nationalId;

  const FamilyInfo({
    required this.id,
    required this.name,
    required this.membersCount,
    required this.area,
    required this.nationalId,
  });
}

// =========================================================
// CREATE ASSISTANCE SCREEN
// =========================================================

class CreateAssistanceScreen extends StatefulWidget {
  final FamilyInfo? initialFamily;

  const CreateAssistanceScreen({
    super.key,
    this.initialFamily,
  });

  @override
  State<CreateAssistanceScreen> createState() =>
      _CreateAssistanceScreenState();
}

class _CreateAssistanceScreenState
    extends State<CreateAssistanceScreen> {
  final AssistanceController controller =
  Get.find<AssistanceController>();

  final TextEditingController notesController =
  TextEditingController();

  final TextEditingController searchController =
  TextEditingController();

  final List<FamilyInfo> availableFamilies = [];

  bool loadingFamilies = true;

  String? familyError;

  String searchText = '';

  @override
  void initState() {
    super.initState();

    controller.clearSelection();

    if (controller.services.isEmpty) {
      controller.loadServices();
    }

    _loadFamilies();
  }

  // =========================================================
  // LOAD AUTHORIZED FAMILIES
  // =========================================================

  Future<void> _loadFamilies() async {
    if (!mounted) return;

    setState(() {
      loadingFamilies = true;
      familyError = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw StateError('يجب تسجيل الدخول أولاً');
      }

      final firestore = FirebaseFirestore.instance;

      final profile = await firestore
          .collection('users')
          .doc(user.uid)
          .get(const GetOptions(source: Source.server));

      final userData = profile.data();

      if (userData == null) {
        throw StateError('بيانات المستخدم غير موجودة');
      }

      if (userData['status'] != 'active') {
        throw StateError('حساب المستخدم غير فعال');
      }

      if (userData['organizationId'] !=
          controller.organizationId) {
        throw StateError(
          'المؤسسة غير مطابقة لحساب المستخدم',
        );
      }

      final role = userData['role'] as String? ?? '';

      if (role != 'field_worker' &&
          role != 'supervisor') {
        throw StateError(
          'ليس لديك صلاحية عرض الأسر',
        );
      }

      Query<Map<String, dynamic>> query = firestore
          .collection('organizations')
          .doc(controller.organizationId)
          .collection('families');

      // Field workers only see families in their area.
      if (role == 'field_worker') {
        final areaId = userData['areaId'] as String?;

        if (areaId == null || areaId.isEmpty) {
          throw StateError(
            'منطقة الموظف غير محددة',
          );
        }

        query = query.where(
          'areaId',
          isEqualTo: areaId,
        );
      }

      final snapshot = await query.get(
        const GetOptions(source: Source.server),
      );

      final families = snapshot.docs.map((doc) {
        final data = doc.data();

        return FamilyInfo(
          id: doc.id,
          name: data['headName'] as String? ??
              'أسرة بدون اسم',
          membersCount:
          (data['membersCount'] as num?)?.toInt() ?? 0,
          area: data['areaId'] as String? ?? '',
          nationalId:
          data['nationalId'] as String? ?? '',
        );
      }).toList();

      families.sort(
            (a, b) => a.name.compareTo(b.name),
      );

      if (!mounted) return;

      setState(() {
        availableFamilies
          ..clear()
          ..addAll(families);

        loadingFamilies = false;
      });

      // Only preselect a family if it was returned
      // by the authorized Firestore query.
      final initialFamily = widget.initialFamily;

      if (initialFamily != null) {
        final isAvailable = families.any(
              (family) => family.id == initialFamily.id,
        );

        if (isAvailable) {
          controller.selectFamilies([
            initialFamily.id,
          ]);
        } else {
          Get.snackbar(
            'تنبيه',
            'الأسرة المحددة غير متاحة ضمن صلاحيات حسابك',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        familyError = _readError(e);
        loadingFamilies = false;
      });
    }
  }

  String _readError(Object error) {
    if (error is StateError) {
      return error.message.toString();
    }

    if (error is FirebaseException) {
      return error.message ??
          'تعذر تحميل البيانات من الخادم';
    }

    return 'حدث خطأ أثناء تحميل الأسر';
  }

  // =========================================================
  // FAMILY SELECTION
  // =========================================================

  void _openFamilySelectionSheet() {
    if (loadingFamilies || availableFamilies.isEmpty) {
      return;
    }

    searchController.clear();
    searchText = '';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: FractionallySizedBox(
            heightFactor: 0.85,
            child: StatefulBuilder(
              builder: (context, setSheetState) {
                final filtered = availableFamilies.where(
                      (family) {
                    return family.name
                        .contains(searchText) ||
                        family.nationalId
                            .contains(searchText);
                  },
                ).toList();

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'اختيار الأسر المستفيدة',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Obx(() {
                        return Text(
                          'تم اختيار '
                              '${controller.selectedFamilyIds.length}'
                              ' من '
                              '${AssistanceController.maxFamiliesPerRequest}'
                              ' أسرة',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        );
                      }),

                      const SizedBox(height: 14),

                      TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText:
                          'ابحث باسم رب الأسرة أو رقم الهوية',
                          prefixIcon:
                          const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius:
                            BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (value) {
                          setSheetState(() {
                            searchText = value.trim();
                          });
                        },
                      ),

                      const SizedBox(height: 12),


                      Expanded(
                        child: ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final family = filtered[index];

                            return Obx(() {
                              final checked = controller
                                  .selectedFamilyIds
                                  .contains(family.id);

                              return CheckboxListTile(
                                value: checked,
                                activeColor: AppColors.primary,
                                controlAffinity:
                                ListTileControlAffinity.leading,
                                title: Text(family.name),
                                subtitle: Text(
                                  '${family.membersCount} أفراد'
                                      ' · ${family.nationalId}',
                                ),
                                onChanged: controller.isAssigning.value
                                    ? null
                                    : (value) {
                                  controller.toggleFamily(family.id);

                                  final error =
                                      controller.errorMessage.value;

                                  if (error.isNotEmpty) {
                                    Get.snackbar(
                                      'تنبيه',
                                      error,
                                      snackPosition:
                                      SnackPosition.BOTTOM,
                                    );
                                  }
                                },
                              );
                            });
                          },
                        ),
                      ),


                      const SizedBox(height: 12),

                      Obx(() {
                        return ElevatedButton(
                          onPressed:
                          controller.isAssigning.value
                              ? null
                              : () {
                            Navigator.pop(
                              sheetContext,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                            AppColors.primary,
                            foregroundColor: Colors.white,
                            minimumSize:
                            const Size.fromHeight(48),
                          ),
                          child: Text(
                            'تأكيد الاختيار '
                                '(${controller.selectedFamilyIds.length})',
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  // =========================================================
  // SUBMIT ASSIGNMENT
  // =========================================================

  Future<void> _submit() async {
    if (controller.isAssigning.value) return;

    final service = controller.selectedService.value;

    if (service == null) {
      _showMessage('يرجى اختيار الخدمة أولاً');
      return;
    }

    if (!service.isActive) {
      _showMessage('الخدمة المحددة غير متاحة');
      return;
    }

    if (controller.selectedFamilyIds.isEmpty) {
      _showMessage('يرجى اختيار أسرة واحدة على الأقل');
      return;
    }

    final availableIds = availableFamilies
        .map((family) => family.id)
        .toSet();

    final allAuthorized = controller.selectedFamilyIds
        .every(availableIds.contains);

    if (!allAuthorized) {
      _showMessage(
        'توجد أسرة محددة غير متاحة ضمن صلاحيات حسابك',
      );
      return;
    }

    await controller.assignSelectedAssistance(
      notes: notesController.text.trim(),
    );

    if (!mounted) return;

    final error = controller.errorMessage.value;

    if (error.isNotEmpty) {
      Get.snackbar(
        'تعذر تخصيص المساعدة',
        error,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
      return;
    }

    if (!controller.hasAssignmentResults) {
      _showMessage(
        'لم يتم استلام نتائج التخصيص من الخادم',
      );
      return;
    }

    await _showAssignmentResults();

    if (!mounted) return;

    final successes = controller.successfulAssignments;
    final failures = controller.failedAssignments;

    if (successes > 0 && failures == 0) {
      Get.back();
      return;
    }

    // Keep failed families selected for a new attempt.
    controller.keepFailedFamiliesSelected();
  }

  void _showMessage(String message) {
    Get.snackbar(
      'تنبيه',
      message,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  // =========================================================
  // ASSIGNMENT RESULT DIALOG
  // =========================================================

  Future<void> _showAssignmentResults() async {
    final results = controller.assignmentResults
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    final successes = controller.successfulAssignments;
    final failures = controller.failedAssignments;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text(
              'نتيجة تخصيص المساعدة',
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    'نجح: $successes'
                        ' · لم ينجح: $failures',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final result = results[index];

                        final familyId =
                        result['familyId'] as String;

                        final success =
                            result['success'] == true;

                        final matches = availableFamilies
                            .where(
                              (family) =>
                          family.id == familyId,
                        )
                            .toList();

                        final familyName =
                        matches.isNotEmpty
                            ? matches.first.name
                            : familyId;

                        final message =
                            result['message']?.toString() ??
                                (success
                                    ? 'تم التخصيص'
                                    : 'تعذر التخصيص');

                        return ListTile(
                          contentPadding:
                          EdgeInsets.zero,
                          leading: Icon(
                            success
                                ? Icons.check_circle
                                : Icons.error_outline,
                            color: success
                                ? AppColors.primary
                                : Colors.red,
                          ),
                          title: Text(familyName),
                          subtitle: Text(message),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text('إغلاق'),
              ),
            ],
          ),
        );
      },
    );
  }

  // =========================================================
  // SELECTED FAMILIES WIDGET
  // =========================================================

  Widget _buildSelectedFamilies() {
    return Obx(() {
      final selected = availableFamilies.where(
            (family) => controller.selectedFamilyIds
            .contains(family.id),
      ).toList();

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFEBF7F4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: selected.isEmpty
            ? const Text(
          'لم يتم اختيار أي أسرة',
        )
            : Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Text(
              '${selected.length} أسرة محددة',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 8),

            ...selected.map(
                  (family) => Padding(
                padding:
                const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 16,
                      color: AppColors.primary,
                    ),

                    const SizedBox(width: 6),

                    Expanded(
                      child: Text(
                        family.name,
                        style: const TextStyle(
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  // =========================================================
  // SERVICE SELECTION WIDGET
  // =========================================================

  Widget _buildServiceSelection() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }

      final services = controller.services.toList();

      if (services.isEmpty) {
        return Column(
          children: [
            const Text(
              'لا توجد خدمات فعالة متاحة حاليًا',
            ),

            TextButton(
              onPressed: controller.loadServices,
              child: const Text('إعادة التحميل'),
            ),
          ],
        );
      }

      final selected = controller.selectedService.value;

      return DropdownButtonFormField<String>(
        key: ValueKey(selected?.id ?? 'none'),
        initialValue: services.any(
              (item) => item.id == selected?.id,
        )
            ? selected!.id
            : null,
        isExpanded: true,
        hint: const Text('اختر الخدمة'),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        items: services.map((service) {
          final cooldownDescription =
          service.hasCooldown
              ? 'كل ${service.cooldownDays} يوم'
              : 'بدون فترة منع';

          return DropdownMenuItem<String>(
            value: service.id,
            child: Text(
              '${service.name} - $cooldownDescription',
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: controller.isAssigning.value
            ? null
            : (serviceId) {
          if (serviceId == null) return;

          final service = services.firstWhere(
                (item) => item.id == serviceId,
          );

          controller.selectService(service);
        },
      );
    });
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    notesController.dispose();
    searchController.dispose();
    super.dispose();
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor:
        AppColors.neutralBackground,
        appBar: CustomAppBar(
          title: 'تخصيص مساعدة',
          leading: Icons.arrow_back,
          onLeadingPressed: () {
            if (!controller.isAssigning.value) {
              Get.back();
            }
          },
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.stretch,
              children: [
                // -----------------------------------
                // FAMILIES
                // -----------------------------------

                const Text(
                  'الأسر المستفيدة *',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 10),

                if (loadingFamilies)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (familyError != null)
                  Column(
                    children: [
                      Text(
                        familyError!,
                        style: const TextStyle(
                          color: Colors.red,
                        ),
                      ),

                      TextButton(
                        onPressed: _loadFamilies,
                        child: const Text(
                          'إعادة المحاولة',
                        ),
                      ),
                    ],
                  )
                else ...[
                    _buildSelectedFamilies(),

                    const SizedBox(height: 10),

                    Obx(() {
                      return OutlinedButton.icon(
                        onPressed:
                        controller.isAssigning.value ||
                            availableFamilies.isEmpty
                            ? null
                            : _openFamilySelectionSheet,
                        icon: const Icon(
                          Icons.groups_outlined,
                        ),
                        label: const Text(
                          'اختيار أسرة أو عدة أسر',
                        ),
                      );
                    }),
                  ],

                const SizedBox(height: 24),

                // -----------------------------------
                // SERVICE
                // -----------------------------------

                const Text(
                  'نوع المساعدة *',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 10),

                _buildServiceSelection(),

                const SizedBox(height: 20),

                // -----------------------------------
                // NOTES
                // -----------------------------------

                Obx(() {
                  return TextField(
                    controller: notesController,
                    enabled:
                    !controller.isAssigning.value,
                    minLines: 2,
                    maxLines: 4,
                    maxLength: 500,
                    decoration: InputDecoration(
                      labelText:
                      'ملاحظات (اختياري)',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius:
                        BorderRadius.circular(12),
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 12),

                // -----------------------------------
                // INFORMATION CARD
                // -----------------------------------

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                    BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.shade300,
                    ),
                  ),
                  child: const Row(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.primary,
                      ),

                      SizedBox(width: 10),

                      Expanded(
                        child: Text(
                          'تبدأ فترة منع تكرار المساعدة '
                              'من تاريخ التخصيص، حسب إعدادات '
                              'الخدمة التي حددها المشرف.\n\n'
                              'عملية التخصيص لا تعني أن '
                              'المساعدة تم تسليمها فعليًا.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // -----------------------------------
                // SUBMIT BUTTON
                // -----------------------------------

                Obx(() {
                  final assigning =
                      controller.isAssigning.value;

                  final canSubmit =
                      !assigning &&
                          !loadingFamilies &&
                          familyError == null &&
                          controller.selectedService.value !=
                              null &&
                          controller.selectedFamilyIds
                              .isNotEmpty;

                  return ElevatedButton.icon(
                    onPressed:
                    canSubmit ? _submit : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                      Colors.grey.shade300,
                      minimumSize:
                      const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(12),
                      ),
                    ),
                    icon: assigning
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child:
                      CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Icon(
                      Icons.assignment_turned_in_outlined,
                    ),
                    label: Text(
                      assigning
                          ? 'جارٍ تخصيص المساعدة...'
                          : 'تخصيص المساعدة للأسر المحددة',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
