import '../../core/constants.dart';

/// Represents a trackable activity, e.g. "Study", "Workout", "Social Media".
class Activity {
  final String id;
  final String name;
  final int score; // base points awarded per check-in
  final String category;
  final ActivityType type;
  final int color; // ARGB int, stored directly in Flutter's Color(value)
  final String icon; // icon key, mapped in UI via an icon registry
  final bool enabled;
  final int sortOrder;
  final bool archived;
  final bool isCustomOneTime; // true for ad-hoc "Other" entries not saved permanently

  const Activity({
    required this.id,
    required this.name,
    required this.score,
    required this.category,
    required this.type,
    required this.color,
    required this.icon,
    this.enabled = true,
    this.sortOrder = 0,
    this.archived = false,
    this.isCustomOneTime = false,
  });

  Activity copyWith({
    String? name,
    int? score,
    String? category,
    ActivityType? type,
    int? color,
    String? icon,
    bool? enabled,
    int? sortOrder,
    bool? archived,
  }) {
    return Activity(
      id: id,
      name: name ?? this.name,
      score: score ?? this.score,
      category: category ?? this.category,
      type: type ?? this.type,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      enabled: enabled ?? this.enabled,
      sortOrder: sortOrder ?? this.sortOrder,
      archived: archived ?? this.archived,
      isCustomOneTime: isCustomOneTime,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'score': score,
      'category': category,
      'type': type.name,
      'color': color,
      'icon': icon,
      'enabled': enabled ? 1 : 0,
      'sort_order': sortOrder,
      'archived': archived ? 1 : 0,
    };
  }

  factory Activity.fromMap(Map<String, Object?> map) {
    return Activity(
      id: map['id'] as String,
      name: map['name'] as String,
      score: map['score'] as int,
      category: map['category'] as String,
      type: ActivityTypeX.fromString(map['type'] as String),
      color: map['color'] as int,
      icon: map['icon'] as String,
      enabled: (map['enabled'] as int) == 1,
      sortOrder: map['sort_order'] as int? ?? 0,
      archived: (map['archived'] as int? ?? 0) == 1,
    );
  }
}
