
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:sijil/features/auth/controllers/user_session_controller.dart';
import 'package:sijil/features/home/widgets/home_stat_card.dart';

class HomeStatsGrid extends StatelessWidget {
  const HomeStatsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Get.find<UserSessionController>();
    final firestore = FirebaseFirestore.instance;

    return Obx(() {
      final orgId = session.organizationId.value.trim();
      final areaId = session.areaId.value.trim();
      final uid = FirebaseAuth.instance.currentUser?.uid;

      if (orgId.isEmpty || areaId.isEmpty || uid == null) {
        return _statsGrid('—', '—', '—', '—');
      }

      final familiesStream = firestore
          .collection('organizations')
          .doc(orgId)
          .collection('families')
          .where('areaId', isEqualTo: areaId)
          .snapshots();

      final assignmentsStream = firestore
          .collection('organizations')
          .doc(orgId)
          .collection('assistanceAssignments')
          .where('areaId', isEqualTo: areaId)
          .snapshots();

      // Show only referrals created by this employee.
      final referralsStream = firestore
          .collection('referrals')
          .where('createdBy', isEqualTo: uid)
          .snapshots();

      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: familiesStream,
        builder: (context, familiesSnapshot) {
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: assignmentsStream,
            builder: (context, assignmentsSnapshot) {
              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: referralsStream,
                builder: (context, referralsSnapshot) {
                  // Families in the employee's area.
                  final familiesCount = familiesSnapshot.hasError
                      ? '—'
                      : familiesSnapshot.hasData
                      ? '${familiesSnapshot.data!.docs.length}'
                      : '…';

                  // Assistance assignments in this area.
                  final assignments = assignmentsSnapshot.data?.docs ?? [];

                  final activeAssignments = assignments.where((doc) {
                    return doc.data()['status'] != 'canceled';
                  }).toList();

                  final assistanceCount = assignmentsSnapshot.hasError
                      ? '—'
                      : assignmentsSnapshot.hasData
                      ? '${activeAssignments.length}'
                      : '…';

                  // Unique families receiving assistance assignments.
                  final beneficiaryIds = activeAssignments
                      .map((doc) => doc.data()['familyId'])
                      .whereType<String>()
                      .where((id) => id.isNotEmpty)
                      .toSet();

                  final beneficiariesCount = assignmentsSnapshot.hasError
                      ? '—'
                      : assignmentsSnapshot.hasData
                      ? '${beneficiaryIds.length}'
                      : '…';

                  // Completed outgoing referrals in the same area.
                  final completedCount = referralsSnapshot.hasError
                      ? '—'
                      : referralsSnapshot.hasData
                      ? '${referralsSnapshot.data!.docs.where((doc) {
                    final data = doc.data();
                    return data['sourceOrganizationId'] == orgId &&
                        data['areaId'] == areaId &&
                        data['status'] == 'completed';
                  }).length}'
                      : '…';

                  return Column(
                    children: [
                      _StatsRow(
                        first: HomeStat(
                          value: familiesCount,
                          label: 'أسرة مسجلة',
                        ),
                        second: HomeStat(
                          value: assistanceCount,
                          label: 'عملية مساعدة',
                        ),
                      ),
                      const SizedBox(height: 12),
                      _StatsRow(
                        first: HomeStat(
                          value: beneficiariesCount,
                          label: 'أسرة مستفيدة',
                        ),
                        second: HomeStat(
                          value: completedCount,
                          label: 'إحالة مكتملة',
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      );
    });
  }

  Widget _statsGrid(
      String families,
      String assistances,
      String beneficiaries,
      String referrals,
      ) {
    return Column(
      children: [
        _StatsRow(
          first: HomeStat(
            value: families,
            label: 'أسرة مسجلة',
          ),
          second: HomeStat(
            value: assistances,
            label: 'عملية مساعدة',
          ),
        ),
        const SizedBox(height: 12),
        _StatsRow(
          first: HomeStat(
            value: beneficiaries,
            label: 'أسرة مستفيدة',
          ),
          second: HomeStat(
            value: referrals,
            label: 'إحالة مكتملة',
          ),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  final HomeStat first;
  final HomeStat second;

  const _StatsRow({
    required this.first,
    required this.second,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: HomeStatCard(stat: first),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: HomeStatCard(stat: second),
        ),
      ],
    );
  }
}
