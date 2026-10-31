import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import 'assign_assistance_screen.dart';

class AssistanceHistoryScreen extends StatelessWidget {
  const AssistanceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: CustomAppBar(
          title: 'سجل المساعدات',
          subtitle: 'محمود حسن العلي · حي النور',
          leading: Icons.arrow_back,
          onLeadingPressed: () => Get.back(),
        ),
        body: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildTab('البيانات', isSelected: false),
                  const SizedBox(width: 8),
                  _buildTab('المساعدات 3', isSelected: true),
                  const SizedBox(width: 8),
                  _buildTab('الإحالات 1', isSelected: false),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'جميع المساعدات (3 عمليات)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  _buildHistoryCard(
                    title: 'طرد غذائي · طرد واحد',
                    date: '8 أكتوبر 2026',
                    officer: 'أحمد سالم',
                    note: 'تسليم مباشر في حي النور',
                    status: 'تمت المزامنة',
                    actionLabel: 'عرض توقيع المستلم',
                    actionIcon: Icons.edit_outlined,
                  ),
                  const SizedBox(height: 12),

                  _buildHistoryCard(
                    title: 'مستلزمات نظافة · حقيبتان',
                    date: '15 سبتمبر 2026',
                    officer: 'أحمد سالم',
                    note: 'تم التسليم وفق الاحتياج المسجل',
                    status: 'تمت المزامنة',
                    actionLabel: 'عرض صورة إثبات الاستلام',
                    actionIcon: Icons.image_outlined,
                  ),
                  const SizedBox(height: 12),

                  _buildHistoryCard(
                    title: 'طرد غذائي · طرد واحد',
                    date: '1 سبتمبر 2026',
                    officer: 'أحمد سالم',
                    note: 'المساعدة الأولى بعد التسجيل',
                    status: 'تمت المزامنة',
                    actionLabel: 'عرض توقيع المستلم',
                    actionIcon: Icons.edit_outlined,
                  ),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Get.to(() => const CreateAssistanceScreen()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF135354),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    '+ تسجيل مساعدة جديدة',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String title, {required bool isSelected}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F3EE) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? const Color(0xFF135354) : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard({
    required String title,
    required String date,
    required String officer,
    required String note,
    required String status,
    required String actionLabel,
    required IconData actionIcon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
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
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F3EE),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF135354),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'تاريخ التسليم: $date',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
          ),
          Text(
            'الموظف: $officer',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
          ),
          Text(
            note,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () {},
            icon: Icon(actionIcon, size: 16, color: const Color(0xFF135354)),
            label: Text(
              actionLabel,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF135354),
                fontWeight: FontWeight.bold,
              ),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 36),
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
