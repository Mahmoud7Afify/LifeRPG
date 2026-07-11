import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';

/// Wraps SharedPreferences for simple app settings (interval, theme, sound...).
class SettingsRepository {
  Future<int> getIntervalMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(AppConstants.prefIntervalMinutes) ??
        AppConstants.defaultCheckInIntervalMinutes;
  }

  Future<void> setIntervalMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.prefIntervalMinutes, minutes);
  }

  Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.prefDarkMode) ?? false;
  }

  Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefDarkMode, value);
  }

  Future<bool> getNotifSound() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.prefNotifSound) ?? true;
  }

  Future<void> setNotifSound(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefNotifSound, value);
  }

  Future<bool> getNotifVibration() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.prefNotifVibration) ?? true;
  }

  Future<void> setNotifVibration(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefNotifVibration, value);
  }

  Future<void> setLastCheckInEpoch(int epochMs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.prefLastCheckIn, epochMs);
  }

  Future<int?> getLastCheckInEpoch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(AppConstants.prefLastCheckIn);
  }

  Future<int> getDefaultAttributeMax() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(AppConstants.prefDefaultAttributeMax) ??
        AppConstants.defaultAttributeMaxValue;
  }

  Future<void> setDefaultAttributeMax(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.prefDefaultAttributeMax, value);
  }
}
