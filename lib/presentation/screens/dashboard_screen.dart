import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(statsProvider.notifier).refresh();
        await ref.read(attributesProvider.notifier).refresh();
        ref.invalidate(recentLogsProvider);
      },
      child: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (stats) {
          // "Today" is the primary XP/level shown — it resets every day.
          final todayXp = XpService().describeXp(stats.todayXp);
          final ratio = (stats.todayGoodPoints + stats.todayBadPoints) == 0
              ? 0.5
              : stats.todayGoodPoints /
                  (stats.todayGoodPoints + stats.todayBadPoints);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Today's XP Progress
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Today", style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 8),
                      XpProgressBar(result: todayXp),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Today's Stats Grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.6,
                children: [
                  StatCard(label: "Today's Points", value: '${stats.todayPoints}', icon: Icons.today),
                  StatCard(label: "Today's XP", value: '${stats.todayXp}', icon: Icons.bolt),
                  StatCard(
                    label: 'Current Streak',
                    value: '${stats.currentStreakDays} days',
                    icon: Icons.local_fire_department,
                    color: Colors.deepOrange,
                  ),
                  StatCard(label: 'Total Check-Ins', value: '${stats.totalCheckIns}', icon: Icons.check_circle),
                ],
              ),

              const SizedBox(height: 24),

              // === Best Day Records ===
              Text('Best Day Records', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                stats.bestDayDate != null
                    ? 'Set on ${DateFormat('MMM d, y').format(stats.bestDayDate!)}'
                    : 'Keep checking in to set your first record!',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.0,
                children: [
                  StatCard(
                    label: 'Best XP',
                    value: '${stats.bestDayXp > stats.todayXp ? stats.bestDayXp : stats.todayXp}',
                    icon: Icons.bolt,
                    color: Colors.amber.shade800,
                  ),
                  StatCard(
                    label: 'Best Level',
                    value: '${stats.bestDayLevel > stats.todayLevel ? stats.bestDayLevel : stats.todayLevel}',
                    icon: Icons.military_tech,
                    color: Colors.amber.shade800,
                  ),
                  StatCard(
                    label: 'Best Points',
                    value: '${stats.bestDayPoints > stats.todayPoints ? stats.bestDayPoints : stats.todayPoints}',
                    icon: Icons.stacked_line_chart,
                    color: Colors.amber.shade800,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Overall (lifetime) totals
              Text('Overall Run', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.6,
                children: [
                  StatCard(label: 'Lifetime XP', value: '${stats.totalXp}', icon: Icons.auto_graph),
                  StatCard(label: 'Lifetime Level', value: '${stats.level}', icon: Icons.emoji_events),
                ],
              ),

              const SizedBox(height: 24),

              // Productive vs Unproductive (today)
              Text('Productive vs Unproductive (today)', style: Theme.of(context).textTheme.titleMedium),
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
                          valueColor: const AlwaysStoppedAnimation(Colors.green),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('${(ratio * 100).toStringAsFixed(0)}% productive'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Recent Points Chart
              Text('Points, last 7 check-ins', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              logsAsync.when(
                loading: () => const SizedBox(
                  height: 160,
                  child: Center(child: CircularProgressIndicator()),
                ),
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
    );
  }
}
