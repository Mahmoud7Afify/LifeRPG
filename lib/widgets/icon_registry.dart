import 'package:flutter/material.dart';

/// Maps string icon keys (stored in DB) to actual Material icons.
/// Keeps the DB storage-format decoupled from Flutter's IconData.
class IconRegistry {
  IconRegistry._();

  static const Map<String, IconData> _map = {
    'school': Icons.school,
    'code': Icons.code,
    'fitness_center': Icons.fitness_center,
    'menu_book': Icons.menu_book,
    'auto_stories': Icons.auto_stories,
    'family_restroom': Icons.family_restroom,
    'smartphone': Icons.smartphone,
    'sports_esports': Icons.sports_esports,
    'bedtime': Icons.bedtime,
    'flag': Icons.flag,
    'bolt': Icons.bolt,
    'local_fire_department': Icons.local_fire_department,
    'trending_up': Icons.trending_up,
    'phonelink_erase': Icons.phonelink_erase,
    'more_horiz': Icons.more_horiz,
    'work': Icons.work,
    'restaurant': Icons.restaurant,
    'brush': Icons.brush,
    'self_improvement': Icons.self_improvement,
    'directions_walk': Icons.directions_walk,
  };

  static IconData resolve(String key) => _map[key] ?? Icons.circle;

  static List<String> get allKeys => _map.keys.toList();
}
