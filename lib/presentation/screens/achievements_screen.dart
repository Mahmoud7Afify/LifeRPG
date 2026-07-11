import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/achievement.dart';
import '../../widgets/icon_registry.dart';
import '../providers/providers.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(achievementsProvider);
    return achievementsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
      data: (achievements) {
        if (achievements.isEmpty) {
          return const Center(child: Text('No achievements yet.'));
        }
        final daily = achievements.where((a) => a.triggerType.isDaily).toList();
        final overall = achievements.where((a) => !a.triggerType.isDaily).toList();

        return ListView(
          children: [
            if (daily.isNotEmpty) ...[
              const _SectionHeader('Daily Records'),
              ...daily.map((a) => _AchievementTile(a)),
            ],
            if (overall.isNotEmpty) ...[
              const _SectionHeader('Overall Run'),
              ...overall.map((a) => _AchievementTile(a)),
            ],
          ],
        );
      },
    );
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

class _AchievementTile extends StatelessWidget {
  const _AchievementTile(this.a);
  final Achievement a;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: a.unlocked
            ? Colors.amber.withOpacity(0.3)
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Icon(
          IconRegistry.resolve(a.icon),
          color: a.unlocked ? Colors.amber.shade800 : Colors.grey,
        ),
      ),
      title: Text(
        a.title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: a.unlocked ? null : Colors.grey,
        ),
      ),
      subtitle: Text(a.description),
      trailing: a.unlocked
          ? const Icon(Icons.check_circle, color: Colors.green)
          : const Icon(Icons.lock_outline, color: Colors.grey),
    );
  }
}
