import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/attribute.dart';
import '../providers/providers.dart';

/// Shows every character attribute ("Knowledge", "Discipline", ...) with a
/// progress bar out of a user-editable max value. Attributes can be added,
/// renamed, deleted, and have their max value adjusted right here.
class CharacterStatesScreen extends ConsumerWidget {
  const CharacterStatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attributesAsync = ref.watch(attributesProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(context, ref, null),
        child: const Icon(Icons.add),
      ),
      body: attributesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (attributes) {
          if (attributes.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No character states yet. Tap + to add one, like '
                  '"Knowledge" or "Discipline".',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(attributesProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: attributes.length,
              itemBuilder: (context, index) {
                final attr = attributes[index];
                return _AttributeCard(
                  attribute: attr,
                  onTap: () => _openEditor(context, ref, attr),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _openEditor(BuildContext context, WidgetRef ref, CharacterAttribute? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AttributeEditorSheet(existing: existing),
    );
  }
}

class _AttributeCard extends StatelessWidget {
  const _AttributeCard({required this.attribute, required this.onTap});
  final CharacterAttribute attribute;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fraction = attribute.maxValue <= 0
        ? 0.0
        : (attribute.totalPoints / attribute.maxValue).clamp(0.0, 1.0);

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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(attribute.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  Text('${attribute.totalPoints} / ${attribute.maxValue}',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: fraction,
                  minHeight: 12,
                  backgroundColor: scheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(scheme.primary),
                ),
              ),
              const SizedBox(height: 6),
              Text('+${attribute.todayPoints} today',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttributeEditorSheet extends ConsumerStatefulWidget {
  const _AttributeEditorSheet({this.existing});
  final CharacterAttribute? existing;

  @override
  ConsumerState<_AttributeEditorSheet> createState() => _AttributeEditorSheetState();
}

class _AttributeEditorSheetState extends ConsumerState<_AttributeEditorSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _maxController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _maxController =
        TextEditingController(text: '${widget.existing?.maxValue ?? 100}');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.existing == null;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(isNew ? 'New Character State' : 'Edit Character State',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _maxController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Max value (the "out of" number)'),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _save,
            child: Text(isNew ? 'Create' : 'Save Changes'),
          ),
          if (!isNew) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              label: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final max = int.tryParse(_maxController.text.trim()) ?? 100;

    final notifier = ref.read(attributesProvider.notifier);
    if (widget.existing == null) {
      await notifier.addAttribute(name, maxValue: max);
    } else {
      await notifier.updateAttribute(widget.existing!.copyWith(name: name, maxValue: max));
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final existing = widget.existing;
    if (existing == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete character state?'),
        content: Text('"${existing.name}" and its activity contributions will be removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(attributesProvider.notifier).deleteAttribute(existing.id);
      if (mounted) Navigator.of(context).pop();
    }
  }
}
