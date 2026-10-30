
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/widgets/custom_app_bar.dart';
import '../../auth/controllers/user_session_controller.dart';

class EditStaffScreen extends StatefulWidget {
  final String employeeId;
  final bool isPendingInvitation;

  const EditStaffScreen({
    super.key,
    required this.employeeId,
    required this.isPendingInvitation,
  });

  @override
  State<EditStaffScreen> createState() =>
      _EditStaffScreenState();
}

class _EditStaffScreenState extends State<EditStaffScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final UserSessionController session = Get.find<UserSessionController>();

  bool isLoading = true;
  bool isSaving = false;

  String staffName = '';
  String email = '';

  String? selectedRole;
  String? selectedAreaId;
  String? selectedStatus;

  List<Map<String, String>> areas = [];

  final List<Map<String, String>> roles = [
    {
      'id': 'field_worker',
      'name': 'موظف ميداني',
    },
    {
      'id': 'supervisor',
      'name': 'مشرف',
    },
  ];

  final List<Map<String, String>> statuses = [
    {
      'id': 'active',
      'name': 'نشط',
    },
    {
      'id': 'inactive',
      'name': 'غير نشط',
    },
  ];

  String get organizationId => session.organizationId.value;

  // ---------------------------------------
  // Employee document reference
  // ---------------------------------------

  DocumentReference<Map<String, dynamic>>
  get _employeeReference {
    if (widget.isPendingInvitation) {
      return _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('employees')
          .doc(widget.employeeId);
    }

    return _firestore
        .collection('users')
        .doc(widget.employeeId);
  }

  // ---------------------------------------
  // Load employee and areas
  // ---------------------------------------

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      if (organizationId.isEmpty) {
        throw Exception('لم يتم تحديد المؤسسة');
      }

      // Read employee data and organization areas.
      final results = await Future.wait([
        _employeeReference.get(),

        _firestore
            .collection('organizations')
            .doc(organizationId)
            .collection('areas')
            .get(),
      ]);

      final employeeSnapshot =
      results[0] as DocumentSnapshot<Map<String, dynamic>>;

      final areasSnapshot =
      results[1] as QuerySnapshot<Map<String, dynamic>>;

      if (!employeeSnapshot.exists) {
        throw Exception('لم يتم العثور على بيانات الموظف');
      }

      final data = employeeSnapshot.data()!;

      // Verify that the employee belongs to this organization.
      if (data['organizationId'] != organizationId) {
        throw Exception('الموظف لا يتبع لهذه المؤسسة');
      }

      final loadedAreas = areasSnapshot.docs.map((doc) {
        final name = doc.data()['name'];

        return {
          'id': doc.id,
          'name': name is String && name.isNotEmpty
              ? name
              : doc.id,
        };
      }).toList();

      if (!mounted) return;

      setState(() {
        staffName = data['fullName'] as String? ?? '';
        email = data['email'] as String? ?? '';

        selectedRole = data['role'] as String? ?? 'field_worker';

        selectedAreaId = data['areaId'] as String?;

        selectedStatus = data['status'] as String? ?? 'pending';

        areas = loadedAreas;

        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      Get.snackbar(
        'خطأ',
        'تعذر تحميل بيانات الموظف: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // ---------------------------------------
  // Save employee changes
  // ---------------------------------------

  Future<void> _saveChanges() async {
    if (isSaving) return;

    if (selectedRole == null) {
      Get.snackbar('تنبيه', 'يرجى اختيار الدور الوظيفي');
      return;
    }

    if (selectedAreaId == null ||
        !areas.any((area) => area['id'] == selectedAreaId)) {
      Get.snackbar('تنبيه', 'يرجى اختيار منطقة صحيحة');
      return;
    }

    if (!widget.isPendingInvitation &&
        selectedStatus == null) {
      Get.snackbar('تنبيه', 'يرجى اختيار حالة الحساب');
      return;
    }

    try {
      setState(() {
        isSaving = true;
      });

      // Fields shared by both document types.
      final Map<String, dynamic> updates = {
        'role': selectedRole,
        'areaId': selectedAreaId,
      };

      // Pending invitations must remain pending
      // until the invited employee accepts.
      if (!widget.isPendingInvitation) {
        updates['status'] = selectedStatus;
      }

      await _employeeReference.update(updates);

      if (!mounted) return;

      Get.back();

      Get.snackbar(
        'تم الحفظ',
        'تم تحديث بيانات $staffName بنجاح',
        snackPosition: SnackPosition.BOTTOM,
      );
    } on FirebaseException catch (e) {
      Get.snackbar(
        'خطأ',
        e.code == 'permission-denied'
            ? 'ليس لديك صلاحية لتعديل بيانات الموظف. تحقق من قواعد Firestore.'
            : 'تعذر تحديث البيانات: ${e.message ?? e.code}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'حدث خطأ أثناء تحديث بيانات الموظف',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  // ---------------------------------------
  // Dropdown widget
  // ---------------------------------------

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<Map<String, String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    final validValue = items.any(
          (item) => item['id'] == value,
    ) ? value : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 6),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.grey.shade300,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: validValue,
              hint: const Text('اختر'),
              isExpanded: true,

              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item['id'],
                  child: Text(
                    item['name']!,
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),

              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------
  // Screen UI
  // ---------------------------------------

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),

        appBar: CustomAppBar(
          title: 'إدارة الفريق والخدمات',
          subtitle: 'تعديل بيانات الموظف',
          leading: Icons.arrow_back,
          onLeadingPressed: () => Get.back(),
        ),

        body: isLoading
            ? const Center(
          child: CircularProgressIndicator(),
        )
            : _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),

            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.shade200,
              ),
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تعديل بيانات $staffName',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A202C),
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  email,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 20),

                // Role
                _buildDropdown(
                  label: 'الدور الوظيفي *',
                  value: selectedRole,
                  items: roles,
                  onChanged: (value) {
                    setState(() {
                      selectedRole = value;
                    });
                  },
                ),

                const SizedBox(height: 16),

                // Area
                _buildDropdown(
                  label: 'المنطقة المكلف بها *',
                  value: selectedAreaId,
                  items: areas,
                  onChanged: (value) {
                    setState(() {
                      selectedAreaId = value;
                    });
                  },
                ),

                const SizedBox(height: 16),

                // Account status
                if (widget.isPendingInvitation) ...[
                  const Text(
                    'حالة الحساب',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3CD),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'بانتظار قبول الدعوة',
                      style: TextStyle(
                        color: Color(0xFF856404),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ] else
                  _buildDropdown(
                    label: 'حالة الحساب',
                    value: selectedStatus,
                    items: statuses,
                    onChanged: (value) {
                      setState(() {
                        selectedStatus = value;
                      });
                    },
                  ),

                const SizedBox(height: 12),

                Text(
                  widget.isPendingInvitation
                      ? 'هذه دعوة لم يتم قبولها بعد. لا يمكن تفعيل الحساب إلا بعد قبول الموظف للدعوة.'
                      : 'يمكن للمشرف تعديل الدور والمنطقة وحالة حساب الموظف.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isSaving || areas.isEmpty
                        ? null
                        : _saveChanges,

                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF135354),
                      disabledBackgroundColor: Colors.grey.shade400,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),

                    child: isSaving
                        ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : const Text(
                      'حفظ تغييرات الموظف',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (areas.isEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'لا توجد مناطق مسجلة في قاعدة البيانات.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
