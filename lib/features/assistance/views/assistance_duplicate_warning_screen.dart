import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/widgets/custom_app_bar.dart';

class AssistanceDuplicateWarningScreen extends StatelessWidget {
  const AssistanceDuplicateWarningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: CustomAppBar(
          title: 'التحقق من المساعدة',
          subtitle: 'منع تكرار التوزيع',
          leading: Icons.arrow_back,
          onLeadingPressed: () => Get.back(),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF3CD),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.inventory_2_outlined,
                        size: 32,
                        color: Color(0xFF856404),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'سبق تسليم طرد غذائي',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A202C),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'تلقت أسرة محمود حسن العلي المساعدة نفسها خلال آخر 30 يوماً. لا يمكن حفظ عملية تسليم مكررة.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'المساعدة السابقة: طرد غذائي · طرد واحد',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'تاريخ التسليم السابق: 8 أكتوبر 2026 - منذ 13 يوماً',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'الموظف: أحمد سالم · توقيع المستلم',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'معاودة التسجيل متاحة في: 7 نوفمبر 2026 طبقاً لفترة المنع المعتمدة لهذا النوع (30 يوماً).',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF135354),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.history, color: Colors.white),
                  label: const Text(
                    'عرض المساعدة السابقة',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF135354),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: () => Get.back(),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'العودة لتصحيح الإدخال',
                    style: TextStyle(
                      color: Color(0xFF135354),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.info_outline, size: 18, color: Colors.blueGrey),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'لم تُحفظ مساعدة جديدة. تحقق من الأسرة ونوع الخدمة إذا فتح هذا التنبيه تجاوز قاعدة منع التكرار.',
                        style: TextStyle(fontSize: 11, color: Colors.blueGrey),
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
}
