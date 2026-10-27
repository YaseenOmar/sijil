import 'package:flutter/material.dart';
import 'package:sijil/core/widgets/custom_app_bar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/family_model.dart';

class FamilyDetailScreen extends StatelessWidget {
  final FamilyModel family;

  const FamilyDetailScreen({super.key, required this.family});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: CustomAppBar(
          title: 'ملف الأسرة',
          leading: Icons.arrow_back,
          onLeadingPressed: () => Navigator.of(context).pop(),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // كرت اسم الأسرة العلوي
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F3EE),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      family.headName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${family.membersCount} أفراد · حي النور',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary.withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3CD),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        family.housingStatus.isNotEmpty
                            ? family.housingStatus
                            : 'تمت المزامنة',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF856404),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // كرت بيانات الأسرة
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'بيانات الأسرة',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.right,
                    ),
                    const Divider(height: 24),

                    _buildDetailRow('رقم الجوال', family.phoneNumber),
                    const SizedBox(height: 12),

                    _buildDetailRow('رقم الهوية', family.nationalId),
                    const SizedBox(height: 12),

                    _buildDetailRow(
                      'السكن',
                      '${family.housingStatus} · ${family.membersCount} أفراد',
                    ),
                    const SizedBox(height: 12),

                    _buildDetailRow('العنوان التفصيلي', family.address),
                    const SizedBox(height: 16),

                    const Text(
                      'الاحتياجات المسجلة',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 8),
                    if (family.needs.isEmpty)
                      const Text(
                        'لا توجد احتياجات مسجلة',
                        style: TextStyle(fontSize: 13),
                        textAlign: TextAlign.right,
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.start,
                        children: family.needs.map((need) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.neutralBackground,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              need,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          textAlign: TextAlign.right,
        ),
        const SizedBox(height: 2),
        Text(
          value.isNotEmpty ? value : 'غير محدد',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.right,
        ),
      ],
    );
  }
}
