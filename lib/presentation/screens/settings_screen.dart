import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/database/db_helper.dart';
import '../../data/repositories/log_repository.dart';
import '../../services/notification_service.dart';
import '../providers/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final intervalAsync = ref.watch(checkInIntervalProvider);
    final darkModeAsync = ref.watch(darkModeProvider);
    final defaultMaxAsync = ref.watch(defaultAttributeMaxProvider);
    final settingsRepo = ref.read(settingsRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _SectionHeader('Check-Ins'),
          intervalAsync.when(
            loading: () => const ListTile(title: Text('Loading...')),
            error: (e, st) => ListTile(title: Text('Error: $e')),
            data: (minutes) => ListTile(
              title: const Text('Reminder interval'),
              subtitle: Text('Every $minutes minutes'),
              trailing: DropdownButton<int>(
                value: minutes,
                items: const [5, 10, 15, 20, 30, 45, 60]
                    .map((m) => DropdownMenuItem(value: m, child: Text('$m min')))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    ref.read(checkInIntervalProvider.notifier).setInterval(v);
                  }
                },
              ),
            ),
          ),
          FutureBuilder<bool>(
            future: settingsRepo.getNotifSound(),
            builder: (context, snap) => SwitchListTile(
              title: const Text('Notification sound'),
              value: snap.data ?? true,
              onChanged: (v) async {
                await settingsRepo.setNotifSound(v);
                (context as Element).markNeedsBuild();
              },
            ),
          ),
          FutureBuilder<bool>(
            future: settingsRepo.getNotifVibration(),
            builder: (context, snap) => SwitchListTile(
              title: const Text('Vibration'),
              value: snap.data ?? true,
              onChanged: (v) async {
                await settingsRepo.setNotifVibration(v);
                (context as Element).markNeedsBuild();
              },
            ),
          ),
          ListTile(
            title: const Text('Snooze current reminder'),
            subtitle: const Text('5, 10, or 30 minutes'),
            trailing: PopupMenuButton<int>(
              onSelected: (m) => NotificationService.instance.snooze(m),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 5, child: Text('5 min')),
                PopupMenuItem(value: 10, child: Text('10 min')),
                PopupMenuItem(value: 30, child: Text('30 min')),
              ],
              child: const Icon(Icons.snooze),
            ),
          ),
          const Divider(),
          const _SectionHeader('Appearance'),
          darkModeAsync.when(
            loading: () => const ListTile(title: Text('Loading...')),
            error: (e, st) => ListTile(title: Text('Error: $e')),
            data: (dark) => SwitchListTile(
              title: const Text('Dark mode'),
              value: dark,
              onChanged: (_) => ref.read(darkModeProvider.notifier).toggle(),
            ),
          ),
          const Divider(),
          const _SectionHeader('Character States'),
          defaultMaxAsync.when(
            loading: () => const ListTile(title: Text('Loading...')),
            error: (e, st) => ListTile(title: Text('Error: $e')),
            data: (maxValue) => ListTile(
              title: const Text('Default max value'),
              subtitle: const Text('Used as the starting target for new character states'),
              trailing: DropdownButton<int>(
                value: maxValue,
                items: const [10, 25, 50, 100, 200, 500, 1000]
                    .map((m) => DropdownMenuItem(value: m, child: Text('$m')))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    ref.read(defaultAttributeMaxProvider.notifier).setValue(v);
                  }
                },
              ),
            ),
          ),
          const Divider(),
          const _SectionHeader('Data'),
          ListTile(
            leading: const Icon(Icons.file_download_outlined),
            title: const Text('Export CSV'),
            subtitle: const Text('Export all check-in logs'),
            onTap: () => _exportCsv(context),
          ),
          ListTile(
            leading: const Icon(Icons.restore_page_outlined),
            title: const Text('Reset statistics'),
            subtitle: const Text('Clears logs, XP, streaks, and achievements'),
            onTap: () => _confirmReset(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _exportCsv(BuildContext context) async {
    final logs = await LogRepository().getAll();
    final rows = <List<dynamic>>[
      ['timestamp', 'activity_id', 'custom_name', 'score', 'type', 'notes'],
      for (final l in logs)
        [
          l.timestamp.toIso8601String(),
          l.activityId ?? '',
          l.customName ?? '',
          l.score,
          l.type.name,
          l.notes ?? '',
        ],
    ];
    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/life_rpg_export.csv');
    await file.writeAsString(csv, encoding: utf8);
    if (context.mounted) {
      await Share.shareXFiles([XFile(file.path)], text: 'Life RPG export');
    }
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset all statistics?'),
        content: const Text(
            'This deletes all check-in logs, XP, streaks, and achievement progress. '
            'Your activities themselves are kept. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Reset')),
        ],
      ),
    );
    if (confirmed == true) {
      await DBHelper.instance.resetAllData();
      await ref.read(statsProvider.notifier).refresh();
      ref.invalidate(recentLogsProvider);
      ref.invalidate(achievementsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Statistics reset.')));
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}
