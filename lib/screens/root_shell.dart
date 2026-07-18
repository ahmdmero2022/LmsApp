import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import 'catalog_screen.dart';
import 'my_learning_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'teaching_screen.dart';

class _NavDest {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget screen;
  const _NavDest(this.label, this.icon, this.selectedIcon, this.screen);
}

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final destinations = <_NavDest>[
      const _NavDest(
        'Catalog',
        Icons.explore_outlined,
        Icons.explore,
        CatalogScreen(),
      ),
      if (state.isInstructor)
        const _NavDest(
          'Teaching',
          Icons.co_present_outlined,
          Icons.co_present,
          TeachingScreen(),
        )
      else
        const _NavDest(
          'My Learning',
          Icons.menu_book_outlined,
          Icons.menu_book,
          MyLearningScreen(),
        ),
      _NavDest(
        'Notifications',
        Icons.notifications_outlined,
        Icons.notifications,
        const NotificationsScreen(),
      ),
      const _NavDest(
        'Profile',
        Icons.person_outline,
        Icons.person,
        ProfileScreen(),
      ),
    ];

    final safeIndex = _index.clamp(0, destinations.length - 1);
    final unread = state.unreadCount;
    final isWide = MediaQuery.of(context).size.width >= 800;

    Widget notifIcon(IconData icon) {
      if (unread == 0) return Icon(icon);
      return Badge(
        label: Text('$unread'),
        child: Icon(icon),
      );
    }

    final body = IndexedStack(
      index: safeIndex,
      children: destinations.map((d) => d.screen).toList(),
    );

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              extended: MediaQuery.of(context).size.width >= 1100,
              selectedIndex: safeIndex,
              onDestinationSelected: (i) => setState(() => _index = i),
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Icon(
                  Icons.school_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              destinations: [
                for (final d in destinations)
                  NavigationRailDestination(
                    icon: d.label == 'Notifications'
                        ? notifIcon(d.icon)
                        : Icon(d.icon),
                    selectedIcon: d.label == 'Notifications'
                        ? notifIcon(d.selectedIcon)
                        : Icon(d.selectedIcon),
                    label: Text(d.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: safeIndex,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (final d in destinations)
            NavigationDestination(
              icon: d.label == 'Notifications'
                  ? notifIcon(d.icon)
                  : Icon(d.icon),
              selectedIcon: d.label == 'Notifications'
                  ? notifIcon(d.selectedIcon)
                  : Icon(d.selectedIcon),
              label: d.label,
            ),
        ],
      ),
    );
  }
}
