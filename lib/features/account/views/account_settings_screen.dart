import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sijil/core/theme/app_colors.dart';
import '../../../../core/widgets/custom_bottom_nav_bar.dart';
import 'package:sijil/core/widgets/app_button.dart';
import 'package:sijil/core/widgets/app_status_card.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../controllers/account_settings_controller.dart';
import '../widgets/app_option_tile.dart';
import '../widgets/profile_card.dart';

class AccountSettingsScreen extends StatelessWidget {
  AccountSettingsScreen({super.key});

  final AccountSettingsController controller =
  Get.put(AccountSettingsController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutralBackground,

      appBar: CustomAppBar(
        title:'الحساب والإعدادات', action: Icons.settings_outlined,
      ),

      bottomNavigationBar: CustomBottomNavBar(selectedIndex: 4,),

      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [


                Obx(() {
                  // Loading State
                  if (controller.isLoadingProfile.value) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    );
                  }

                  // Error State
                  if (controller.profileError.value.isNotEmpty) {
                    return Column(
                      children: [
                        AppStatusCard(
                          title: 'تعذر تحميل بيانات الحساب',
                          message: controller.profileError.value,
                          type: AppStatusType.error,
                        ),

                        const SizedBox(height: 12),

                        AppButton(
                          text: 'إعادة المحاولة',
                          type: AppButtonType.secondary,
                          icon: Icons.refresh,
                          onPressed: controller.loadUserProfile,
                        ),
                      ],
                    );
                  }

                  // Profile Data
                  return ProfileCard(
                    name: controller.userName.value,
                    organization: controller.organizationName.value,
                    role: controller.userRole.value,
                    area: controller.userArea.value,
                    email: controller.userEmail.value,
                  );
                }),


                const SizedBox(height: 28),

                // //المزامنة والعرض
                // sectionTitle('المزامنة والعرض'),
                //
                // const SizedBox(height: 16),
                //
                // Container(
                //   padding: const EdgeInsets.all(15),
                //   decoration: BoxDecoration(
                //     color: AppColors.surface,
                //     border: Border.all(
                //       color: AppColors.border,
                //     ),
                //     borderRadius: BorderRadius.circular(16),
                //   ),
                //   child: Column(
                //     crossAxisAlignment: CrossAxisAlignment.stretch,
                //     children: [
                //
                //       // Automatic Sync
                //       Obx(() => AppOptionTile(
                //         title: 'المزامنة التلقائية',
                //         selected: controller.autoSync.value,
                //         onTap: controller.toggleAutoSync,
                //       )),
                //
                //       const SizedBox(height: 12),
                //
                //       const Text(
                //         'تبدأ عند عودة الاتصال، مع الاحتفاظ بحالة كل عملية ومرفق.',
                //         style: TextStyle(
                //           fontSize: 13,
                //           color: AppColors.textSecondary,
                //           height: 1.7,
                //         ),
                //       ),
                //
                //       const Divider(
                //         height: 30,
                //         color: AppColors.border,
                //       ),
                //
                //       // Larger Text
                //       Obx(() => AppOptionTile(
                //         title: 'نص أكبر',
                //         selected: controller.largeText.value,
                //         onTap: controller.toggleLargeText,
                //       )),
                //
                //       const SizedBox(height: 12),
                //
                //       const Text(
                //         'تتبع الواجهة حجم خط الجهاز. يوسّع هذا الخيار النصوص دون إخفاء المحتوى.',
                //         style: TextStyle(
                //           fontSize: 13,
                //           color: AppColors.textSecondary,
                //           height: 1.7,
                //         ),
                //       ),
                //     ],
                //   ),
                // ),
                //
                // const SizedBox(height: 28),

                //الخصوصية والاذونات

                sectionTitle('الخصوصية والأذونات'),

                const SizedBox(height: 16),

                // Custom AppStatusCard
                const AppStatusCard(
                  title: 'حماية بيانات العمل',
                  message:
                  'تُحفظ البيانات في قاعدة محلية مشفّرة. '
                      'الوصول حسب دورك، ولا تُشارك سجلات الجهة '
                      'مع جهات أخرى إلا عبر إحالة رسمية.',
                  type: AppStatusType.success,
                ),

                const SizedBox(height: 20),

                AppButton(
                  text: 'مساعدة أذونات الكاميرا والملفات',
                  type: AppButtonType.secondary,
                  icon: Icons.camera_alt_outlined,
                  onPressed: () {
                    // TODO: Open permissions help screen
                  },
                ),

                const SizedBox(height: 12),

                const Text(
                  'عند رفض إذن الكاميرا، استخدم توثيق '
                      'المستلم للمساعدة أو امنح الإذن من '
                      'إعدادات الجهاز لإرفاق الصورة.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.7,
                  ),
                ),

                // const SizedBox(height: 20),
                //
                // AppButton(
                //   text: 'طلب تعديل بيانات الحساب من المشرف',
                //   type: AppButtonType.secondary,
                //   onPressed: () {
                //     // TODO: Open permissions help screen
                //   },
                // ),

                const SizedBox(height: 28),

               //تسجيل الخروج

                // sectionTitle('تسجيل الخروج'),

                // const SizedBox(height: 16),

                // Custom AppStatusCard
                // Obx(() => AppStatusCard(
                //   title:
                //   'لديك ${controller.pendingOperations.value} '
                //       'عمليات غير متزامنة',
                //   message:
                //   'لأمان أولًا ثم أمكن. الخروج لا يحذف '
                //       'البيانات المحلية، لكن فتحها مجددًا '
                //       'يتطلب الحساب نفسه. يلزم اتصال '
                //       'لتسجيل دخول جديد.',
                //   type: AppStatusType.offline,
                // )),

                // const SizedBox(height: 20),

                // Sync Center Button
                // AppButton(
                //   text: 'الانتقال إلى مركز المساعدة',
                //   type: AppButtonType.primary,
                //   onPressed: () {
                //     // TODO: Open permissions help screen
                //   },
                // ),

                const SizedBox(height: 20),

                Obx(() => AppButton(
                  text: 'تسجيل الخروج',
                  type: AppButtonType.primary,
                  isLoading: controller.isLoggingOut.value,
                  onPressed: controller.confirmLogout,
                )),

                const SizedBox(height: 20),

                const Text(
                  'لا يتم تغيير الدور أو حذف بيانات الجهاز من هذه الصفحة.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Section Title

  Widget sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

}
