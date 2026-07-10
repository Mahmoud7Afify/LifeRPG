import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/xp_service.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/xp_progress_bar.dart';
import '../providers/providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsProvider);
    final logsAsync = ref.watch(recentLogsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(statsProvider.notifier).refresh();
          ref.invalidate(recentLogsProvider);
        },
        child: statsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text('Error: $e')),
          data: (stats) {
            final xp = XpService().describeXp(stats.totalXp);
            final ratio = (stats.overallGoodPoints + stats.overallBadPoints) == 0
                ? 0.5
                : stats.overallGoodPoints /
                    (stats.overallGoodPoints + stats.overallBadPoints);

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: XpProgressBar(result: xp),
                  ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.6,
                  children: [
                    StatCard(
                      label: "Today's Points",
                      value: '${stats.todayPoints}',
                      icon: Icons.today,
                    ),
                    StatCard(
                      label: 'Overall Points',
                      value: '${stats.overallPoints}',
                      icon: Icons.stacked_line_chart,
                    ),
                    StatCard(
                      label: 'Current Streak',
                      value: '${stats.currentStreakDays} days',
                      icon: Icons.local_fire_department,
                      color: Colors.deepOrange,
                    ),
                    StatCard(
                      label: 'Total Check-Ins',
                      value: '${stats.totalCheckIns}',
                      icon: Icons.check_circle,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text('Productive vs Unproductive',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: ratio,
                            minHeight: 14,
                            backgroundColor: Colors.red.withOpacity(0.25),
                            valueColor:
                                const AlwaysStoppedAnimation(Colors.green),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('${(ratio * 100).toStringAsFixed(0)}% productive'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Points, last 7 check-ins',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                logsAsync.when(
                  loading: () => const SizedBox(
                      height: 160, child: Center(child: CircularProgressIndicator())),
                  error: (e, st) => Text('Error: $e'),
                  data: (logs) {
                    final recent = logs.take(7).toList().reversed.toList();
                    if (recent.isEmpty) {
                      return const SizedBox(
                        height: 160,
                        child: Center(child: Text('No check-ins yet')),
                      );
                    }
                    return SizedBox(
                      height: 200,
                      child: LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: false),
                          titlesData: const FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              isCurved: true,
                              color: Theme.of(context).colorScheme.primary,
                              barWidth: 3,
                              dotData: const FlDotData(show: true),
                              spots: [
                                for (var i = 0; i < recent.length; i++)
                                  FlSpot(i.toDouble(), recent[i].score.toDouble()),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
