
class FamilyModel {
  final String id;
  final String headName;
  final String nationalId;
  final String phoneNumber;
  final int membersCount;
  final String address;
  final String housingStatus;
  final String? idCardImagePath;
  final List<String> needs;

  // Relationships
  final String areaId;
  final String createdBy;
  final String organizationId;

  const FamilyModel({
    required this.id,
    required this.headName,
    required this.nationalId,
    required this.phoneNumber,
    required this.membersCount,
    required this.address,
    required this.housingStatus,
    this.idCardImagePath,
    required this.needs,
    required this.areaId,
    required this.createdBy,
    required this.organizationId,
  });

  // Convert FamilyModel to Firestore Map
  Map<String, dynamic> toMap() {
    return {
      'headName': headName,
      'nationalId': nationalId.trim(),
      'phoneNumber': phoneNumber,
      'membersCount': membersCount,
      'address': address,
      'housingStatus': housingStatus,
      'idCardImagePath': idCardImagePath,
      'needs': needs,
      'areaId': areaId,
      'createdBy': createdBy,
      'organizationId': organizationId,
    };
  }

  // Convert Firestore Map to FamilyModel
  factory FamilyModel.fromMap(Map<String, dynamic> map) {
    return FamilyModel(
      id: map['id'] as String,
      headName: map['headName'] as String,
      nationalId: (map['nationalId'] as String).trim(),
      phoneNumber: map['phoneNumber'] as String,
      membersCount: (map['membersCount'] as num).toInt(),
      address: map['address'] as String,
      housingStatus: map['housingStatus'] as String,
      idCardImagePath: map['idCardImagePath'] as String?,
      needs: List<String>.from(map['needs'] ?? []),
      areaId: map['areaId'] as String,
      createdBy: map['createdBy'] as String,
      organizationId: map['organizationId'] as String,
    );
  }
}
