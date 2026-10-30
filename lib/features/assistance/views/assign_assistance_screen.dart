import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/assistance_controller.dart';
import '../models/assistance_model.dart';
import '../../../../core/widgets/custom_app_bar.dart';

// Optional preselection when navigating from the family profile.
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

class CreateAssistanceScreen extends StatefulWidget {
  final FamilyInfo? initialFamily;

  const CreateAssistanceScreen({super.key, this.initialFamily});

  @override
  State<CreateAssistanceScreen> createState() =>
      _CreateAssistanceScreenState();
}

class _CreateAssistanceScreenState extends State<CreateAssistanceScreen> {
  static const Color primary = Color(0xFF165D59);
  final AssistanceController controller = Get.find<AssistanceController>();
  final TextEditingController notesController = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  final List<FamilyInfo> availableFamilies = [];
  bool loadingFamilies = true;
  String? familyError;
  String searchText = '';

  @override
  void initState() {
    super.initState();
    // Avoid retaining selections from an earlier visit to this form.
    controller.clearSelection();
    if (widget.initialFamily != null) {
      controller.selectFamilies([widget.initialFamily!.id]);
    }
    if (controller.assistances.isEmpty) {
      controller.loadAssistances();
    }
    _loadFamilies();
  }

  Future<void> _loadFamilies() async {
    setState(() {
      loadingFamilies = true;
      familyError = null;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw StateError('يجب تسجيل الدخول أولاً');
      final firestore = FirebaseFirestore.instance;
      final profile = await firestore.collection('users').doc(user.uid).get();
      final userData = profile.data();
      if (userData == null || userData['status'] != 'active') {
        throw StateError('حساب المستخدم غير فعّال أو بياناته غير موجودة');
      }
      if (userData['organizationId'] != controller.organizationId) {
        throw StateError('المؤسسة غير مطابقة لحساب المستخدم');
      }
      final role = userData['role'] as String? ?? '';
      if (!['employee', 'supervisor', 'manager'].contains(role)) {
        throw StateError('لا توجد صلاحية لعرض الأسر');
      }
      Query<Map<String, dynamic>> query = firestore
          .collection('organizations')
          .doc(controller.organizationId)
          .collection('families');
      if (role == 'employee') {
        final areaId = userData['areaId'] as String?;
        if (areaId == null || areaId.isEmpty) {
          throw StateError('المنطقة غير محددة في ملف المستخدم');
        }
        query = query.where('areaId', isEqualTo: areaId);
      }
      final snapshot = await query.get();
      final families = snapshot.docs.map((doc) {
        final data = doc.data();
        return FamilyInfo(
          id: doc.id,
          name: data['headName'] as String? ?? 'أسرة بدون اسم',
          membersCount: (data['membersCount'] as num?)?.toInt() ?? 0,
          area: data['areaId'] as String? ?? '',
          nationalId: data['nationalId'] as String? ?? '',
        );
      }).toList();
      families.sort((a, b) => a.name.compareTo(b.name));
      if (!mounted) return;
      setState(() {
        availableFamilies
          ..clear()
          ..addAll(families);
        loadingFamilies = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        familyError = e.toString();
        loadingFamilies = false;
      });
    }
  }

  void _openFamilySelectionSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: FractionallySizedBox(
          heightFactor: 0.80,
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              final filtered = availableFamilies.where((f) {
                return f.name.contains(searchText) ||
                    f.nationalId.contains(searchText);
              }).toList();
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text('اختيار الأسر المستفيدة',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'ابحث باسم رب الأسرة أو رقم الهوية',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setSheetState(() => searchText = value.trim());
                      },
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Obx(() => ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final family = filtered[index];
                          final checked = controller.selectedFamilyIds.contains(family.id);
                          return CheckboxListTile(
                            value: checked,
                            activeColor: primary,
                            title: Text(family.name),
                            subtitle: Text(
                              '${family.membersCount} أفراد · ${family.area} · ${family.nationalId}',
                            ),
                            onChanged: (value) {
                              controller.toggleFamily(family.id);
                              setSheetState(() {});
                            },
                          );
                        },
                      )),
                    ),
                    Obx(() => FilledButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      style: FilledButton.styleFrom(backgroundColor: primary),
                      child: Text('تأكيد الاختيار (${controller.selectedFamilyIds.length})'),
                    )),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (controller.selectedAssistance.value == null) {
      Get.snackbar('تنبيه', 'اختر نوع المساعدة أولاً');
      return;
    }
    if (controller.selectedFamilyIds.isEmpty) {
      Get.snackbar('تنبيه', 'اختر أسرة واحدة على الأقل');
      return;
    }
    await controller.assignSelectedAssistance(
      notes: notesController.text.trim(),
    );
    if (!mounted) return;
    final error = controller.errorMessage.value;
    if (error.isNotEmpty) {
      Get.snackbar('تعذر التخصيص', error, snackPosition: SnackPosition.BOTTOM);
      return;
    }
    final successes = controller.successfulAssignments;
    final failures = controller.failedAssignments;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('نتيجة تخصيص المساعدة'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('نجح: $successes · لم ينجح: $failures'),
              const SizedBox(height: 10),
              Flexible(
                child: Obx(() => ListView.builder(
                  shrinkWrap: true,
                  itemCount: controller.assignmentResults.length,
                  itemBuilder: (_, index) {
                    final result = controller.assignmentResults[index];
                    final familyId = result['familyId']?.toString() ?? '';
                    final family = availableFamilies.where((f) => f.id == familyId);
                    final name = family.isEmpty ? familyId : family.first.name;
                    final success = result['success'] == true;
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(success ? Icons.check_circle : Icons.error_outline,
                          color: success ? Colors.green : Colors.red),
                      title: Text(name),
                      subtitle: Text(result['message']?.toString() ?? ''),
                    );
                  },
                )),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (failures == 0 && successes > 0) {
      Get.back();
    } else if (successes > 0) {
      controller.keepFailedFamiliesSelected();
    }
  }

  @override
  void dispose() {
    notesController.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F6F2),
        appBar: CustomAppBar(
          title: 'تخصيص مساعدة',
          leading: Icons.arrow_back,
          onLeadingPressed: () => Get.back(),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('الأسر المستفيدة *',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (loadingFamilies)
                const Center(child: CircularProgressIndicator())
              else if (familyError != null)
                Column(
                  children: [
                    Text(familyError!, style: const TextStyle(color: Colors.red)),
                    TextButton(onPressed: _loadFamilies, child: const Text('إعادة المحاولة')),
                  ],
                )
              else ...[
                  Obx(() {
                    final selected = availableFamilies
                        .where((f) => controller.selectedFamilyIds.contains(f.id))
                        .toList();
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBF7F4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(selected.isEmpty
                          ? 'لم يتم اختيار أي أسرة'
                          : '${selected.length} أسرة محددة\n${selected.map((f) => f.name).join('، ')}'),
                    );
                  }),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: availableFamilies.isEmpty ? null : _openFamilySelectionSheet,
                    icon: const Icon(Icons.groups_outlined),
                    label: const Text('اختيار أسرة أو عدة أسر'),
                  ),
                ],
              const SizedBox(height: 20),
              const Text('نوع المساعدة *',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (controller.errorMessage.value.isNotEmpty &&
                    controller.assistances.isEmpty) {
                  return TextButton(
                    onPressed: controller.loadAssistances,
                    child: const Text('تعذر تحميل المساعدات - إعادة المحاولة'),
                  );
                }
                final items = controller.assistances.toList();
                final selected = controller.selectedAssistance.value;
                return DropdownButtonFormField<String>(
                  value: items.any((a) => a.id == selected?.id) ? selected!.id : null,
                  isExpanded: true,
                  hint: const Text('اختر المساعدة'),
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                  ),
                  items: items.map((AssistanceModel a) => DropdownMenuItem(
                    value: a.id,
                    child: Text('${a.name} (تكرار كل ${a.cooldownDays} يوم)'),
                  )).toList(),
                  onChanged: controller.isAssigning.value ? null : (id) {
                    if (id == null) return;
                    controller.selectAssistance(items.firstWhere((a) => a.id == id));
                  },
                );
              }),
              const SizedBox(height: 18),
              TextField(
                controller: notesController,
                minLines: 2,
                maxLines: 4,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات (اختياري)',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'تبدأ مدة منع تكرار المساعدة من لحظة التخصيص. '
                        'هذه الشاشة لا تؤكد التسليم الفعلي ولا تحفظ توقيعًا أو صورة استلام.',
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Obx(() => ElevatedButton.icon(
                onPressed: controller.isAssigning.value || loadingFamilies ||
                    familyError != null
                    ? null
                    : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
                icon: controller.isAssigning.value
                    ? const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2,
                      color: Colors.white),
                )
                    : const Icon(Icons.assignment_turned_in_outlined),
                label: Text(controller.isAssigning.value
                    ? 'جارٍ التخصيص...' : 'تخصيص المساعدة للأسر المحددة'),
              )),
            ],
          ),
        ),
      ),
    );
  }
}
