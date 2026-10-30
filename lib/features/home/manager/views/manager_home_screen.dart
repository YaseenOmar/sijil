import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:sijil/core/theme/app_colors.dart';
import 'package:sijil/core/widgets/app_button.dart';
import 'package:sijil/core/widgets/app_status_card.dart';
import 'package:sijil/core/widgets/custom_app_bar.dart';
import 'package:sijil/core/widgets/custom_bottom_nav_bar.dart';
import 'package:sijil/features/home/widgets/home_stat_card.dart';
import '../../../assistance/views/create_assistance_screen.dart';
import '../../../organization/views/team_and_services_screen.dart';
import '../../../staff/views/add_staff_screen.dart';

/// Home screen for the organization manager (لوحة مدير الجهة).
///
/// All values are placeholders until the data is read from Firebase.
/// Buttons are visual only for now (same as the employee home screen).
class ManagerHomeScreen extends StatelessWidget {
  const ManagerHomeScreen({super.key});

  static const double _screenPadding = 20;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.neutralBackground,
        appBar: CustomAppBar(
          title: 'لوحة مدير الجهة',
          subtitle: 'خالد عمر · جمعية الأمان',
          leading: Icons.arrow_back,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(_screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _ScopeBadge(text: 'جميع مناطق جمعية الأمان · مدير الجهة'),

                const SizedBox(height: 16),

                const AppStatusCard(
                  title: 'مؤشرات مخبّأة · ١٠–٢٠ أكتوبر ٢٠٢٦',
                  message:
                  'البيانات حتى ٢٠ أكتوبر ٢٠٢٦، ٤:٣٠ م. لا تشمل عمليات '
                      '٢١ أكتوبر أو ما لم يُزامن؛ ليست لوحة آنية.',
                  type: AppStatusType.offline,
                  icon: Icons.info_outline,
                ),

                const SizedBox(height: 16),


                // Statistics (two rows of two cards)
                const _StatsRow(
                  first: HomeStat(value: '٤٨٦', label: 'أسرة مسجلة'),
                  second: HomeStat(value: '٢١٤', label: 'عملية مساعدة'),
                ),
                const SizedBox(height: 12),
                const _StatsRow(
                  first: HomeStat(value: '١٧٨', label: 'أسرة مستفيدة'),
                  second: HomeStat(value: '٣٦', label: 'إحالة مكتملة'),
                ),

                const SizedBox(height: 24),

                // ---------- Work follow-up ----------
                /*const _SectionTitle('متابعة العمل'),
                const SizedBox(height: 12),
                _InfoCard(
                  children: [
                    const _CardText(
                      'قائمة مراجعة متاحة حتى ٢١ أكتوبر، ٩:٣٢ ص',
                      isLabel: true,
                    ),
                    const SizedBox(height: 4),
                    const _CardText(
                      '١٢ سجلًا بانتظار الاعتماد · منها سامي يوسف الخطيب',
                    ),
                    const SizedBox(height: 16),
                    const _CardText(
                      'قائمة الوارد المتاحة حتى ٢١ أكتوبر، ٨:٥٥ ص',
                      isLabel: true,
                    ),
                    const SizedBox(height: 4),
                    const _CardText('٥ إحالات بانتظار القرار'),
                    const SizedBox(height: 16),
                    const _CardText(
                      'أوقات القوائم مستقلة عن فترة مؤشرات التقرير أعلاه.',
                      isSmall: true,
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      text: 'فتح لوحة المشرف واعتماد البيانات',
                      type: AppButtonType.secondary,
                      onPressed: () {},
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      text: 'فتح الإحالات الواردة',
                      type: AppButtonType.secondary,
                      onPressed: () {},
                    ),
                  ],
                ),

                const SizedBox(height: 24),
*/
                // ---------- Administrative priorities ----------
                const _SectionTitle('أولويات المتابعة الإدارية'),
                const SizedBox(height: 12),
                const _InfoCard(
                  children: [
                    _CardText(
                      'مراجعة السجلات غير المعتمدة، متابعة الإحالات دون قرار، '
                          'والتحقق من حداثة بيانات الفريق والخدمات.',
                    ),
                    SizedBox(height: 12),
                    _CardText(
                      'ترتيب مهام العمل فقط؛ لا تصنيف آلي لاستحقاق الأسر '
                          'أو أولوية جديدة.',
                      isLabel: true,
                      isSmall: true,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ---------- Organization management ----------
                const _SectionTitle('إدارة الجهة'),
                const SizedBox(height: 12),
                _InfoCard(
                  children: [
                    const _CardText('الفريق الحالي', isLabel: true),
                    const SizedBox(height: 4),
                    const _CardText('نورا إبراهيم · أحمد سالم · ليلى منصور'),
                    const SizedBox(height: 16),
                    AppButton(
                      text: 'إدارة الفريق والخدمات',
                      onPressed: () {
                        Get.to(() => TeamAndServicesScreen());
                      },
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      text: 'إضافة موظف',
                      type: AppButtonType.secondary,
                      onPressed: () {
                        Get.to(() => AddStaffScreen());
                      },
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      text: 'إضافة خدمة للجهة',
                      type: AppButtonType.secondary,
                      onPressed: () {
                        Get.to(() => CreateAssistanceScreen());
                      },
                    ),
                  ],
                ),

                // const SizedBox(height: 24),

                // ---------- Reports and export ----------
                /*const _SectionTitle('التقارير والتصدير'),
                const SizedBox(height: 12),
                _InfoCard(
                  children: [
                    const _CardText('المساعدات بحسب النوع', isLabel: true),
                    const SizedBox(height: 4),
                    const _CardText('غذاء ١٢٨ · صحة ٥٤ · نظافة ٣٢'),
                    const SizedBox(height: 16),
                    AppButton(
                      text: 'فتح التقارير وتصدير النسخة المحفوظة',
                      type: AppButtonType.secondary,
                      onPressed: () {},
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      text: 'عرض توزيع الأسر حسب المنطقة',
                      type: AppButtonType.secondary,
                      onPressed: () {},
                    ),
                  ],
                ),

                const SizedBox(height: 24),*/

                // ---------- Sync info ----------
                // const AppStatusCard(
                //   title: 'تحديث البيانات ضمن الجهة فقط',
                //   message:
                //   'افتح مركز المزامنة للتحقق من آخر اتصال وتحديث ما '
                //       'تسمح به صلاحيتك. لا تتضمن اللوحة أسر الجهات الأخرى '
                //       'أو إشراف الشبكة المستقبلي.',
                //   type: AppStatusType.success,
                //   icon: Icons.lock_outline,
                // ),
                //
                // const SizedBox(height: 16),
                //
                // AppButton(
                //   text: 'فتح مركز المزامنة',
                //   type: AppButtonType.secondary,
                //   onPressed: () {},
                // ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: const CustomBottomNavBar(selectedIndex: 0),
      ),
    );
  }
}

/// Small badge under the app bar (same look as the area badge on the
/// employee home screen).
class _ScopeBadge extends StatelessWidget {
  const _ScopeBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.successBackground,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.success,
          ),
        ),
      ),
    );
  }
}

/// Two statistic cards side by side (reuses HomeStatCard).
class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.first, required this.second});

  final HomeStat first;
  final HomeStat second;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: HomeStatCard(stat: first)),
        const SizedBox(width: 12),
        Expanded(child: HomeStatCard(stat: second)),
      ],
    );
  }
}

/// Section heading (same style as "إجراء سريع" on the employee home).
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
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

/// White card with border (same decoration as HomeStatCard).
class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

/// Text used inside the cards: main text, gray label, or small note.
class _CardText extends StatelessWidget {
  const _CardText(this.text, {this.isLabel = false, this.isSmall = false});

  final String text;
  final bool isLabel;
  final bool isSmall;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: isSmall ? 13 : (isLabel ? 13 : 15),
        height: 1.6,
        fontWeight: isLabel || isSmall ? FontWeight.normal : FontWeight.w600,
        color: isLabel ? AppColors.textSecondary : AppColors.textPrimary,
      ),
    );
  }
}