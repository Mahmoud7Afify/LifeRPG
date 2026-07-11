/// App-wide constants: default intervals, XP curve knobs, attribute keys, etc.
class AppConstants {
  AppConstants._();

  static const String appName = 'Life RPG';

  // Check-in
  static const int defaultCheckInIntervalMinutes = 15;
  static const List<int> snoozeOptionsMinutes = [5, 10, 30];

  // Notification channel
  static const String checkInChannelId = 'life_rpg_checkin';
  static const String checkInChannelName = 'Check-In Reminders';
  static const String checkInChannelDesc =
      'Periodic reminders asking what you are doing right now';
  static const int checkInNotificationId = 1001;

  // XP / Level curve: XP required to reach level n (cumulative)
  // Level 1 = 0 XP. Each subsequent level requires progressively more XP.
  // cumulativeXpForLevel(n) = 50 * n * (n - 1)  -> smooth quadratic progression
  static int cumulativeXpForLevel(int level) {
    if (level <= 1) return 0;
    return 500 * level * (level - 1);
  }

  // Attribute keys
  static const List<String> defaultAttributes = [
    'Knowledge',
    'Discipline',
    'Health',
    'Spirituality',
    'Social',
    'Career',
    'Creativity',
  ];

  // SharedPreferences keys
  static const String prefIntervalMinutes = 'pref_interval_minutes';
  static const String prefDarkMode = 'pref_dark_mode';
  static const String prefNotifSound = 'pref_notif_sound';
  static const String prefNotifVibration = 'pref_notif_vibration';
  static const String prefLastCheckIn = 'pref_last_checkin_epoch';
  static const String prefDefaultAttributeMax = 'pref_default_attribute_max';

  // Character states
  static const int defaultAttributeMaxValue = 100;
}

enum ActivityType { good, bad, neutral }

extension ActivityTypeX on ActivityType {
  String get label {
    switch (this) {
      case ActivityType.good:
        return 'Good';
      case ActivityType.bad:
        return 'Bad';
      case ActivityType.neutral:
        return 'Neutral';
    }
  }

  static ActivityType fromString(String s) {
    return ActivityType.values.firstWhere(
      (e) => e.name == s,
      orElse: () => ActivityType.neutral,
    );
  }
}
