
class ReceivedFamilyModel {
  final String id;

  // Original family identity
  final String sourceOrganizationId;
  final String sourceFamilyId;

  // Receiving organization
  final String targetOrganizationId;

  // Family information
  final String headName;
  final int membersCount;
  final String phoneNumber;
  final String address;
  final String areaId;

  // First accepted referral
  final String firstReferralId;
  final DateTime receivedAt;

  // Last update
  final DateTime updatedAt;

  const ReceivedFamilyModel({
    required this.id,
    required this.sourceOrganizationId,
    required this.sourceFamilyId,
    required this.targetOrganizationId,
    required this.headName,
    required this.membersCount,
    required this.phoneNumber,
    required this.address,
    required this.areaId,
    required this.firstReferralId,
    required this.receivedAt,
    required this.updatedAt,
  });

  ReceivedFamilyModel copyWith({
    String? headName,
    int? membersCount,
    String? phoneNumber,
    String? address,
    DateTime? updatedAt,
  }) {
    return ReceivedFamilyModel(
      id: id,
      sourceOrganizationId: sourceOrganizationId,
      sourceFamilyId: sourceFamilyId,
      targetOrganizationId: targetOrganizationId,
      headName: headName ?? this.headName,
      membersCount: membersCount ?? this.membersCount,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      areaId: areaId,
      firstReferralId: firstReferralId,
      receivedAt: receivedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
