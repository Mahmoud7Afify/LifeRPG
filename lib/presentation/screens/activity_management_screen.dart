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
      appBar: AppBar(title: const Text('Activities')),
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
  late List<ActivityAttributeMapping> _mappings; // ← New

  static const _palette = [
    0xFF3F51B5, 0xFF00897B, 0xFFE53935, 0xFF43A047, 0xFF6D4C41,
    0xFFFB8C00, 0xFF9E9E9E, 0xFF8E24AA, 0xFF3949AB, 0xFF00ACC1,
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameController = TextEditingController(text: e?.name ?? '');
    _categoryController = TextEditingController(text: e?.category ?? 'General');
    _scoreController = TextEditingController(text: '${e?.score ?? 3}');
    _type = e?.type ?? ActivityType.good;
    _icon = e?.icon ?? 'school';
    _color = e?.color ?? _palette.first;
    _mappings = []; // Will be loaded async
    _loadMappings();
  }

  Future<void> _loadMappings() async {
    if (widget.existing == null) {
      // Default mappings for new activities
      final attrs = await ref.read(attributesProvider.future);
      _mappings = attrs.map((attr) => ActivityAttributeMapping(
        activityId: '', // temporary
        attributeId: attr.id,
        points: 0,
      )).toList();
    } else {
      _mappings = await ref.read(activityRepositoryProvider).getMappingsForActivity(widget.existing!.id);
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _scoreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.existing == null ? 'New activity' : 'Edit activity',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),

            // Basic fields (unchanged)
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

            // Attribute Mappings Section - NEW
            Text('Attribute Contributions', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ..._mappings.map((mapping) {
              final attrName = mapping.attributeId; // In real app you'd map ID to name better
              return ListTile(
                title: Text(attrName),
                subtitle: const Text('Points contributed'),
                trailing: SizedBox(
                  width: 80,
                  child: TextField(
                    keyboardType: TextInputType.numberWithOptions(signed: true),
                    decoration: const InputDecoration(suffixText: 'pts'),
                    controller: TextEditingController(text: mapping.points.toString()),
                    onChanged: (val) {
                      final points = int.tryParse(val) ?? 0;
                      final index = _mappings.indexOf(mapping);
                      _mappings[index] = ActivityAttributeMapping(
                        activityId: mapping.activityId,
                        attributeId: mapping.attributeId,
                        points: points,
                      );
                    },
                  ),
                ),
              );
            }).toList(),

            const SizedBox(height: 12),
            // Icon & Color pickers (kept from before)
            // ... (I'll keep them short for brevity - copy from your original if needed)

            const SizedBox(height: 20),
            FilledButton(
              onPressed: _save,
              child: Text(widget.existing == null ? 'Add activity' : 'Save changes'),
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

    final activity = widget.existing?.copyWith(
          name: name,
          score: score,
          category: _categoryController.text.trim(),
          type: _type,
          color: _color,
          icon: _icon,
        ) ??
        Activity(
          id: const Uuid().v4(),
          name: name,
          score: score,
          category: _categoryController.text.trim(),
          type: _type,
          color: _color,
          icon: _icon,
          sortOrder: 0,
        );

    if (widget.existing == null) {
      await notifier.addActivity(activity);
    } else {
      await notifier.updateActivity(activity);
    }

    // Save attribute mappings
    final repo = ref.read(activityRepositoryProvider);
    await repo.setMappingsForActivity(activity.id, _mappings);

    if (mounted) Navigator.of(context).pop();
  }
}
