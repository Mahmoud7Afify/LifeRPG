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
    'military_tech': Icons.military_tech,
    'star': Icons.star,
    'favorite': Icons.favorite,
    'psychology': Icons.psychology,
    'savings': Icons.savings,
    'timer': Icons.timer,
    'music_note': Icons.music_note,
    'spa': Icons.spa,
    'water_drop': Icons.water_drop,
    'wb_sunny': Icons.wb_sunny,
    'nights_stay': Icons.nights_stay,
    'pets': Icons.pets,
    'fastfood': Icons.fastfood,
    'local_cafe': Icons.local_cafe,
    'directions_run': Icons.directions_run,
    'computer': Icons.computer,
    'attach_money': Icons.attach_money,
    'groups': Icons.groups,
    'palette': Icons.palette,
    'emoji_events': Icons.emoji_events,
    'lightbulb': Icons.lightbulb,
    'health_and_safety': Icons.health_and_safety,
    'shield': Icons.shield,
    'rocket_launch': Icons.rocket_launch,
  };

  static IconData resolve(String key) => _map[key] ?? Icons.circle;

  static List<String> get allKeys => _map.keys.toList();
}
