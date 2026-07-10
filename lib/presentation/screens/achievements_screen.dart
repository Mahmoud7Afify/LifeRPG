import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/icon_registry.dart';
import '../providers/providers.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(achievementsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),
      body: achievementsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (achievements) => ListView.builder(
          itemCount: achievements.length,
          itemBuilder: (context, index) {
            final a = achievements[index];
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
          },
        ),
      ),
    );
  }
}
