import '../core/constants.dart';

/// Result of applying XP: new level, and whether a level-up occurred.
class XpResult {
  final int totalXp;
  final int level;
  final bool leveledUp;
  final int xpIntoCurrentLevel;
  final int xpNeededForNextLevel;

  const XpResult({
    required this.totalXp,
    required this.level,
    required this.leveledUp,
    required this.xpIntoCurrentLevel,
    required this.xpNeededForNextLevel,
  });

  double get progressFraction {
    if (xpNeededForNextLevel <= 0) return 1.0;
    return (xpIntoCurrentLevel / xpNeededForNextLevel).clamp(0.0, 1.0);
  }
}

/// Pure XP/level math, decoupled from persistence so it's independently testable.
class XpService {
  /// Given cumulative XP, find the current level (1-indexed).
  int levelForXp(int totalXp) {
    int level = 1;
    while (AppConstants.cumulativeXpForLevel(level + 1) <= totalXp) {
      level++;
    }
    return level;
  }

  XpResult applyXpGain(int currentTotalXp, int xpGain) {
    final oldLevel = levelForXp(currentTotalXp);
    final newTotal = currentTotalXp + xpGain;
    final newLevel = levelForXp(newTotal);

    final thisLevelFloor = AppConstants.cumulativeXpForLevel(newLevel);
    final nextLevelFloor = AppConstants.cumulativeXpForLevel(newLevel + 1);

    return XpResult(
      totalXp: newTotal,
      level: newLevel,
      leveledUp: newLevel > oldLevel,
      xpIntoCurrentLevel: newTotal - thisLevelFloor,
      xpNeededForNextLevel: nextLevelFloor - thisLevelFloor,
    );
  }

  XpResult describeXp(int totalXp) {
    final level = levelForXp(totalXp);
    final thisLevelFloor = AppConstants.cumulativeXpForLevel(level);
    final nextLevelFloor = AppConstants.cumulativeXpForLevel(level + 1);
    return XpResult(
      totalXp: totalXp,
      level: level,
      leveledUp: false,
      xpIntoCurrentLevel: totalXp - thisLevelFloor,
      xpNeededForNextLevel: nextLevelFloor - thisLevelFloor,
    );
  }

  /// XP awarded per check-in. Good activities award more XP than their raw
  /// score to make "good" behavior feel more rewarding; bad activities still
  /// grant a little XP (checking in honestly is itself worth something) but
  /// far less than their point cost.
  int xpForCheckIn({required int score, required ActivityType type}) {
    switch (type) {
      case ActivityType.good:
        return (score.abs() * 1.5).round() + 2;
      case ActivityType.neutral:
        return 1;
      case ActivityType.bad:
        return 1; // small "honesty" XP for logging truthfully
    }
  }
}
