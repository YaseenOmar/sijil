import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/demo_context.dart';
import '../models/family_model.dart';

class FamilyRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Families collection for the current organization
  CollectionReference<Map<String, dynamic>> get _families {
    return _firestore
        .collection('organizations')
        .doc(DemoContext.organizationId)
        .collection('families');
  }

  // Add a new family

  Future<void> addFamily(FamilyModel family) async {
    // Check organization
    if (family.organizationId != DemoContext.organizationId) {
      throw Exception('Invalid organization');
    }

    // Check employee
    if (family.createdBy != DemoContext.employeeId) {
      throw Exception('Invalid employee');
    }

    // Check assigned area
    if (!DemoContext.assignedAreaIds.contains(family.areaId)) {
      throw Exception('Area is not assigned to this employee');
    }

    // Check duplicate national ID
    final exists = await familyExists(family.nationalId);

    if (exists) {
      throw Exception('هذه الأسرة مسجلة مسبقاً');
    }

    // Add family to Firestore
    await _families.doc(family.id).set(family.toMap());
  }


  // Get families within the employee's assigned areas
  Future<List<FamilyModel>> getFamilies() async {
    final areaIds = DemoContext.assignedAreaIds;

    if (areaIds.isEmpty) {
      return [];
    }

    final List<FamilyModel> families = [];

    // Firestore whereIn supports up to 30 comparison values
    for (int i = 0; i < areaIds.length; i += 30) {
      final end = (i + 30 < areaIds.length) ? i + 30 : areaIds.length;

      final batch = areaIds.sublist(i, end);

      final snapshot = await _families.where('areaId', whereIn: batch).get();

      families.addAll(
        snapshot.docs.map(
          (doc) => FamilyModel.fromMap({...doc.data(), 'id': doc.id}),
        ),
      );
    }

    return families;
  }

  // Get families from a specific area
  Future<List<FamilyModel>> getFamiliesByArea(String areaId) async {
    if (!DemoContext.assignedAreaIds.contains(areaId)) {
      throw Exception('Area is not assigned to the employee');
    }

    final snapshot = await _families.where('areaId', isEqualTo: areaId).get();

    return snapshot.docs.map((doc) {
      return FamilyModel.fromMap({...doc.data(), 'id': doc.id});
    }).toList();
  }

  // Check for an existing national ID
  Future<bool> familyExists(String nationalId) async {
    final snapshot = await _families
        .where('nationalId', isEqualTo: nationalId.trim())
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }
}
