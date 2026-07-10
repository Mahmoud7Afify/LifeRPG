import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../domain/models/activity.dart';
import 'icon_registry.dart';

/// A single activity tile in the check-in grid.
class ActivityCard extends StatelessWidget {
  const ActivityCard({super.key, required this.activity, required this.onTap});

  final Activity activity;
  final VoidCallback onTap;

  Color _typeColor() {
    switch (activity.type) {
      case ActivityType.good:
        return const Color(0xFF2E7D32);
      case ActivityType.bad:
        return const Color(0xFFC62828);
      case ActivityType.neutral:
        return const Color(0xFF616161);
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = Color(activity.color);
    return Material(
      color: baseColor.withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: baseColor.withOpacity(0.25),
                child: Icon(IconRegistry.resolve(activity.icon), color: baseColor),
              ),
              const SizedBox(height: 10),
              Text(
                activity.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                activity.score >= 0 ? '+${activity.score}' : '${activity.score}',
                style: TextStyle(
                  color: _typeColor(),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
