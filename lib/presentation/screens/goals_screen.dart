import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/goal.dart';
import '../../widgets/icon_registry.dart';
import '../providers/providers.dart';

/// Lets the user set goals for today: check in a specific activity N times,
/// do N good activities in general, or earn N XP today. Progress is live and
/// naturally resets with each new day.
class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(goalProgressProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(context, ref, null),
        child: const Icon(Icons.add),
      ),
      body: progressAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (progressList) {
          if (progressList.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No goals yet. Tap + to set a goal for today — like '
                  '"Study 2 times" or "Earn 50 XP".',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(goalProgressProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: progressList.length,
              itemBuilder: (context, index) {
                final gp = progressList[index];
                return _GoalCard(
                  progress: gp,
                  onTap: () => _openEditor(context, ref, gp.goal),
                  onDelete: () => _delete(context, ref, gp.goal),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Goal goal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete goal?'),
        content: Text('"${goal.title}" will be removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(goalsProvider.notifier).deleteGoal(goal.id);
    }
  }

  void _openEditor(BuildContext context, WidgetRef ref, Goal? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _GoalEditorSheet(existing: existing),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.progress, required this.onTap, required this.onDelete});
  final GoalProgress progress;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  IconData _iconFor(GoalType type) {
    switch (type) {
      case GoalType.activity:
        return Icons.check_circle_outline;
      case GoalType.goodActivities:
        return Icons.thumb_up_outlined;
      case GoalType.xpPoints:
        return Icons.bolt;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final goal = progress.goal;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_iconFor(goal.type), color: scheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(goal.title,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                  ),
                  if (progress.completed)
                    const Icon(Icons.check_circle, color: Colors.green)
                  else
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: onDelete,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress.fraction,
                  minHeight: 12,
                  backgroundColor: scheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(
                      progress.completed ? Colors.green : scheme.primary),
                ),
              ),
              const SizedBox(height: 6),
              Text('${progress.progress} / ${goal.targetValue}',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalEditorSheet extends ConsumerStatefulWidget {
  const _GoalEditorSheet({this.existing});
  final Goal? existing;

  @override
  ConsumerState<_GoalEditorSheet> createState() => _GoalEditorSheetState();
}

class _GoalEditorSheetState extends ConsumerState<_GoalEditorSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _targetController;
  late GoalType _type;
  String? _targetActivityId;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleController = TextEditingController(text: e?.title ?? '');
    _targetController = TextEditingController(text: '${e?.targetValue ?? 1}');
    _type = e?.type ?? GoalType.goodActivities;
    _targetActivityId = e?.targetActivityId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activitiesAsync = ref.watch(activitiesProvider);
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.existing == null ? 'New Goal (today)' : 'Edit Goal',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 16),
            Text('Type', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<GoalType>(
              segments: const [
                ButtonSegment(value: GoalType.goodActivities, label: Text('Good activities')),
                ButtonSegment(value: GoalType.activity, label: Text('Specific activity')),
                ButtonSegment(value: GoalType.xpPoints, label: Text('XP')),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            if (_type == GoalType.activity) ...[
              const SizedBox(height: 12),
              activitiesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, st) => Text('Error: $e'),
                data: (activities) => DropdownButtonFormField<String>(
                  value: _targetActivityId != null &&
                          activities.any((a) => a.id == _targetActivityId)
                      ? _targetActivityId
                      : null,
                  decoration: const InputDecoration(labelText: 'Activity'),
                  items: activities
                      .map((a) => DropdownMenuItem(
                            value: a.id,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(IconRegistry.resolve(a.icon), size: 18, color: Color(a.color)),
                                const SizedBox(width: 8),
                                Text(a.name),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _targetActivityId = v),
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _targetController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: _type == GoalType.xpPoints ? 'Target XP' : 'Target count',
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _save,
              child: Text(widget.existing == null ? 'Create Goal' : 'Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    if (_type == GoalType.activity && _targetActivityId == null) return;
    final target = int.tryParse(_targetController.text.trim()) ?? 1;

    final notifier = ref.read(goalsProvider.notifier);
    final goal = Goal(
      id: widget.existing?.id ?? const Uuid().v4(),
      title: title,
      type: _type,
      targetActivityId: _type == GoalType.activity ? _targetActivityId : null,
      targetValue: target,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );

    if (widget.existing == null) {
      await notifier.addGoal(goal);
    } else {
      await notifier.updateGoal(goal);
    }
    if (mounted) Navigator.of(context).pop();
  }
}
