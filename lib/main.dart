import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';
import 'data/repositories/settings_repository.dart';
import 'presentation/providers/providers.dart';
import 'presentation/screens/check_in_screen.dart';
import 'presentation/screens/home_shell.dart';
import 'services/notification_service.dart';
import 'services/seed_data.dart';

/// Global navigator key so the notification tap handler (a top-level/static
/// callback) can push the check-in screen even from a cold start.
final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Seed default activities/attributes/achievements on first run.
  await SeedDataService().seedIfEmpty();

  await NotificationService.instance.init(
    onNotificationTap: _handleNotificationTap,
  );
  await NotificationService.instance.requestPermissions();

  runApp(const ProviderScope(child: LifeRpgApp()));
}

void _handleNotificationTap(NotificationResponse response) {
  // Quick actions from the notification: "Check In", "Snooze 5m", "Skip".
  switch (response.actionId) {
    case 'snooze_5':
      NotificationService.instance.snooze(5);
      return;
    case 'skip':
      NotificationService.instance.scheduleNext(15);
      return;
    default:
      // Default tap (or "Check In" action) opens the check-in screen.
      // Also re-arm the next reminder here — scheduleNext() only ever
      // schedules a single one-shot alarm, so without this the reminder
      // chain would die after the very first notification unless the
      // user happened to tap "Skip" specifically.
      _rescheduleFromPersistedInterval();
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('What are you doing right now?')),
            body: const CheckInScreen(),
          ),
        ),
      );
  }
}

/// Re-arms the next check-in reminder using the user's saved interval.
/// Used as a fallback whenever a notification is dismissed/tapped in a
/// way that doesn't already imply a specific next delay (snooze/skip).
Future<void> _rescheduleFromPersistedInterval() async {
  final minutes = await SettingsRepository().getIntervalMinutes();
  await NotificationService.instance.scheduleNext(minutes);
}

class LifeRpgApp extends ConsumerStatefulWidget {
  const LifeRpgApp({super.key});

  @override
  ConsumerState<LifeRpgApp> createState() => _LifeRpgAppState();
}

class _LifeRpgAppState extends ConsumerState<LifeRpgApp> {
  @override
  void initState() {
    super.initState();
    // Kick off the first periodic reminder using the persisted interval,
    // then nudge the user toward the exact-alarm settings screen if needed.
    Future.microtask(() async {
      final minutes = await ref.read(checkInIntervalProvider.future);
      await NotificationService.instance.scheduleNext(minutes);

      // If exact alarms aren't granted, offer a one-time prompt, since
      // scheduling otherwise silently degrades to "inexact" (fires within
      // a window, not on the dot) rather than failing outright.
      final canExact =
          await NotificationService.instance.canScheduleExactAlarms();
      if (!canExact) {
        final context = navigatorKey.currentContext;
        if (context != null && context.mounted) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Enable precise reminders'),
              content: const Text(
                'For check-in reminders to arrive right on time, allow '
                '"Alarms & reminders" for Life RPG in system settings. '
                'Without it, reminders may arrive a few minutes late.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Not now'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    NotificationService.instance.openExactAlarmSettings();
                  },
                  child: const Text('Open settings'),
                ),
              ],
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final darkModeAsync = ref.watch(darkModeProvider);
    final isDark = darkModeAsync.value ?? false;

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Life RPG',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: const HomeShell(),
    );
  }
}