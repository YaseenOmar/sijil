import 'package:flutter/material.dart';
import 'package:sijil/core/theme/app_colors.dart';
import 'package:sijil/core/widgets/app_button.dart';
import 'package:sijil/core/widgets/app_status_card.dart';
import 'package:sijil/core/widgets/custom_app_bar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.neutralBackground,

        // الشريط العلوي جاهز (العنوان + أيقونة الإشعارات)
        appBar: const CustomAppBar(
          title: 'صباح الخير، أحمد',
          icon: Icons.notifications_outlined,
        ),

        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // اسم الجمعية والدور
                const Text(
                  'جمعية الأمان · العامل الميداني',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 20),

                //  "كار دون اتصال"
                const AppStatusCard(
                  title: 'دون اتصال · ٧ عمليات بانتظار المزامنة',
                  message: 'تابع عملك على الجهاز. تُرسل التغييرات عند عودة الاتصال.',
                  type: AppStatusType.offline,
                ),

                const SizedBox(height: 20),

                // سطر المنطقة المكلّف بها
                _buildAreaRow(),

                const SizedBox(height: 16),

                // كروت الإحصائيات - الصف الأول
                Row(
                  children: [
                    Expanded(
                      child: buildStatCard(
                        value: '١٢٨',
                        label: 'الأسر المسجلة',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: buildStatCard(
                        value: '٨٦',
                        label: 'مساعدات هذا الشهر',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // كروت الإحصائيات - الصف الثاني
                Row(
                  children: [
                    Expanded(
                      child: buildStatCard(
                        value: '٩',
                        label: 'إحالات قيد المتابعة',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: buildStatCard(
                        value: '٢٣',
                        label: 'أسر ذات أولوية',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // عنوان القسم
                const Text(
                  'إجراء سريع',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 16),

                // زر إضافة أسرة جديدة (ضمن نطاق السبرنت)
                AppButton(
                  text: 'إضافة أسرة جديدة',
                  icon: Icons.person_add_alt_1_outlined,
                  onPressed: () {

                    // TODO: Get.to(() => const CreateFamilyScreen());
                    // لما اضغط على الزر، التطبيق بيفتح شاشة إنشاء أسرة

                  },
                ),

                const SizedBox(height: 12),

                // الزرين الثانويين (شكليين)
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        text: 'تسجيل مساعدة',
                        type: AppButtonType.secondary,
                        onPressed: () {},
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppButton(
                        text: 'إنشاء إحالة',
                        type: AppButtonType.secondary,
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // شريط التنقل السفلي
        bottomNavigationBar: NavigationBar(
          selectedIndex: 0,
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.successBackground,
          onDestinationSelected: (index) {
            // index 0 = الرئيسية (نحن فيها)
            // index 1 = الأسر
            // TODO: if (index == 1) Get.to(() => const FamiliesListScreen());
            //لما شاشة إنشاء الأسرة  تتجهز، بدي أشيل // من أول السطر عشان الزر ينقل لها
            // باقي التبويبات خارج نطاق السبرنت (شكلية فقط)
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: AppColors.primary),
              label: 'الرئيسية',
            ),
            NavigationDestination(
              icon: Icon(Icons.groups_outlined),
              label: 'الأسر',
            ),
            NavigationDestination(
              icon: Icon(Icons.volunteer_activism_outlined),
              label: 'المساعدات',
            ),
            NavigationDestination(
              icon: Icon(Icons.send_outlined),
              label: 'الإحالات',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              label: 'الحساب',
            ),
          ],
        ),
      ),
    );
  }

  // سطر "منطقتك المكلّف بها" مع شارة اسم الحي
  Widget _buildAreaRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Row(
          children: [
            Icon(
              Icons.location_on_outlined,
              size: 20,
              color: AppColors.textSecondary,
            ),
            SizedBox(width: 6),
            Text(
              'منطقتك المكلّف بها',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.successBackground,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'حي النور',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.success,
            ),
          ),
        ),
      ],
    );
  }

  // كارد إحصائية واحد (رقم + وصف)
  Widget buildStatCard({
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}