enum SyncOperationStatus {
  pending, // saved on the device, waiting for the server
  synced, // confirmed by the server
  failed, // the last try failed and can be retried
}

extension SyncOperationStatusLabel on SyncOperationStatus {
  String get label {
    switch (this) {
      case SyncOperationStatus.pending:
        return 'بانتظار المزامنة';
      case SyncOperationStatus.synced:
        return 'تمت المزامنة';
      case SyncOperationStatus.failed:
        return 'تعذّر الإرسال';
    }
  }
}

// One saved operation in the local queue (the model does not depend on Firebase)
class SyncOperation {
  final String id;
  final int number;
  final String title;

  // Line above the status badge
  final String? detail;

  // Line under the status badge (ex: why it failed)
  final String? note;

  final SyncOperationStatus status;

  // Attachments (ID photo, receipt proof) need more time to upload
  final bool isAttachment;

  const SyncOperation({
    required this.id,
    required this.number,
    required this.title,
    required this.status,
    this.detail,
    this.note,
    this.isAttachment = false,
  });
}
