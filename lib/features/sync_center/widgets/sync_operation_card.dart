import 'package:flutter/material.dart';
import 'package:sijil/core/theme/app_colors.dart';
import 'package:sijil/core/widgets/app_button.dart';
import 'package:sijil/features/family_creation/utils/text_utils.dart';
import 'package:sijil/features/sync_center/models/sync_operation.dart';
import 'package:sijil/features/sync_center/widgets/sync_status_badge.dart';

// One operation of the sync queue (presentational only)
class SyncOperationCard extends StatelessWidget {
  final SyncOperation operation;

  // When it is set, a retry button appears (failed attachments)
  final VoidCallback? onRetry;

  const SyncOperationCard({super.key, required this.operation, this.onRetry});

  @override
  Widget build(BuildContext context) {
    // 1 -> ٠١
    final String number = toArabicDigits(
      operation.number.toString().padLeft(2, '0'),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number · ${operation.title}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),

          if (operation.detail != null) ...[
            const SizedBox(height: 8),
            Text(
              operation.detail!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],

          const SizedBox(height: 8),

          SyncStatusBadge(status: operation.status),

          if (operation.note != null) ...[
            const SizedBox(height: 8),
            Text(
              operation.note!,
              style: const TextStyle(
                fontSize: 12,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],

          if (onRetry != null) ...[
            const SizedBox(height: 16),
            AppButton(
              text: 'إعادة محاولة رفع المرفق',
              icon: Icons.refresh,
              type: AppButtonType.secondary,
              onPressed: onRetry,
            ),
          ],
        ],
      ),
    );
  }
}
