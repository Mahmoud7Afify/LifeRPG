import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants.dart';
import '../../domain/models/achievement.dart';
import '../../domain/models/activity.dart';
import '../../widgets/activity_card.dart';
import '../providers/providers.dart';

/// The core interaction of the app: "What are you doing right now?"
class CheckInScreen extends ConsumerWidget {
  const CheckInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(activitiesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('What are you doing right now?')),
      body: activitiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (activities) {
          final enabled = activities.where((a) => a.enabled && !a.archived).toList();
          if (enabled.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No activities yet. Add some from the Activities tab, '
                  'or tap "Other" below.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.05,
              ),
              itemCount: enabled.length + 1, // +1 for "Other"
              itemBuilder: (context, index) {
                if (index == enabled.length) {
                  return _OtherCard(onTap: () => _openOtherSheet(context, ref));
                }
                final activity = enabled[index];
                return ActivityCard(
                  activity: activity,
                  onTap: () => _submitCheckIn(context, ref, activity.id),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _submitCheckIn(
      BuildContext context, WidgetRef ref, String activityId) async {
    final unlocked =
        await ref.read(checkInActionProvider).submitForActivity(activityId);
    if (context.mounted) {
      _showConfirmationAndAchievements(context, unlocked);
    }
  }

  void _showConfirmationAndAchievements(
      BuildContext context, List<Achievement> unlocked) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Logged! Keep it up 💪'),
        duration: Duration(seconds: 1),
      ),
    );
    for (final a in unlocked) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('🏆 Achievement Unlocked!'),
          content: Text('${a.title}\n${a.description}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Nice!'),
            ),
          ],
        ),
      );
    }
  }

  void _openOtherSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _OtherActivitySheet(
        onSubmitted: (unlocked) {
          if (context.mounted) {
            _showConfirmationAndAchievements(context, unlocked);
          }
        },
      ),
    );
  }
}

class _OtherCard extends StatelessWidget {
  const _OtherCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, size: 32, color: scheme.primary),
            const SizedBox(height: 8),
            const Text('Other', style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet for logging a fully custom activity, with an option to save
/// it as a permanent, reusable activity in the check-in grid.
class _OtherActivitySheet extends ConsumerStatefulWidget {
  const _OtherActivitySheet({required this.onSubmitted});
  final void Function(List<Achievement>) onSubmitted;

  @override
  ConsumerState<_OtherActivitySheet> createState() => _OtherActivitySheetState();
}

class _OtherActivitySheetState extends ConsumerState<_OtherActivitySheet> {
  final _nameController = TextEditingController();
  final _scoreController = TextEditingController(text: '3');
  ActivityType _type = ActivityType.neutral;
  bool _saveAsPermanent = false;
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Custom activity', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Activity name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _scoreController,
            keyboardType: const TextInputType.numberWithOptions(signed: true),
            decoration: const InputDecoration(labelText: 'Score (e.g. 3 or -3)'),
          ),
          const SizedBox(height: 12),
          SegmentedButton<ActivityType>(
            segments: const [
              ButtonSegment(value: ActivityType.good, label: Text('Good')),
              ButtonSegment(value: ActivityType.neutral, label: Text('Neutral')),
              ButtonSegment(value: ActivityType.bad, label: Text('Bad')),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() => _type = s.first),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Save as permanent activity'),
            subtitle: const Text('Adds this to your check-in grid for reuse'),
            value: _saveAsPermanent,
            onChanged: (v) => setState(() => _saveAsPermanent = v),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Log it'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final score = int.tryParse(_scoreController.text.trim()) ?? 0;
    if (name.isEmpty) return;

    setState(() => _submitting = true);

    final unlocked = await ref.read(checkInActionProvider).submitCustom(
          name: name,
          score: score,
          type: _type,
        );

    if (_saveAsPermanent) {
      final activities = ref.read(activitiesProvider).value ?? [];
      await ref.read(activitiesProvider.notifier).addActivity(
            Activity(
              id: const Uuid().v4(),
              name: name,
              score: score,
              category: 'Custom',
              type: _type,
              color: 0xFF757575,
              icon: 'more_horiz',
              sortOrder: activities.length,
            ),
          );
    }

    if (mounted) {
      Navigator.of(context).pop();
      widget.onSubmitted(unlocked);
    }
  }
}
