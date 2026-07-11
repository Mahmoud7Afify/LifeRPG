import '../../core/constants.dart';

/// A character attribute, e.g. "Knowledge", "Discipline", "Health".
class CharacterAttribute {
  final String id;
  final String name;
  final int totalPoints; // accumulated points across all time
  final int todayPoints;
  final int maxValue; // the "out of" number shown on the progress bar

  const CharacterAttribute({
    required this.id,
    required this.name,
    this.totalPoints = 0,
    this.todayPoints = 0,
    this.maxValue = AppConstants.defaultAttributeMaxValue,
  });

  CharacterAttribute copyWith({
    String? name,
    int? totalPoints,
    int? todayPoints,
    int? maxValue,
  }) {
    return CharacterAttribute(
      id: id,
      name: name ?? this.name,
      totalPoints: totalPoints ?? this.totalPoints,
      todayPoints: todayPoints ?? this.todayPoints,
      maxValue: maxValue ?? this.maxValue,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'total_points': totalPoints,
        'today_points': todayPoints,
        'max_value': maxValue,
      };

  factory CharacterAttribute.fromMap(Map<String, Object?> map) {
    return CharacterAttribute(
      id: map['id'] as String,
      name: map['name'] as String,
      totalPoints: map['total_points'] as int? ?? 0,
      todayPoints: map['today_points'] as int? ?? 0,
      maxValue: map['max_value'] as int? ?? AppConstants.defaultAttributeMaxValue,
    );
  }
}

/// Maps an activity to how many points it contributes to each attribute.
/// e.g. Programming -> {Career: 4, Knowledge: 2, Discipline: 1}
class ActivityAttributeMapping {
  final String activityId;
  final String attributeId;
  final int points; // can be negative (e.g. Social Media -> Discipline: -2)

  const ActivityAttributeMapping({
    required this.activityId,
    required this.attributeId,
    required this.points,
  });

  ActivityAttributeMapping copyWith({
    String? activityId,
    String? attributeId,
    int? points,
  }) {
    return ActivityAttributeMapping(
      activityId: activityId ?? this.activityId,
      attributeId: attributeId ?? this.attributeId,
      points: points ?? this.points,
    );
  }

  Map<String, Object?> toMap() => {
        'activity_id': activityId,
        'attribute_id': attributeId,
        'points': points,
      };

  factory ActivityAttributeMapping.fromMap(Map<String, Object?> map) {
    return ActivityAttributeMapping(
      activityId: map['activity_id'] as String,
      attributeId: map['attribute_id'] as String,
      points: map['points'] as int,
    );
  }
}
