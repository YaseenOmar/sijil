import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../staff/views/add_staff_screen.dart';
import 'edit_staff_screen.dart';

class TeamAndServicesScreen extends StatelessWidget {
  const TeamAndServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // قائمة الموظفين المعروضة حسب التصميم
    final staffList = [
      {
        'name': 'نورا إبراهيم',
        'role': 'مشرفة • جميع مناطق الجهة',
        'status': 'نشطة',
        'statusColor': const Color(0xFFE6F4EA),
        'textColor': const Color(0xFF137333),
      },
      {
        'name': 'أحمد سالم',
        'role': 'عامل ميداني • حي النور',
        'status': 'نشط',
        'statusColor': const Color(0xFFE6F4EA),
        'textColor': const Color(0xFF137333),
      },
      {
        'name': 'ليلى منصور',
        'role': 'عاملة ميدانية • حي السلام',
        'status': 'نشطة',
        'statusColor': const Color(0xFFE6F4EA),
        'textColor': const Color(0xFF137333),
      },
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: CustomAppBar(
          title: 'الفريق والخدمات',
          subtitle: 'خالد عمر • مدير جمعية الأمان',
          leading: Icons.arrow_back,
          onLeadingPressed: () => Get.back(),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // بطاقة تنبيه صلاحيات الإدارة
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F3EE),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFCCE4DA)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.verified_user_outlined,
                      color: Color(0xFF135354),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'صلاحيات إدارية لجهتك فقط',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF135354),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'تسجل تغييرات الفريق والخدمات في سجل التدقيق. لا يستطيع الموظف تغيير دوره من إعدادات حسابه.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF2D3748),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'الفريق • ٣ موظفين',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A202C),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      // الانتقال إلى شاشة إضافة موظف
                      Get.to(() => AddStaffScreen());;
                    },
                    icon: const Icon(
                      Icons.add,
                      size: 16,
                      color: Color(0xFF135354),
                    ),
                    label: const Text(
                      'إضافة موظف',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF135354),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: staffList.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final staff = staffList[index];
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      final roleParts = (staff['role'] as String).split(' • ');
                      final role = roleParts.isNotEmpty
                          ? roleParts[0].trim()
                          : 'عامل ميداني';
                      final area = roleParts.length > 1
                          ? roleParts[1].trim()
                          : 'حي النور';

                      Get.to(
                        () => EditStaffScreen(
                          staffName: staff['name'] as String,
                          initialRole: role,
                          initialArea: area,
                          initialStatus: staff['status'] as String,
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  staff['name'] as String,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A202C),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  staff['role'] as String,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: staff['statusColor'] as Color,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              staff['status'] as String,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: staff['textColor'] as Color,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              const Text(
                'تهيئة الخدمات المتاحة',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A202C),
                ),
              ),
              const SizedBox(height: 12),

              // بطاقة مساعدة غذائية
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'مساعدات غذائية',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F3EE),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'الخدمة متاحة للإحالات',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF135354),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'فترة منع تكرار الطرد الغذائي *',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '٣٠ يوماً',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'الكمية الافتراضية',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'طرد واحد',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('حفظ إعدادات الخدمة'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'مستلزمات نظافة',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F3EE),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'متاحة',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF135354),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'مسؤول الخدمة: نورا إبراهيم • آخر تحديث: ٢٠ أكتوبر ٢٠٢٦',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'تعديل الخدمة أو إيقاف استقبال الإحالات',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // زر إضافة خدمة للجهة
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, color: Color(0xFF135354)),
                label: const Text(
                  'إضافة خدمة للجهة',
                  style: TextStyle(
                    color: Color(0xFF135354),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  side: const BorderSide(color: Color(0xFF135354)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'تغييرات الفريق والخدمات تخص جمعية الأمان وحدها ولا تؤثر على سجلات الموظفين أو الخدمات لدى الجهات الأخرى.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
