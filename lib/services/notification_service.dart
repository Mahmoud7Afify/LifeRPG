import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import '../core/constants.dart';

/// Owns scheduling of the periodic "What are you doing right now?" reminder,
/// plus snooze / skip / quick-action handling.
///
/// IMPORTANT (Android 12+ / exact alarms):
/// `SCHEDULE_EXACT_ALARM` is a "special access" permission. On many OEM
/// skins (Honor/Huawei/Xiaomi/etc.) calling `Permission.scheduleExactAlarm
/// .request()` does NOT show a system dialog — it silently stays denied.
/// The only reliable fix is to send the user straight to the OS settings
/// screen for it (see `openExactAlarmSettings`) and to make scheduling
/// itself resilient: if exact scheduling is refused at call time, we fall
/// back to an inexact (but still "while idle") schedule rather than
/// throwing and silently failing.
class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init({
    required void Function(NotificationResponse) onNotificationTap,
  }) async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings =
        InitializationSettings(android: androidInit, iOS: iosInit);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: onNotificationTap,
    );

    await _createChannel();
    _initialized = true;
  }

  Future<void> _createChannel() async {
    const channel = AndroidNotificationChannel(
      AppConstants.checkInChannelId,
      AppConstants.checkInChannelName,
      description: AppConstants.checkInChannelDesc,
      importance: Importance.high,
      playSound: true,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<bool> requestPermissions() async {
    final notifStatus = await Permission.notification.request();
    // NOTE: this request() call is close to a no-op for scheduleExactAlarm
    // on many devices — see class doc above. We still call it in case the
    // OS does show a dialog, but don't rely on it.
    if (await Permission.scheduleExactAlarm.isDenied) {
      await Permission.scheduleExactAlarm.request();
    }
    return notifStatus.isGranted;
  }

  /// Whether exact alarms are currently allowed for this app.
  Future<bool> canScheduleExactAlarms() async {
    return Permission.scheduleExactAlarm.isGranted;
  }

  /// Opens the OS "Alarms & reminders" settings screen for this app so the
  /// user can grant exact-alarm access directly, since the runtime request
  /// dialog is unreliable for this permission on many devices.
  Future<void> openExactAlarmSettings() async {
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    // requestExactAlarmsPermission() (plugin v17+) opens the system screen
    // directly on Android 12+. Fall back to the generic app settings page
    // if that's unavailable for some reason.
    try {
      await androidImpl?.requestExactAlarmsPermission();
    } catch (_) {
      await openAppSettings();
    }
  }

  NotificationDetails _details({bool sound = true, bool vibrate = true}) {
    final android = AndroidNotificationDetails(
      AppConstants.checkInChannelId,
      AppConstants.checkInChannelName,
      channelDescription: AppConstants.checkInChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      ongoing: true, // persists until user interacts with it
      autoCancel: false,
      playSound: sound,
      enableVibration: vibrate,
      actions: const [
        AndroidNotificationAction('checkin_now', 'Check In'),
        AndroidNotificationAction('snooze_5', 'Snooze 5m'),
        AndroidNotificationAction('skip', 'Skip'),
      ],
    );
    return NotificationDetails(android: android);
  }

  /// Schedules the very next reminder, [intervalMinutes] from now.
  ///
  /// Tries exact scheduling first (best UX: fires right on time). If the OS
  /// refuses because exact-alarm access hasn't been granted, this silently
  /// (but loudly in the log) falls back to inexact scheduling instead of
  /// throwing — so the reminder still fires, just with some OS-controlled
  /// slack (usually within a few minutes), rather than not firing at all.
  Future<void> scheduleNext(int intervalMinutes,
      {bool sound = true, bool vibrate = true}) async {
    final scheduledTime =
        tz.TZDateTime.now(tz.local).add(Duration(minutes: intervalMinutes));

    try {
      await _plugin.zonedSchedule(
        AppConstants.checkInNotificationId,
        'What are you doing right now?',
        'Tap to log your current activity',
        scheduledTime,
        _details(sound: sound, vibrate: vibrate),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } on PlatformException catch (e) {
      if (e.code == 'exact_alarms_not_permitted') {
        // Fall back so the app still works without the special permission.
        await _plugin.zonedSchedule(
          AppConstants.checkInNotificationId,
          'What are you doing right now?',
          'Tap to log your current activity',
          scheduledTime,
          _details(sound: sound, vibrate: vibrate),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } else {
        rethrow;
      }
    }
  }

  /// Fires an immediate re-prompt after a snooze duration.
  Future<void> snooze(int minutes,
      {bool sound = true, bool vibrate = true}) async {
    await scheduleNext(minutes, sound: sound, vibrate: vibrate);
  }

  Future<void> cancelPending() async {
    await _plugin.cancel(AppConstants.checkInNotificationId);
  }

  Future<void> showImmediateCheckIn(
      {bool sound = true, bool vibrate = true}) async {
    await _plugin.show(
      AppConstants.checkInNotificationId,
      'What are you doing right now?',
      'Tap to log your current activity',
      _details(sound: sound, vibrate: vibrate),
    );
  }
}