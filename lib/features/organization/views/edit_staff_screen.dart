import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/widgets/custom_app_bar.dart';

class EditStaffScreen extends StatefulWidget {
  final String staffName;
  final String initialRole;
  final String initialArea;
  final String initialStatus;

  const EditStaffScreen({
    super.key,
    required this.staffName,
    this.initialRole = 'عامل ميداني',
    this.initialArea = 'حي النور',
    this.initialStatus = 'نشط',
  });

  @override
  State<EditStaffScreen> createState() => _EditStaffScreenState();
}

class _EditStaffScreenState extends State<EditStaffScreen> {
  late String selectedRole;
  late String selectedArea;
  late String selectedStatus;

  final List<String> roles = [
    'عامل ميداني',
    'عاملة ميدانية',
    'مشرفة',
    'مشرف ميداني',
    'مدير الجهة',
  ];
  final List<String> areas = ['حي النور', 'حي السلام', 'جميع مناطق الجهة'];
  final List<String> statuses = ['نشط', 'معلق', 'غير نشط'];

  @override
  void initState() {
    super.initState();
    selectedRole = roles.contains(widget.initialRole)
        ? widget.initialRole
        : roles.first;
    selectedArea = areas.contains(widget.initialArea)
        ? widget.initialArea
        : areas.first;
    selectedStatus = statuses.contains(widget.initialStatus)
        ? widget.initialStatus
        : statuses.first;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: CustomAppBar(
          title: 'تعديل بيانات ${widget.staffName}',
          subtitle: 'إدارة الفريق والخدمات',
          leading: Icons.arrow_back,
          onLeadingPressed: () => Get.back(),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تعديل بيانات ${widget.staffName}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A202C),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // الدور الوظيفي
                    const Text(
                      'الدور الوظيفي *',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildDropdown(
                      value: selectedRole,
                      items: roles,
                      onChanged: (val) => setState(() => selectedRole = val!),
                    ),
                    const SizedBox(height: 14),

                    // المنطقة المكلف بها
                    const Text(
                      'المنطقة المكلف بها *',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildDropdown(
                      value: selectedArea,
                      items: areas,
                      onChanged: (val) => setState(() => selectedArea = val!),
                    ),
                    const SizedBox(height: 14),

                    // حالة الحساب
                    const Text(
                      'حالة الحساب',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildDropdown(
                      value: selectedStatus,
                      items: statuses,
                      onChanged: (val) => setState(() => selectedStatus = val!),
                    ),
                    const SizedBox(height: 10),

                    Text(
                      'تغيير الدور يتطلب تأكيد المدير لوضع الوصول قبل نقل الموظف إلى منطقة أخرى.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // زر حفظ التغييرات
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          // منطق حفظ التعديلات
                          Get.back();
                          Get.snackbar(
                            'تم الحفظ',
                            'تم تحديث بيانات ${widget.staffName} بنجاح',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF135354),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item, style: const TextStyle(fontSize: 14)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
