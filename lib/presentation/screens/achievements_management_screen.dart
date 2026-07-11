import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/achievement.dart';
import '../../widgets/icon_registry.dart';
import '../providers/providers.dart';

class AchievementsManagementScreen extends ConsumerWidget {
  const AchievementsManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(achievementsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Achievements Management')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(context, ref, null),
        child: const Icon(Icons.add),
      ),
      body: achievementsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (achievements) {
          if (achievements.isEmpty) {
            return const Center(child: Text('No achievements yet. Tap + to add one.'));
          }
          return ListView.builder(
            itemCount: achievements.length,
            itemBuilder: (context, index) {
              final a = achievements[index];
              return ListTile(
                leading: CircleAvatar(child: Icon(IconRegistry.resolve(a.icon))),
                title: Text(a.title),
                subtitle: Text(
                  '${_triggerLabel(a.triggerType)} · target ${a.targetValue}'
                  '${a.targetActivityName != null ? ' · ${a.targetActivityName}' : ''}'
                  '${a.unlocked ? ' · Unlocked' : ''}',
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (choice) async {
                    switch (choice) {
                      case 'edit':
                        _openEditor(context, ref, a);
                        break;
                      case 'delete':
                        final confirmed = await _confirmDelete(context, a.title);
                        if (confirmed) {
                          await ref.read(statsRepositoryProvider).deleteAchievement(a.id);
                          ref.invalidate(achievementsProvider);
                        }
                        break;
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _triggerLabel(AchievementTriggerType t) {
    switch (t) {
      case AchievementTriggerType.totalXp:
        return 'Total XP';
      case AchievementTriggerType.totalCheckIns:
        return 'Total Check-Ins';
      case AchievementTriggerType.activityCount:
        return 'Activity Count';
      case AchievementTriggerType.dailyStreak:
        return 'Daily Streak';
      case AchievementTriggerType.productivePoints:
        return 'Productive Points';
      case AchievementTriggerType.abstinenceStreak:
        return 'Abstinence Streak';
      case AchievementTriggerType.bestDayXp:
        return 'Best Day XP';
      case AchievementTriggerType.bestDayLevel:
        return 'Best Day Level';
      case AchievementTriggerType.bestDayPoints:
        return 'Best Day Points';
    }
  }

  Future<bool> _confirmDelete(BuildContext context, String title) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete achievement?'),
            content: Text('"$title" will be permanently removed.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
            ],
          ),
        ) ??
        false;
  }

  void _openEditor(BuildContext context, WidgetRef ref, Achievement? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AchievementEditorSheet(existing: existing),
    );
  }
}

class _AchievementEditorSheet extends ConsumerStatefulWidget {
  const _AchievementEditorSheet({this.existing});
  final Achievement? existing;

  @override
  ConsumerState<_AchievementEditorSheet> createState() => _AchievementEditorSheetState();
}

class _AchievementEditorSheetState extends ConsumerState<_AchievementEditorSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _targetController;
  late final TextEditingController _targetActivityController;
  late AchievementTriggerType _triggerType;
  late String _icon;

  bool get _needsActivityName =>
      _triggerType == AchievementTriggerType.activityCount ||
      _triggerType == AchievementTriggerType.abstinenceStreak;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleController = TextEditingController(text: e?.title ?? '');
    _descriptionController = TextEditingController(text: e?.description ?? '');
    _targetController = TextEditingController(text: '${e?.targetValue ?? 10}');
    _targetActivityController = TextEditingController(text: e?.targetActivityName ?? '');
    _triggerType = e?.triggerType ?? AchievementTriggerType.totalXp;
    _icon = e?.icon ?? 'flag';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetController.dispose();
    _targetActivityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.existing == null ? 'New Achievement' : 'Edit Achievement',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 12),
            TextField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Description')),
            const SizedBox(height: 16),

            Text('Type', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            DropdownButtonFormField<AchievementTriggerType>(
              value: _triggerType,
              items: AchievementTriggerType.values
                  .map((t) => DropdownMenuItem(value: t, child: Text(_labelFor(t))))
                  .toList(),
              onChanged: (v) => setState(() => _triggerType = v ?? _triggerType),
            ),
            const SizedBox(height: 4),
            Text(
              _triggerType.isDaily
                  ? 'Daily: unlocks once any single day ever reaches this.'
                  : 'Overall: unlocks once your lifetime total reaches this.',
              style: Theme.of(context).textTheme.bodySmall,
            ),

            const SizedBox(height: 12),
            TextField(
              controller: _targetController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Target value'),
            ),

            if (_needsActivityName) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _targetActivityController,
                decoration: const InputDecoration(labelText: 'Activity name'),
              ),
            ],

            const SizedBox(height: 16),
            Text('Icon', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: IconRegistry.allKeys.map((key) {
                final selected = key == _icon;
                return InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => setState(() => _icon = key),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: selected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Icon(
                      IconRegistry.resolve(key),
                      color: selected ? Theme.of(context).colorScheme.onPrimary : null,
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),
            FilledButton(
              onPressed: _save,
              child: Text(widget.existing == null ? 'Create Achievement' : 'Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  String _labelFor(AchievementTriggerType t) {
    switch (t) {
      case AchievementTriggerType.totalXp:
        return 'Total XP (overall)';
      case AchievementTriggerType.totalCheckIns:
        return 'Total Check-Ins (overall)';
      case AchievementTriggerType.activityCount:
        return 'Activity Count (overall)';
      case AchievementTriggerType.dailyStreak:
        return 'Daily Streak (overall)';
      case AchievementTriggerType.productivePoints:
        return 'Productive Points (overall)';
      case AchievementTriggerType.abstinenceStreak:
        return 'Abstinence Streak (overall)';
      case AchievementTriggerType.bestDayXp:
        return 'Best Day XP (daily)';
      case AchievementTriggerType.bestDayLevel:
        return 'Best Day Level (daily)';
      case AchievementTriggerType.bestDayPoints:
        return 'Best Day Points (daily)';
    }
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    final target = int.tryParse(_targetController.text.trim()) ?? 1;
    final targetActivityName =
        _needsActivityName && _targetActivityController.text.trim().isNotEmpty
            ? _targetActivityController.text.trim()
            : null;

    final repo = ref.read(statsRepositoryProvider);
    final achievement = Achievement(
      id: widget.existing?.id ?? const Uuid().v4(),
      title: title,
      description: _descriptionController.text.trim(),
      icon: _icon,
      triggerType: _triggerType,
      targetValue: target,
      targetActivityName: targetActivityName,
      unlocked: widget.existing?.unlocked ?? false,
      unlockedAt: widget.existing?.unlockedAt,
    );
    await repo.upsertAchievement(achievement);
    ref.invalidate(achievementsProvider);

    if (mounted) Navigator.of(context).pop();
  }
}
