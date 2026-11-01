import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:sijil/core/theme/app_colors.dart';
import 'package:sijil/core/widgets/app_button.dart';
import 'package:sijil/core/widgets/app_status_card.dart';
import 'package:sijil/core/widgets/custom_app_bar.dart';
import 'package:sijil/core/widgets/custom_bottom_nav_bar.dart';
import 'package:sijil/features/home/widgets/home_stat_card.dart';
import '../../../assistance/views/assign_assistance_screen.dart';
import '../../../auth/controllers/user_session_controller.dart';
import '../../../service_catalog/views/add_service_screen.dart';
import '../../../staff/views/team_and_services_screen.dart';
import '../../../staff/views/add_staff_screen.dart';

/// Home screen for the organization manager (لوحة مدير الجهة).
///
/// Statistics are calculated from Firestore for the current organization.
class ManagerHomeScreen extends StatelessWidget {
  ManagerHomeScreen({super.key});

  static const double _screenPadding = 20;

  final session = Get.find<UserSessionController>();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.neutralBackground,
        appBar: CustomAppBar(
          title: 'لوحة مدير الجهة',
          subtitle: '${session.fullName.value} . ${session.organizationName
              .value}',
          action: Icons.notifications_outlined,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(_screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ScopeBadge(text: 'جميع مناطق ${session.organizationName
                    .value} · ${session.roleName}'),

                const SizedBox(height: 16),

// const AppStatusCard(
//   title: 'مؤشرات مخبّأة · ١٠–٢٠ أكتوبر ٢٠٢٦',
//   message:
//   'البيانات حتى ٢٠ أكتوبر ٢٠٢٦، ٤:٣٠ م. لا تشمل عمليات '
//       '٢١ أكتوبر أو ما لم يُزامن؛ ليست لوحة آنية.',
//   type: AppStatusType.offline,
//   icon: Icons.info_outline,
// ),
//
// const SizedBox(height: 16),


// Live statistics from the current organization only.
                _ManagerLiveStats(organizationId: session.organizationId.value),

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
                        Get.to(() => AddServiceScreen());
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

/// Live Firestore statistics scoped to the supervisor's organization.
/// "Assistance operations" are assignment records, not confirmed deliveries.
/// "Beneficiary families" counts distinct familyId values in those records.
class _ManagerLiveStats extends StatelessWidget {
  const _ManagerLiveStats({required this.organizationId});

  final String organizationId;

  String _arabicDigits(int number) {
    const digits = '٠١٢٣٤٥٦٧٨٩';
    return number.toString().split('').map((c) {
      final digit = int.tryParse(c);
      return digit == null ? c : digits[digit];
    }).join();
  }

  Widget _stats({
    required String families,
    required String operations,
    required String beneficiaries,
    required String completed,
  }) {
    return Column(
      children: [
        _StatsRow(
          first: HomeStat(value: families, label: 'أسرة مسجلة'),
          second: HomeStat(value: operations, label: 'عملية مساعدة'),
        ),
        const SizedBox(height: 12),
        _StatsRow(
          first: HomeStat(value: beneficiaries, label: 'أسرة مستفيدة'),
          second: HomeStat(value: completed, label: 'إحالة مكتملة'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (organizationId.isEmpty) {
      return const AppStatusCard(
        title: 'تعذر عرض الإحصائيات',
        message: 'معرّف المؤسسة غير متوفر.',
        type: AppStatusType.error,
      );
    }

    final firestore = FirebaseFirestore.instance;
    final organization = firestore.collection('organizations').doc(
        organizationId);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: organization.collection('families').snapshots(),
      builder: (context, familiesSnapshot) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: organization.collection('assistanceAssignments').snapshots(),
          builder: (context, assignmentsSnapshot) {
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: firestore.collection('referrals')
                  .where('targetOrganizationId', isEqualTo: organizationId)
                  .where('status', isEqualTo: 'completed')
                  .snapshots(),
              builder: (context, referralsSnapshot) {
                if (familiesSnapshot.hasError || assignmentsSnapshot.hasError ||
                    referralsSnapshot.hasError) {
                  return const AppStatusCard(
                    title: 'تعذر تحميل الإحصائيات',
                    message: 'تحقق من الاتصال وصلاحيات قراءة بيانات المؤسسة والإحالات.',
                    type: AppStatusType.error,
                  );
                }

                if (!familiesSnapshot.hasData || !assignmentsSnapshot.hasData ||
                    !referralsSnapshot.hasData) {
                  return _stats(
                    families: '—', operations: '—',
                    beneficiaries: '—', completed: '—',
                  );
                }

                final assignments = assignmentsSnapshot.data!.docs;
                final beneficiaryIds = assignments
                    .map((doc) => doc.data()['familyId'])
                    .whereType<String>()
                    .where((id) => id.isNotEmpty)
                    .toSet();

                final completedCount = referralsSnapshot.data!
                    .docs
                    .where(
                      (doc) => doc.data()['status'] == 'completed',
                )
                    .length;

                return _stats(
                  families: _arabicDigits(familiesSnapshot.data!.docs.length),
                  operations: _arabicDigits(assignments.length),
                  beneficiaries: _arabicDigits(beneficiaryIds.length),
                  completed: _arabicDigits(completedCount),
                );
              },
            );
          },
        );
      },
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
