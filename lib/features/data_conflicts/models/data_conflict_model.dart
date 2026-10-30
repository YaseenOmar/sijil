// One saved version of the field (who changed it, to what, and when)
class ConflictVersion {
  final String value;
  final String editor;
  final DateTime editedAt;

  const ConflictVersion({
    required this.value,
    required this.editor,
    required this.editedAt,
  });
}

// Two employees edited the same field while offline: the latest edit wins.
// The model does not depend directly on Firebase
class DataConflictModel {
  final String id;
  final String familyName;
  final String organization;
  final String fieldLabel;
  final DateTime detectedAt;

  // Replaced by the latest edit but kept in the audit log
  final ConflictVersion previous;

  // Approved automatically because it is the newest
  final ConflictVersion current;

  const DataConflictModel({
    required this.id,
    required this.familyName,
    required this.organization,
    required this.fieldLabel,
    required this.detectedAt,
    required this.previous,
    required this.current,
  });
}
