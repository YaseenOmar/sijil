import 'package:flutter/material.dart';
import 'package:sijil/core/theme/app_colors.dart';
import 'package:sijil/features/sync_center/models/sync_operation.dart';

// Small status pill (color + text, not color only)
class SyncStatusBadge extends StatelessWidget {
  final SyncOperationStatus status;

  const SyncStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: _getBackground(),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          status.label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _getColor(),
          ),
        ),
      ),
    );
  }

  Color _getColor() {
    switch (status) {
      case SyncOperationStatus.pending:
        return AppColors.warning;
      case SyncOperationStatus.synced:
        return AppColors.success;
      case SyncOperationStatus.failed:
        return AppColors.error;
    }
  }

  Color _getBackground() {
    switch (status) {
      case SyncOperationStatus.pending:
        return AppColors.warningBackground;
      case SyncOperationStatus.synced:
        return AppColors.successBackground;
      case SyncOperationStatus.failed:
        return AppColors.errorBackground;
    }
  }
}
