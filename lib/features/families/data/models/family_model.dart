
class FamilyModel {
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
}
