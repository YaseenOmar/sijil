import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';

import 'add_staff_screen.dart';
import 'edit_staff_screen.dart';

class StaffSection extends StatelessWidget {
  late final String organizationId;
  late final String currentUserId;

   StaffSection({
    required this.organizationId,
    required this.currentUserId,
  });

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // -------------------------------
  // Status translation
  // -------------------------------

  String _statusName(String status) {
    switch (status) {
      case 'active':
        return 'نشط';
      case 'pending':
        return 'بانتظار القبول';
      case 'inactive':
        return 'غير نشط';
      default:
        return 'غير محدد';
    }
  }

  Color _statusBackground(String status) {
    switch (status) {
      case 'active':
        return const Color(0xFFE6F4EA);
      case 'pending':
        return const Color(0xFFFFF3CD);
      default:
        return const Color(0xFFF1F2F4);
    }
  }

  Color _statusTextColor(String status) {
    switch (status) {
      case 'active':
        return const Color(0xFF137333);
      case 'pending':
        return const Color(0xFF856404);
      default:
        return const Color(0xFF606874);
    }
  }

  String _roleName(String role) {
    switch (role) {
      case 'field_worker':
        return 'موظف ميداني';
      case 'supervisor':
        return 'مشرف';
      case 'manager':
        return 'مدير الجهة';
      default:
        return 'غير محدد';
    }
  }

  // -------------------------------
  // Build employee list
  // -------------------------------

  Widget _buildStaffList(
      BuildContext context,
      List<QueryDocumentSnapshot<Map<String, dynamic>>>
      invitations,
      List<QueryDocumentSnapshot<Map<String, dynamic>>>
      users,
      List<QueryDocumentSnapshot<Map<String, dynamic>>>
      areaDocuments,
      ) {
    // Map area IDs to their actual names.
    final Map<String, String> areaNames = {};

    for (final area in areaDocuments) {
      final name = area.data()['name'];

      areaNames[area.id] =
      name is String && name.trim().isNotEmpty
          ? name
          : area.id;
    }

    // Unified list for both collections.
    final List<Map<String, dynamic>> employees = [];

    // 1. Actual registered users.
    for (final user in users) {
      // Exclude the currently signed-in supervisor.
      if (user.id == currentUserId) continue;

      final data = user.data();

      employees.add({
        'id': user.id,
        'data': data,
        'isPendingInvitation': false,
      });
    }

    // 2. Pending invitations.
    for (final invitation in invitations) {
      final data = invitation.data();

      // Only show invitations that are still pending.
      if (data['status'] != 'pending') continue;

      employees.add({
        'id': invitation.id,
        'data': data,
        'isPendingInvitation': true,
      });
    }

    // Sort employees alphabetically by name.
    employees.sort((a, b) {
      final nameA =
          a['data']['fullName'] as String? ?? '';

      final nameB =
          b['data']['fullName'] as String? ?? '';

      return nameA.compareTo(nameB);
    });

    // -------------------------------
    // Calculate counts
    // -------------------------------

    final activeCount = employees.where((employee) {
      return employee['data']['status'] == 'active';
    }).length;

    final pendingCount = employees.where((employee) {
      return employee['data']['status'] == 'pending';
    }).length;

    final inactiveCount = employees.where((employee) {
      return employee['data']['status'] == 'inactive';
    }).length;

    // -------------------------------
    // UI
    // -------------------------------

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'الفريق • ${employees.length} موظفين',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A202C),
                ),
              ),
            ),

            TextButton.icon(
              onPressed: () {
                Get.to(() => AddStaffScreen());
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

        const SizedBox(height: 4),

        Text(
          'النشطون: $activeCount  •  '
              'غير النشطين: $inactiveCount  •  '
              'بانتظار القبول: $pendingCount',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),

        const SizedBox(height: 12),

        if (employees.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'لا يوجد موظفون مسجلون حاليًا',
              textAlign: TextAlign.center,
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics:
            const NeverScrollableScrollPhysics(),
            itemCount: employees.length,
            separatorBuilder: (_, __) =>
            const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final employee = employees[index];

              final String employeeId =
              employee['id'] as String;

              final bool isPending =
              employee['isPendingInvitation'] as bool;

              final data =
              employee['data'] as Map<String, dynamic>;

              final name =
                  data['fullName'] as String? ?? '';

              final role =
                  data['role'] as String? ?? '';

              final areaId =
                  data['areaId'] as String? ?? '';

              final status =
                  data['status'] as String? ?? '';

              final roleName = _roleName(role);

              final areaName =
                  areaNames[areaId] ?? 'منطقة غير محددة';

              return InkWell(
                borderRadius: BorderRadius.circular(12),

                // Navigate using the document ID and its source.
                onTap: () {
                  Get.to(
                        () => EditStaffScreen(
                      employeeId: employeeId,
                      isPendingInvitation: isPending,
                    ),
                  );
                },

                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A202C),
                              ),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              '$roleName • $areaName',
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
                          color: _statusBackground(status),
                          borderRadius:
                          BorderRadius.circular(8),
                        ),
                        child: Text(
                          _statusName(status),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _statusTextColor(status),
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
      ],
    );
  }

  // -------------------------------
  // Main build
  // -------------------------------

  @override
  Widget build(BuildContext context) {
    if (organizationId.isEmpty) {
      return const Center(
        child: Text('لم يتم تحديد المؤسسة'),
      );
    }

    // Invitations collection.
    final invitationsStream = _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('employees')
        .where('status', isEqualTo: 'pending')
        .snapshots();

    // Actual users collection.
    final usersStream = _firestore
        .collection('users')
        .where(
      'organizationId',
      isEqualTo: organizationId,
    )
        .snapshots();

    // Organization areas.
    final areasStream = _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('areas')
        .snapshots();

    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: invitationsStream,
      builder: (context, invitationSnapshot) {
        if (invitationSnapshot.hasError) {
          return const Text(
            'تعذر تحميل الدعوات المعلقة',
            style: TextStyle(color: Colors.red),
          );
        }

        if (!invitationSnapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return StreamBuilder<
            QuerySnapshot<Map<String, dynamic>>>(
          stream: usersStream,
          builder: (context, usersSnapshot) {
            if (usersSnapshot.hasError) {
              return const Text(
                'تعذر تحميل حسابات الموظفين',
                style: TextStyle(color: Colors.red),
              );
            }

            if (!usersSnapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            return StreamBuilder<
                QuerySnapshot<Map<String, dynamic>>>(
              stream: areasStream,
              builder: (context, areasSnapshot) {
                if (areasSnapshot.hasError) {
                  return const Text(
                    'تعذر تحميل المناطق',
                    style: TextStyle(color: Colors.red),
                  );
                }

                if (!areasSnapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                return _buildStaffList(
                  context,
                  invitationSnapshot.data!.docs,
                  usersSnapshot.data!.docs,
                  areasSnapshot.data!.docs,
                );
              },
            );
          },
        );
      },
    );
  }
}
