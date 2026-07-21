import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../catalog/catalog_screen.dart';
import '../learning/my_learning_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';
import '../teaching/teaching_screen.dart';

class _NavDest {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget screen;
  final bool isNotifications;
  const _NavDest(
    this.label,
    this.icon,
    this.selectedIcon,
    this.screen, {
    this.isNotifications = false,
  });
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
    final l10n = AppLocalizations.of(context);
    final destinations = <_NavDest>[
      _NavDest(
        l10n.navCatalog,
        Icons.explore_outlined,
        Icons.explore,
        const CatalogScreen(),
      ),
      if (state.isInstructor)
        _NavDest(
          l10n.navTeaching,
          Icons.co_present_outlined,
          Icons.co_present,
          const TeachingScreen(),
        )
      else
        _NavDest(
          l10n.navMyLearning,
          Icons.menu_book_outlined,
          Icons.menu_book,
          const MyLearningScreen(),
        ),
      _NavDest(
        l10n.navNotifications,
        Icons.notifications_outlined,
        Icons.notifications,
        const NotificationsScreen(),
        isNotifications: true,
      ),
      _NavDest(
        l10n.navProfile,
        Icons.person_outline,
        Icons.person,
        const ProfileScreen(),
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
                    icon: d.isNotifications
                        ? notifIcon(d.icon)
                        : Icon(d.icon),
                    selectedIcon: d.isNotifications
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
              icon: d.isNotifications
                  ? notifIcon(d.icon)
                  : Icon(d.icon),
              selectedIcon: d.isNotifications
                  ? notifIcon(d.selectedIcon)
                  : Icon(d.selectedIcon),
              label: d.label,
            ),
        ],
      ),
    );
  }
}
