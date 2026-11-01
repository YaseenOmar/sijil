import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sijil/features/staff/views/staff_section.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../auth/controllers/user_session_controller.dart';
import 'add_staff_screen.dart';
import 'edit_staff_screen.dart';

class TeamAndServicesScreen extends StatelessWidget {
  TeamAndServicesScreen({super.key});
  final session = Get.find<UserSessionController>();

  @override
  Widget build(BuildContext context) {

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: CustomAppBar(
          title: 'الفريق والخدمات',
          subtitle: '${session.fullName.value} . ${session.organizationName.value}',
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

              Obx(
                    () => StaffSection(
                  organizationId: session.organizationId.value,
                  currentUserId: session.uid.value,
                ),
              ),

              const SizedBox(height: 24),

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


