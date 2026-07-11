import 'package:flutter/material.dart';
import 'achievements_management_screen.dart';
import 'achievements_screen.dart';
import 'activity_management_screen.dart';
import 'character_states_screen.dart';
import 'check_in_screen.dart';
import 'dashboard_screen.dart';
import 'goals_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

/// Bottom-navigation shell hosting the app's five core sections. Less
/// frequently used screens (Settings, History, Activities Management,
/// Achievements Management) live behind the overflow menu in the app bar
/// instead of taking up a bottom-nav slot.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

enum _OverflowItem { settings, history, activityManagement, achievementManagement }

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _titles = [
    'Check In',
    'Dashboard',
    'Character States',
    'Goals',
    'Achievements',
  ];

  static const _screens = [
    CheckInScreen(),
    DashboardScreen(),
    CharacterStatesScreen(),
    GoalsScreen(),
    AchievementsScreen(),
  ];

  void _openOverflow(_OverflowItem item) {
    Widget screen;
    switch (item) {
      case _OverflowItem.settings:
        screen = const SettingsScreen();
        break;
      case _OverflowItem.history:
        screen = const HistoryScreen();
        break;
      case _OverflowItem.activityManagement:
        screen = const ActivityManagementScreen();
        break;
      case _OverflowItem.achievementManagement:
        screen = const AchievementsManagementScreen();
        break;
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          PopupMenuButton<_OverflowItem>(
            onSelected: _openOverflow,
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: _OverflowItem.settings,
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Settings'),
                ),
              ),
              PopupMenuItem(
                value: _OverflowItem.history,
                child: ListTile(
                  leading: Icon(Icons.history),
                  title: Text('History'),
                ),
              ),
              PopupMenuItem(
                value: _OverflowItem.activityManagement,
                child: ListTile(
                  leading: Icon(Icons.list_alt),
                  title: Text('Activities Management'),
                ),
              ),
              PopupMenuItem(
                value: _OverflowItem.achievementManagement,
                child: ListTile(
                  leading: Icon(Icons.emoji_events),
                  title: Text('Achievements Management'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.bolt), label: 'Check In'),
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.person), label: 'States'),
          NavigationDestination(icon: Icon(Icons.flag), label: 'Goals'),
          NavigationDestination(icon: Icon(Icons.emoji_events), label: 'Achievements'),
        ],
      ),
    );
  }
}
