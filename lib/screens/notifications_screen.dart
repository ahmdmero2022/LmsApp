import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/app_notification.dart';
import '../state/app_state.dart';
import 'course_detail_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  IconData _iconFor(NotificationType type) {
    switch (type) {
      case NotificationType.enrollment:
        return Icons.group_add;
      case NotificationType.newCourse:
        return Icons.library_add;
      case NotificationType.newLesson:
        return Icons.playlist_add;
      case NotificationType.progress:
        return Icons.emoji_events;
      case NotificationType.quiz:
        return Icons.quiz;
      case NotificationType.review:
        return Icons.reviews;
      case NotificationType.system:
        return Icons.info_outline;
    }
  }

  Color _colorFor(NotificationType type) {
    switch (type) {
      case NotificationType.enrollment:
        return const Color(0xFF2E7D32);
      case NotificationType.newCourse:
        return const Color(0xFF1565C0);
      case NotificationType.newLesson:
        return const Color(0xFF00838F);
      case NotificationType.progress:
        return const Color(0xFFEF6C00);
      case NotificationType.quiz:
        return const Color(0xFF6A1B9A);
      case NotificationType.review:
        return const Color(0xFFF9A825);
      case NotificationType.system:
        return const Color(0xFF546E7A);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final notifications = state.myNotifications;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (state.unreadCount > 0)
            TextButton(
              onPressed: state.markAllNotificationsRead,
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 72,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 12),
                  const Text('No notifications yet.'),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final n = notifications[i];
                return Card(
                  color: n.read
                      ? null
                      : Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withValues(alpha: 0.4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          _colorFor(n.type).withValues(alpha: 0.15),
                      foregroundColor: _colorFor(n.type),
                      child: Icon(_iconFor(n.type)),
                    ),
                    title: Text(
                      n.title,
                      style: TextStyle(
                        fontWeight:
                            n.read ? FontWeight.w500 : FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(n.body),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat.yMMMd().add_jm().format(n.createdAt),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    trailing: n.read
                        ? null
                        : Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                    onTap: () async {
                      await state.markNotificationRead(n);
                      final course = state.courseById(n.courseId);
                      if (course != null && context.mounted) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                CourseDetailScreen(courseId: course.id),
                          ),
                        );
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}
