class AssistanceRecord {
  final String id;
  final String beneficiaryId;
  final String beneficiaryName;
  final String assistanceType;
  final String quantity;
  final DateTime deliveryDate;
  final String officerName;
  final String area;
  final String status; // 'pending' أو 'synced'
  final String proofType; // 'signature' أو 'photo'
  final String? notes;

  AssistanceRecord({
    required this.id,
    required this.beneficiaryId,
    required this.beneficiaryName,
    required this.assistanceType,
    required this.quantity,
    required this.deliveryDate,
    required this.officerName,
    required this.area,
    this.status = 'pending',
    required this.proofType,
    this.notes,
  });
}
