import 'package:flutter/material.dart';
import 'package:sijil/core/theme/app_colors.dart';

/// "Assigned area" label with the neighborhood badge.
class HomeAreaRow extends StatelessWidget {
  const HomeAreaRow({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _AreaLabel(),
        _AreaBadge(name: 'حي النور'),
      ],
    );
  }
}

class _AreaLabel extends StatelessWidget {
  const _AreaLabel();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(
          Icons.location_on_outlined,
          size: 20,
          color: AppColors.textSecondary,
        ),
        SizedBox(width: 6),
        Text(
          'منطقتك المكلّف بها',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _AreaBadge extends StatelessWidget {
  const _AreaBadge({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.successBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        name,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.success,
        ),
      ),
    );
  }
}
