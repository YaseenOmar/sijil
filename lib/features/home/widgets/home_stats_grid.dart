import 'package:flutter/material.dart';
import 'package:sijil/features/home/widgets/home_stat_card.dart';


/// Four statistic cards arranged as two rows of two.
class HomeStatsGrid extends StatelessWidget {
  const HomeStatsGrid({super.key});

  static const double _gap = 12;

  // Placeholder values until the data is read from Firebase.
  static const List<HomeStat> _stats = [
    HomeStat(value: '١٢٨', label: 'الأسر المسجلة'),
    HomeStat(value: '٨٦', label: 'مساعدات هذا الشهر'),
    HomeStat(value: '٩', label: 'إحالات قيد المتابعة'),
    HomeStat(value: '٢٣', label: 'أسر ذات أولوية'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _StatsRow(first: _stats[0], second: _stats[1]),
        const SizedBox(height: _gap),
        _StatsRow(first: _stats[2], second: _stats[3]),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.first, required this.second});

  final HomeStat first;
  final HomeStat second;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: HomeStatCard(stat: first)),
        const SizedBox(width: HomeStatsGrid._gap),
        Expanded(child: HomeStatCard(stat: second)),
      ],
    );
  }
}
