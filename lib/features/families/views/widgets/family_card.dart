
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/family_model.dart';

class FamilyCard extends StatelessWidget {
  final FamilyModel family;
  final VoidCallback onTap;
  final String areaName;

  const FamilyCard({
    super.key,
    required this.family,
    required this.onTap,
    this.areaName = '',
  });

  String _maskedNationalId(String nationalId) {
    final id = nationalId.trim();

    if (id.isEmpty) return 'غير متوفر';

    if (id.length <= 4) {
      return '••••';
    }

    return '•••••${id.substring(id.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    final housingStatus = family.housingStatus.trim();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: 20,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.border,
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  // Family icon - right side
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary
                          .withValues(alpha: 0.10),
                      borderRadius:
                      BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.groups_outlined,
                      color: AppColors.primary,
                      size: 25,
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Family details
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          family.headName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),

                        const SizedBox(height: 7),

                        Wrap(
                          crossAxisAlignment:
                          WrapCrossAlignment.center,
                          spacing: 6,
                          runSpacing: 5,
                          children: [
                            Text(
                              'الهوية: ${family.nationalId}',
                              textDirection: TextDirection.rtl,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const Text(
                              '·',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              '${family.membersCount} أفراد',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),

                        if (housingStatus.isNotEmpty) ...[

                          const SizedBox(height: 13),

                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              // Area name
                              if (areaName.trim().isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    areaName,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              // Housing status
                              if (family.housingStatus.trim().isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'حالة السكن: ${family.housingStatus}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),

                              // Full phone number
                              if (family.phoneNumber.trim().isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    family.phoneNumber,
                                    textDirection: TextDirection.ltr,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                            ],
                          ),

                        ],
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Open details arrow - left side
                  const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Icon(
                      Icons.chevron_right,
                      size: 24,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
