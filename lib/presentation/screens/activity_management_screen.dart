import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants.dart';
import '../../domain/models/activity.dart';
import '../../domain/models/attribute.dart';
import '../../widgets/icon_registry.dart';
import '../providers/providers.dart';

class ActivityManagementScreen extends ConsumerWidget {
  const ActivityManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(activitiesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Activities Management')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(context, ref, null),
        child: const Icon(Icons.add),
      ),
      body: activitiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (activities) {
          if (activities.isEmpty) {
            return const Center(child: Text('No activities yet. Tap + to add one.'));
          }
          return ReorderableListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: activities.length,
            onReorder: (oldIndex, newIndex) async {
              if (newIndex > oldIndex) newIndex--;
              final reordered = [...activities];
              final item = reordered.removeAt(oldIndex);
              reordered.insert(newIndex, item);
              await ref
                  .read(activitiesProvider.notifier)
                  .reorder(reordered.map((a) => a.id).toList());
            },
            itemBuilder: (context, index) {
              final a = activities[index];
              return ListTile(
                key: ValueKey(a.id),
                leading: CircleAvatar(
                  backgroundColor: Color(a.color).withOpacity(0.2),
                  child: Icon(IconRegistry.resolve(a.icon), color: Color(a.color)),
                ),
                title: Text(a.name),
                subtitle: Text('${a.category} · ${a.type.label} · ${a.score} pts'),
                trailing: PopupMenuButton<String>(
                  onSelected: (choice) async {
                    switch (choice) {
                      case 'edit':
                        _openEditor(context, ref, a);
                        break;
                      case 'archive':
                        await ref.read(activitiesProvider.notifier).archiveActivity(a.id, true);
                        break;
                      case 'delete':
                        final confirmed = await _confirmDelete(context, a.name);
                        if (confirmed) {
                          await ref.read(activitiesProvider.notifier).deleteActivity(a.id);
                        }
                        break;
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'archive', child: Text('Archive')),
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

  Future<bool> _confirmDelete(BuildContext context, String name) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete activity?'),
            content: Text('This removes "$name" but keeps its past logs.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
            ],
          ),
        ) ??
        false;
  }

  void _openEditor(BuildContext context, WidgetRef ref, Activity? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ActivityEditorSheet(existing: existing),
    );
  }
}

class _ActivityEditorSheet extends ConsumerStatefulWidget {
  const _ActivityEditorSheet({this.existing});
  final Activity? existing;

  @override
  ConsumerState<_ActivityEditorSheet> createState() => _ActivityEditorSheetState();
}

class _ActivityEditorSheetState extends ConsumerState<_ActivityEditorSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _categoryController;
  late final TextEditingController _scoreController;
  late ActivityType _type;
  late String _icon;
  late int _color;
  List<ActivityAttributeMapping> _mappings = [];
  List<CharacterAttribute> _allAttributes = [];
  final Map<String, TextEditingController> _mappingControllers = {};
  bool _loading = true;

  static const _palette = [
    0xFF3F51B5, 0xFF00897B, 0xFFE53935, 0xFF43A047, 0xFF6D4C41,
    0xFFFB8C00, 0xFF9E9E9E, 0xFF8E24AA, 0xFF3949AB, 0xFF00ACC1,
    0xFFD81B60, 0xFF5D4037, 0xFF1E88E5, 0xFF7CB342, 0xFFF4511E,
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameController = TextEditingController(text: e?.name ?? '');
    _categoryController = TextEditingController(text: e?.category ?? 'General');
    _scoreController = TextEditingController(text: '${e?.score ?? 5}');
    _type = e?.type ?? ActivityType.good;
    _icon = e?.icon ?? 'school';
    _color = e?.color ?? _palette.first;
    _loadData();
  }

  Future<void> _loadData() async {
    final repo = ref.read(activityRepositoryProvider);
    final attrs = await repo.getAllAttributes();
    _allAttributes = attrs;

    if (widget.existing == null) {
      _mappings = attrs
          .map((attr) => ActivityAttributeMapping(activityId: '', attributeId: attr.id, points: 0))
          .toList();
    } else {
      // Filled-in so newly-added attributes still show a row for existing activities.
      _mappings = await repo.getMappingsFilled(widget.existing!.id);
    }
    for (final m in _mappings) {
      _mappingControllers[m.attributeId] = TextEditingController(text: '${m.points}');
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _scoreController.dispose();
    for (final c in _mappingControllers.values) {
      c.dispose();
    }
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.existing == null ? 'New Activity' : 'Edit Activity',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),

            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 12),
            TextField(controller: _categoryController, decoration: const InputDecoration(labelText: 'Category')),
            const SizedBox(height: 12),
            TextField(
              controller: _scoreController,
              keyboardType: const TextInputType.numberWithOptions(signed: true),
              decoration: const InputDecoration(labelText: 'Base Score'),
            ),
            const SizedBox(height: 12),
            Text('Effect', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<ActivityType>(
              segments: const [
                ButtonSegment(value: ActivityType.good, label: Text('Good')),
                ButtonSegment(value: ActivityType.neutral, label: Text('Neutral')),
                ButtonSegment(value: ActivityType.bad, label: Text('Bad')),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),

            const SizedBox(height: 20),
            Text('Color', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _palette.map((c) {
                final selected = c == _color;
                return InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => setState(() => _color = c),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Color(c),
                    child: selected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),
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
                    backgroundColor: selected ? Color(_color) : Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Icon(
                      IconRegistry.resolve(key),
                      color: selected ? Colors.white : null,
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),
            Text('Character State Effects', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('How much this activity moves each character state, per check-in.',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),

            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_allAttributes.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('No character states yet — add some from the "Character States" tab.'),
              )
            else
              ..._allAttributes.map((attr) {
                final controller = _mappingControllers[attr.id]!;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(attr.name),
                  subtitle: const Text('Points contributed per check-in'),
                  trailing: SizedBox(
                    width: 90,
                    child: TextField(
                      keyboardType: const TextInputType.numberWithOptions(signed: true),
                      decoration: const InputDecoration(suffixText: 'pts'),
                      controller: controller,
                      onChanged: (val) {
                        final points = int.tryParse(val) ?? 0;
                        final index = _mappings.indexWhere((m) => m.attributeId == attr.id);
                        if (index != -1) {
                          _mappings[index] = _mappings[index].copyWith(points: points);
                        }
                      },
                    ),
                  ),
                );
              }),

            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _save,
              child: Text(widget.existing == null ? 'Create Activity' : 'Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final score = int.tryParse(_scoreController.text.trim()) ?? 0;
    final notifier = ref.read(activitiesProvider.notifier);
    final repo = ref.read(activityRepositoryProvider);

    final newActivity = widget.existing?.copyWith(
      name: name,
      score: score,
      category: _categoryController.text.trim(),
      type: _type,
      color: _color,
      icon: _icon,
    ) ?? Activity(
      id: const Uuid().v4(),
      name: name,
      score: score,
      category: _categoryController.text.trim(),
      type: _type,
      color: _color,
      icon: _icon,
    );

    final activityId = newActivity.id;

    if (widget.existing == null) {
      await notifier.addActivity(newActivity);
    } else {
      await notifier.updateActivity(newActivity);
    }

    final updatedMappings = _mappings
        .map((m) => ActivityAttributeMapping(
              activityId: activityId,
              attributeId: m.attributeId,
              points: m.points,
            ))
        .toList();

    await repo.setMappingsForActivity(activityId, updatedMappings);

    if (mounted) Navigator.of(context).pop();
  }
}
